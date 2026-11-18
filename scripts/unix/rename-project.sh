#!/bin/bash
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
    echo "  copyright-holder : 省略可 (LICENSE / build.rs を更新(例: \"Your Name\"))" >&2
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

# 著作権者名を検証(build.rs の文字列リテラルを壊す文字は不可)
if [[ "$COPYRIGHT_HOLDER" == *'"'* || "$COPYRIGHT_HOLDER" == *'\'* || "$COPYRIGHT_HOLDER" =~ [[:cntrl:]] ]]; then
    echo "エラー: 著作権者名に \" \\ および制御文字(改行など)は使用できません" >&2
    exit 1
fi

# 現在のプロジェクト名と Rust 識別子を取得
CURRENT_NAME="$(grep -E '^name = ' Cargo.toml | head -1 | sed -E 's/^name = "(.*)"/\1/')"
NEW_IDENT="${NEW_NAME//-/_}"
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
    sed_inplace "s/const LEGAL_COPYRIGHT: &str = \".*\";/const LEGAL_COPYRIGHT: \&str = \"${COPYRIGHT_LINE_ESCAPED}\";/" build.rs
fi

# Cargo.lock を更新
echo "Cargo.lock を更新しています..."
cargo check --quiet
echo

# 手動更新が必要な項目を案内
echo "変更が完了しました。必要に応じて以下を手動で更新してください:"
echo "  - Cargo.toml の description, authors, repository"
echo "  - README.md のタイトル"
echo "  - assets/icon.ico"
if [[ -z "$COPYRIGHT_HOLDER" ]]; then
    echo "  - LICENSE / build.rs の著作権表記(または copyright-holder を指定して再実行)"
fi
