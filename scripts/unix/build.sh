#!/usr/bin/env bash
# ========================================================================
# Script Name : build.sh
# Description : Unix (Linux / macOS) 向けのビルド実行スクリプト
# Usage       : ./build.sh [--release|-r]
# ========================================================================

# シェルオプションを設定(エラー時に即終了)
set -euo pipefail

# プロジェクトルートへ移動
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../common/cd-project-root.sh
source "$SCRIPT_DIR/../common/cd-project-root.sh"

# エラー時のメッセージを設定
trap 'echo "ビルドに失敗しました" >&2' ERR

# 引数を解析(--release / -r)
RELEASE=false
for arg in "$@"; do
    case $arg in
        --release|-r)
            RELEASE=true
            ;;
        *)
            # 打ち間違いを見逃さないよう、未知の引数はエラーにする
            echo "不明な引数です: $arg" >&2
            echo "使い方: ./build.sh [--release|-r]" >&2
            exit 1
            ;;
    esac
done

# ビルドを実行
echo "Rust プロジェクトのビルドを実行しています..."
echo

if [[ "$RELEASE" == true ]]; then
    echo "リリースビルドを実行中..."
    cargo build --release
else
    echo "デバッグビルドを実行中..."
    cargo build
fi
echo

# 完了メッセージを表示
echo "ビルドが完了しました"
