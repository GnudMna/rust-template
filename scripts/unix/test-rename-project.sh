#!/usr/bin/env bash
# ========================================================================
# Script Name : test-rename-project.sh
# Description : rename-project をプロジェクトの複製に対して実行し、結果を検証する
#               Windows (Git Bash) では rename-project.ps1 も実行し、sh 版と結果を比較する
# Usage       : ./test-rename-project.sh
# ========================================================================

# シェルオプションを設定(エラー時に即終了)
set -euo pipefail

# プロジェクトルートへ移動
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../common/cd-project-root.sh
source "$SCRIPT_DIR/../common/cd-project-root.sh"

# エラー時のメッセージを設定
trap 'echo "rename-project のテストに失敗しました" >&2' ERR

# 検証の失敗を表示して終了
fail() {
    echo "検証に失敗しました: $1" >&2
    echo "rename-project のテストに失敗しました" >&2
    exit 1
}

# 複製するファイルを git ls-files で決めるため, Git リポジトリが必要
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "エラー: Git リポジトリではありません (git init を実行してください)" >&2
    exit 1
fi

# 改名に使う名前(2 回目は 1 回目の名前を含め、部分一致による置換ミスを検出する)
FIRST_NAME="rename-test-app"
SECOND_NAME="${FIRST_NAME}-next"

# 置換で特別な意味を持つ文字(sed の & と /, .NET 正規表現の $1)と非 ASCII 文字を含む著作権者名
COPYRIGHT_HOLDER='山田 & O'\''Brien / $1'
COPYRIGHT_LINE="Copyright (c) $(date +%Y) ${COPYRIGHT_HOLDER}"

