#!/usr/bin/env bash
# ========================================================================
# Script Name : rename-project.sh
# Description : テンプレートのプロジェクト名を一括変更する
# Usage       : ./rename-project.sh <new-name> [copyright-holder]
#               new-name         : kebab-case(例: my-project)
#               copyright-holder : 省略可(例: "Your Name")
# ========================================================================

# シェルオプションを設定(エラー時に即終了)
set -euo pipefail

# GNU sed (Linux) は `sed -i`, BSD sed (macOS) は `sed -i ''`
if [[ "$(uname -s)" == Darwin ]]; then
    sed_inplace() { sed -i '' "$@"; }
else
    sed_inplace() { sed -i "$@"; }
fi

# 使い方を表示して終了
usage() {
    echo "Usage: $0 <new-name> [copyright-holder]" >&2
    echo "  new-name         : kebab-case(例: my-project)" >&2
    echo "  copyright-holder : 省略可 (LICENSE / Cargo.toml を更新(例: \"Your Name\"))" >&2
    exit 1
}

# 引数の数を検証
[[ $# -lt 1 || $# -gt 2 ]] && usage

NEW_NAME="$1"
COPYRIGHT_HOLDER="${2:-}"

# プロジェクトルートへ移動
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../common/cd-project-root.sh
source "$SCRIPT_DIR/../common/cd-project-root.sh"

# プロジェクト名の形式を検証(kebab-case)
if [[ ! "$NEW_NAME" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
    echo "エラー: プロジェクト名は kebab-case で指定してください (例: my-project)" >&2
    exit 1
fi

# Rust 識別子が予約された名前でないか検証(ファイルを書き換える前に弾く)
NEW_IDENT="${NEW_NAME//-/_}"
RESERVED_NAMES=(
    # キーワード(将来の予約語を含む)
    abstract as async await become box break const continue crate do dyn else enum extern
    false final fn for gen if impl in let loop macro match mod move mut override priv pub
    ref return self static struct super trait true try type typeof unsafe unsized use
    virtual where while yield
    # 標準ライブラリのクレート名
    alloc core proc_macro std test
    # Cargo のビルドディレクトリ名
    build deps examples incremental
    # Windows の予約デバイス名
    aux con nul prn com1 com2 com3 com4 com5 com6 com7 com8 com9
    lpt1 lpt2 lpt3 lpt4 lpt5 lpt6 lpt7 lpt8 lpt9
)
for reserved in "${RESERVED_NAMES[@]}"; do
    if [[ "$NEW_IDENT" == "$reserved" ]]; then
        echo "エラー: \"${NEW_NAME}\" は Rust または Cargo で予約された名前のため使用できません" >&2
        exit 1
    fi
done

# 著作権者名を検証(Cargo.toml の文字列リテラルを壊す文字は不可)
if [[ "$COPYRIGHT_HOLDER" == *'"'* || "$COPYRIGHT_HOLDER" == *'\'* || "$COPYRIGHT_HOLDER" =~ [[:cntrl:]] ]]; then
    echo "エラー: 著作権者名に \" \\ および制御文字(改行など)は使用できません" >&2
    exit 1
fi

# 現在のプロジェクト名と Rust 識別子を取得
# (grep だと一致しない場合に pipefail で無言のまま終了するため、一致しなくても成功する sed で抽出する)
CURRENT_NAME="$(sed -nE 's/^name = "([^"]+)".*/\1/p' Cargo.toml | head -1)"
if [[ -z "$CURRENT_NAME" ]]; then
    echo "エラー: Cargo.toml から name を読み取れません" >&2
    exit 1
fi
OLD_IDENT="${CURRENT_NAME//-/_}"

# 変更が不要な場合は終了(著作権者のみ更新する場合は続行)
NAME_UNCHANGED=false
if [[ "$CURRENT_NAME" == "$NEW_NAME" ]]; then
    NAME_UNCHANGED=true
    if [[ -z "$COPYRIGHT_HOLDER" ]]; then
        echo "プロジェクト名は既に \"${NEW_NAME}\" です"
        exit 0
    fi
fi

if [[ "$NAME_UNCHANGED" == false ]]; then
    echo "プロジェクト名を \"${CURRENT_NAME}\" から \"${NEW_NAME}\" に変更しています..."
    echo

    # Cargo.toml の name を更新
    sed_inplace "s/^name = \"${CURRENT_NAME}\"/name = \"${NEW_NAME}\"/" Cargo.toml

    # デバッグ設定のパッケージ名 / バイナリ名を更新
    if [[ -f .vscode/launch.json ]]; then
        # 項目単位で置換する(部分文字列置換だと 2 回目以降のリネームで名前が壊れる)
        sed_inplace -E \
            -e ':a' -e 'N' -e '$!ba' \
            -e "s/(--bin=)${CURRENT_NAME}\"/\1${NEW_NAME}\"/g" \
            -e "s/(--package=)${CURRENT_NAME}\"/\1${NEW_NAME}\"/g" \
            -e "s/(\"name\": \")${CURRENT_NAME}(\",[[:space:]]*\"kind\": \"bin\")/\1${NEW_NAME}\2/g" \
            -e "s/(\"name\": \")${OLD_IDENT}(\",[[:space:]]*\"kind\": \"lib\")/\1${NEW_IDENT}\2/g" \
            .vscode/launch.json
    fi

    # use 文と doc コメントのクレート名を更新
    for file in src/main.rs tests/integration_test.rs src/lib.rs; do
        sed_inplace "s/use ${OLD_IDENT}::/use ${NEW_IDENT}::/g" "$file"
        sed_inplace "s/\`${CURRENT_NAME}\`/\`${NEW_NAME}\`/g" "$file"
    done

    # README のタイトルを更新し、テンプレートの案内行(と直後の空行)を削除
    if [[ -f README.md ]]; then
        sed_inplace \
            -e "s/^# ${CURRENT_NAME}\$/# ${NEW_NAME}/" \
            -e '/<!-- template-notice/{N;d;}' \
            README.md
    fi

    # テンプレートの使い方はプロジェクトに不要なため削除
    rm -f TEMPLATE.md
fi

# 著作権表記を更新(指定時のみ)
if [[ -n "$COPYRIGHT_HOLDER" ]]; then
    if [[ "$NAME_UNCHANGED" == true ]]; then
        echo "著作権者を \"${COPYRIGHT_HOLDER}\" に更新しています..."
        echo
    fi

    COPYRIGHT_YEAR="$(date +%Y)"
    COPYRIGHT_LINE="Copyright (c) ${COPYRIGHT_YEAR} ${COPYRIGHT_HOLDER}"
    # sed の置換文字列で特殊な文字(/ と &)をエスケープ
    COPYRIGHT_LINE_ESCAPED="$(printf '%s' "$COPYRIGHT_LINE" | sed -e 's/[\/&]/\\&/g')"
    sed_inplace "s/^Copyright (c) .*/${COPYRIGHT_LINE_ESCAPED}/" LICENSE
    sed_inplace "s/^LegalCopyright = \".*\"/LegalCopyright = \"${COPYRIGHT_LINE_ESCAPED}\"/" Cargo.toml
fi

# Cargo.lock を更新
echo "Cargo.lock を更新しています..."
cargo check --quiet
echo

# 手動更新が必要な項目を案内
echo "変更が完了しました。必要に応じて以下を手動で更新してください:"
echo "  - Cargo.toml の description, repository"
echo "  - README.md の概要"
echo "  - assets/icon.ico"
if [[ -z "$COPYRIGHT_HOLDER" ]]; then
    echo "  - LICENSE / Cargo.toml の著作権表記(または copyright-holder を指定して再実行)"
fi
