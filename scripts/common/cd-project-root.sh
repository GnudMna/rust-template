#!/usr/bin/env bash
# ========================================================================
# Script Name : cd-project-root.sh
# Description : プロジェクトのルートディレクトリに移動するシェルスクリプト
# Usage       : source "$SCRIPT_DIR/../common/cd-project-root.sh"
# ========================================================================

# このスクリプト自身のディレクトリを取得(呼び出し元の SCRIPT_DIR を上書きしない)
_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# プロジェクトのルートディレクトリを計算
PROJECT_ROOT="$(cd "$_COMMON_DIR/../.." && pwd)"

# プロジェクトルートを環境変数にエクスポート
export PROJECT_ROOT

# プロジェクトルートに移動
cd "$PROJECT_ROOT"

# Cargo.toml の存在を確認
if [[ ! -f Cargo.toml ]]; then
    echo "エラー: プロジェクトルートが見つかりません (Cargo.toml がありません): ${PROJECT_ROOT}" >&2
    exit 1
fi