ORIGINAL_NAME="$(sed -nE 's/^name = "([^"]+)".*/\1/p' Cargo.toml | head -1)"
if [[ -z "$ORIGINAL_NAME" ]]; then
    echo "エラー: Cargo.toml から name を読み取れません" >&2
    exit 1
fi
if [[ "$ORIGINAL_NAME" == "$FIRST_NAME" || "$ORIGINAL_NAME" == "$SECOND_NAME" ]]; then
    echo "エラー: プロジェクト名がテストで使う名前 (${ORIGINAL_NAME}) と同じです" >&2
    exit 1
fi

# テスト対象の実装(ps1 版は Windows で pwsh がある場合のみ)
IMPLS=(sh)
case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*)
        if command -v pwsh >/dev/null 2>&1; then
            IMPLS+=(ps1)
        else
            echo "pwsh が見つからないため rename-project.ps1 のテストを省略します"
        fi
        ;;
esac

# 作業ディレクトリを作成し、終了時に削除する
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
LOG_FILE="$WORK_DIR/rename.log"

# 複製ごとに依存クレートをビルドし直さないよう、ビルド結果の出力先を共有する
export CARGO_TARGET_DIR="$PROJECT_ROOT/target/rename-test"

# pwsh はリダイレクト先にコンソールのコードページで出力するため, UTF-8 に切り替えてから実行する
PWSH_WRAPPER="$WORK_DIR/invoke-utf8.ps1"
cat >"$PWSH_WRAPPER" <<'EOF'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$script = $args[0]
# 引数が 1 つでも配列にする(文字列のままだとスプラットで 1 文字ずつに分解される)
$arguments = @($args | Select-Object -Skip 1)
& $script @arguments
exit $LASTEXITCODE
EOF

# Git の管理対象と未追跡(無視されていない)のファイルを、作業ツリーの内容のまま複製する
copy_project() {
    local dest="$1"
    local file

    mkdir -p "$dest"
    while IFS= read -r -d '' file; do
        # 削除してまだコミットしていないファイルは飛ばす
        [[ -f "$file" ]] || continue
        if [[ "$file" == */* ]]; then
            mkdir -p "$dest/${file%/*}"
        fi
        cp -p "$file" "$dest/$file"
    done < <(git ls-files -z --cached --others --exclude-standard)
}

# 指定した実装の rename-project を、複製したプロジェクトで実行する
run_rename() {
    local impl="$1" dir="$2"
    shift 2

    if [[ "$impl" == sh ]]; then
        bash "$dir/scripts/unix/rename-project.sh" "$@"
    else
        pwsh -NoProfile -File "$PWSH_WRAPPER" "$dir/scripts/windows/rename-project.ps1" "$@"
    fi
}

# 成功することを確認する(失敗時は出力を表示)
expect_success() {
    local impl="$1" dir="$2"
    shift 2

    if ! run_rename "$impl" "$dir" "$@" >"$LOG_FILE" 2>&1; then
        cat "$LOG_FILE" >&2
        fail "[$impl] rename-project $* が失敗しました"
    fi
}

# 期待するエラーメッセージで失敗し、ファイルを変更しないことを確認する
expect_failure() {
    local impl="$1" dir="$2" message="$3"
    shift 3

    cp -R "$dir" "$dir.before"
    if run_rename "$impl" "$dir" "$@" >"$LOG_FILE" 2>&1; then
        cat "$LOG_FILE" >&2
        fail "[$impl] rename-project $* が成功しました (失敗するはずです)"
    fi
    if ! grep -qF "$message" "$LOG_FILE"; then
        cat "$LOG_FILE" >&2
        fail "[$impl] rename-project $* の出力に \"${message}\" がありません"
    fi
    assert_unchanged "$impl" "$dir"
}

# expect_failure などで退避した状態から変更されていないことを確認する
assert_unchanged() {
    local impl="$1" dir="$2"

    if ! diff -r "$dir.before" "$dir" >&2; then
        fail "[$impl] ファイルが変更されています"
    fi
    rm -rf "$dir.before"
}

# launch.json でパッケージ名 / バイナリ名 / ライブラリ名を指定している行の数を出力する
count_launch_name_lines() {
    local file="$1" name="$2"
    local ident="${name//-/_}"

    grep -cxE "[[:space:]]*\"(--bin=${name}|--package=${name}|name\": \"${name}|name\": \"${ident})\",?" "$file" || true
}

# 改名後の各ファイルを検証する
verify_renamed() {
    local impl="$1" dir="$2" old_name="$3" new_name="$4"
    local old_ident="${old_name//-/_}"
    local new_ident="${new_name//-/_}"
    local expected file

    grep -qFx "name = \"${new_name}\"" "$dir/Cargo.toml" ||
        fail "[$impl] Cargo.toml の name が \"${new_name}\" ではありません"
    grep -qFx "name = \"${new_name}\"" "$dir/Cargo.lock" ||
        fail "[$impl] Cargo.lock が更新されていません"
    [[ "$(head -1 "$dir/README.md")" == "# ${new_name}" ]] ||
        fail "[$impl] README.md のタイトルが更新されていません"
    if grep -qF 'template-notice' "$dir/README.md"; then
        fail "[$impl] README.md のテンプレートの案内が削除されていません"
    fi
    [[ ! -e "$dir/TEMPLATE.md" ]] ||
        fail "[$impl] TEMPLATE.md が削除されていません"

    # launch.json は行全体で照合し、引用符の重複などの壊れ方も検出する
    for expected in "--bin=${new_name}" "--package=${new_name}" \
        "name\": \"${new_name}" "name\": \"${new_ident}"; do
        grep -qxE "[[:space:]]*\"${expected}\",?" "$dir/.vscode/launch.json" ||
            fail "[$impl] .vscode/launch.json に \"${expected}\" の行がありません"
    done
    [[ "$(count_launch_name_lines "$dir/.vscode/launch.json" "$new_name")" == "$LAUNCH_NAME_LINES" ]] ||
        fail "[$impl] .vscode/launch.json の名前を含む行の数が改名前と異なります"

    grep -qF "use ${new_ident}::" "$dir/src/main.rs" ||
        fail "[$impl] src/main.rs の use 文が更新されていません"
    for file in src/main.rs src/lib.rs tests/integration_test.rs; do
        grep -qF "\`${new_name}\`" "$dir/$file" ||
            fail "[$impl] ${file} のクレート doc コメントが更新されていません"
    done

    # 新しい名前が旧名を含む場合があるため、名前の一部ではない旧名が残っていないか確認する
    # (このスクリプト自体はテスト用の名前を含むため除く)
    if grep -rnIE --exclude="$(basename "$0")" \
        "(^|[^a-z0-9_-])(${old_name}|${old_ident})([^a-z0-9_-]|$)" "$dir" >&2; then
        fail "[$impl] 旧名 \"${old_name}\" が残っています"
    fi
}

# 著作権表記を検証する
verify_copyright() {
    local impl="$1" dir="$2"

    grep -qFx "$COPYRIGHT_LINE" "$dir/LICENSE" ||
        fail "[$impl] LICENSE の著作権表記が \"${COPYRIGHT_LINE}\" ではありません"
    grep -qFx "LegalCopyright = \"${COPYRIGHT_LINE}\"" "$dir/Cargo.toml" ||
        fail "[$impl] Cargo.toml の LegalCopyright が \"${COPYRIGHT_LINE}\" ではありません"
}

# 改名後も launch.json の名前を含む行が同じ数あることを確認するため、改名前の数を数える
LAUNCH_NAME_LINES="$(count_launch_name_lines .vscode/launch.json "$ORIGINAL_NAME")"
if [[ "$LAUNCH_NAME_LINES" -eq 0 ]]; then
    echo "エラー: .vscode/launch.json に \"${ORIGINAL_NAME}\" を指定している行がありません" >&2
    exit 1
fi

# テストを実行
echo "rename-project のテストを実行しています..."
echo

for impl in "${IMPLS[@]}"; do
    dir="$WORK_DIR/$impl"
    echo "[$impl] テストを実行中..."
    copy_project "$dir"

    # 不正な引数はファイルを書き換える前にエラーにすること
    expect_failure "$impl" "$dir" "kebab-case で指定してください" My_App
    expect_failure "$impl" "$dir" "予約された名前のため使用できません" std
    expect_failure "$impl" "$dir" "著作権者名に" "$FIRST_NAME" 'Your "Name"'

    # Cargo.toml から name を読み取れない場合はエラーにすること
    cp "$dir/Cargo.toml" "$WORK_DIR/Cargo.toml.orig"
    sed -E 's/^name = "(.*)"/name="\1"/' "$WORK_DIR/Cargo.toml.orig" >"$dir/Cargo.toml"
    expect_failure "$impl" "$dir" "Cargo.toml から name を読み取れません" "$FIRST_NAME"
    cp "$WORK_DIR/Cargo.toml.orig" "$dir/Cargo.toml"

    # 名前と著作権者を更新すること
    expect_success "$impl" "$dir" "$FIRST_NAME" "$COPYRIGHT_HOLDER"
    verify_renamed "$impl" "$dir" "$ORIGINAL_NAME" "$FIRST_NAME"
    verify_copyright "$impl" "$dir"

    # 旧名を含む名前に付け直せること(著作権表記は維持される)
    expect_success "$impl" "$dir" "$SECOND_NAME"
    verify_renamed "$impl" "$dir" "$FIRST_NAME" "$SECOND_NAME"
    verify_copyright "$impl" "$dir"

    # 現在と同じ名前を指定した場合は何も変更しないこと
    cp -R "$dir" "$dir.before"
    expect_success "$impl" "$dir" "$SECOND_NAME"
    assert_unchanged "$impl" "$dir"
done
echo

# sh 版と ps1 版の結果が一致すること
if [[ "${#IMPLS[@]}" -gt 1 ]]; then
    echo "rename-project.sh と rename-project.ps1 の結果を比較中..."
    if ! diff -r "$WORK_DIR/sh" "$WORK_DIR/ps1" >&2; then
        fail "rename-project.sh と rename-project.ps1 の結果が異なります"
    fi
    echo
fi

# 改名後のプロジェクトでテストが通ること
echo "改名後のプロジェクトでテストを実行中..."
(cd "$WORK_DIR/sh" && cargo test --locked --quiet)
echo

# 完了メッセージを表示
echo "rename-project のテストが完了しました"
