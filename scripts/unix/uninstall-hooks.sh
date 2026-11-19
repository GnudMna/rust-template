#!/usr/bin/env bash
# ========================================================================
# Script Name : uninstall-hooks.sh
# Description : install-hooks.sh で有効にした Git フック(.githooks)を無効にする
# Usage       : ./uninstall-hooks.sh
# ========================================================================

# シェルオプションを設定(エラー時に即終了)
set -euo pipefail

# プロジェクトルートへ移動
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../common/cd-project-root.sh
source "$SCRIPT_DIR/../common/cd-project-root.sh"

# エラー時のメッセージを設定
trap 'echo "Git フックの無効化に失敗しました" >&2' ERR

# install-hooks.sh が core.hooksPath に設定するフックの配置先
HOOKS_PATH=".githooks"

# Git リポジトリであることを確認
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "エラー: Git リポジトリではありません" >&2
    exit 1
fi

# 他のツールなどが設定した core.hooksPath は解除しない
CURRENT_HOOKS_PATH="$(git config --local --get core.hooksPath || true)"
if [[ -z "$CURRENT_HOOKS_PATH" ]]; then
    echo "Git フックは有効になっていません"
    exit 0
fi
if [[ "$CURRENT_HOOKS_PATH" != "$HOOKS_PATH" ]]; then
    echo "エラー: core.hooksPath は \"${CURRENT_HOOKS_PATH}\" に設定されています (${HOOKS_PATH} ではないため解除しません)" >&2
    exit 1
fi

# Git フックを無効化
git config --local --unset core.hooksPath

# 完了メッセージを表示
echo "Git フックを無効にしました"
