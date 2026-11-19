#!/usr/bin/env bash
# ========================================================================
# Script Name : install-hooks.sh
# Description : プロジェクトの Git フック(.githooks)を有効にする
# Usage       : ./install-hooks.sh
# ========================================================================

# シェルオプションを設定(エラー時に即終了)
set -euo pipefail

# プロジェクトルートへ移動
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../common/cd-project-root.sh
source "$SCRIPT_DIR/../common/cd-project-root.sh"

# エラー時のメッセージを設定
trap 'echo "Git フックの有効化に失敗しました" >&2' ERR

# core.hooksPath に設定するフックの配置先(作業ツリーのルートからの相対パス)
HOOKS_PATH=".githooks"

# Git リポジトリであることを確認
if ! PREFIX="$(git rev-parse --show-prefix 2>/dev/null)"; then
    echo "エラー: Git リポジトリではありません (git init を実行してください)" >&2
    exit 1
fi

# core.hooksPath の相対パスは作業ツリーのルートを基準とするため、プロジェクトルートがそれと一致することを確認
if [[ -n "$PREFIX" ]]; then
    echo "エラー: プロジェクトルートが Git リポジトリのルートではありません" >&2
    exit 1
fi

if [[ ! -d "$HOOKS_PATH" ]]; then
    echo "エラー: ${HOOKS_PATH} がありません" >&2
    exit 1
fi

# 他のツールなどが設定した core.hooksPath は上書きしない
CURRENT_HOOKS_PATH="$(git config --local --get core.hooksPath || true)"
if [[ "$CURRENT_HOOKS_PATH" == "$HOOKS_PATH" ]]; then
    echo "Git フックは既に有効です (core.hooksPath = ${HOOKS_PATH})"
    exit 0
fi
if [[ -n "$CURRENT_HOOKS_PATH" ]]; then
    echo "エラー: core.hooksPath は既に \"${CURRENT_HOOKS_PATH}\" に設定されています" >&2
    echo "置き換える場合は git config --local --unset core.hooksPath で解除してから再実行してください" >&2
    exit 1
fi

# 有効にすると、これまでのフックの配置先(.git/hooks やグローバル設定の core.hooksPath)は使われなくなる
CURRENT_HOOKS_DIR="$(git rev-parse --git-path hooks)"
EXISTING_HOOKS=()
if [[ -d "$CURRENT_HOOKS_DIR" ]]; then
    for hook in "$CURRENT_HOOKS_DIR"/*; do
        if [[ -f "$hook" && "$hook" != *.sample ]]; then
            EXISTING_HOOKS+=("${hook##*/}")
        fi
    done
fi

# Git フックを有効化
git config --local core.hooksPath "$HOOKS_PATH"

# 完了メッセージを表示
echo "Git フックを有効にしました (core.hooksPath = ${HOOKS_PATH})"
echo "  - pre-push: push 前に品質チェック (check スクリプト) を実行"
if [[ ${#EXISTING_HOOKS[@]} -gt 0 ]]; then
    echo "注意: ${CURRENT_HOOKS_DIR} にある次のフックは使われなくなります: ${EXISTING_HOOKS[*]}"
fi
echo "無効にする場合は uninstall-hooks.sh を実行してください"
