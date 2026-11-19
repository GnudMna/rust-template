# ========================================================================
# Script Name : check.ps1
# Description : Windows用の品質チェックスクリプト(fmt / clippy / test / doc)
# Usage       : ./check.ps1
# Requires    : PowerShell 7.0+
# ========================================================================

#requires -Version 7.0

# シェルオプションを設定(エラー時に即終了)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ダブルクリック実行時の Enter 待ちヘルパーを読み込み
. (Join-Path $PSScriptRoot '..\common\wait-if-double-clicked.ps1')

# ネイティブコマンドの終了コード検査ヘルパーを読み込み
. (Join-Path $PSScriptRoot '..\common\invoke-native.ps1')

Invoke-ScriptMain {
    # プロジェクトルートへ移動
    . (Join-Path $PSScriptRoot '..\common\cd-project-root.ps1')

    # 品質チェックを開始(--locked で Cargo.lock の更新漏れもエラーにする)
    Write-Host '品質チェックを実行しています...'
    Write-Host ''

    # コード整形を検証
    Write-Host 'コード整形を検証中...'
    Invoke-Native cargo fmt --check
    Write-Host ''

    # Clippy を実行
    Write-Host 'Clippy を実行中...'
    Invoke-Native cargo clippy --all-targets --locked '--' -D warnings
    Write-Host ''

    # テストを実行
    Write-Host 'テストを実行中...'
    Invoke-Native cargo test --all-targets --locked

    Invoke-Native cargo test --doc --locked
    Write-Host ''

    # ドキュメントを生成(警告をエラーとして扱う)
    Write-Host 'ドキュメントを生成中...'
    $previousRustdocFlags = $env:RUSTDOCFLAGS
    $env:RUSTDOCFLAGS = '-D warnings'
    try {
        Invoke-Native cargo doc --no-deps --locked
    } finally {
        if ($null -eq $previousRustdocFlags) {
            Remove-Item Env:RUSTDOCFLAGS -ErrorAction SilentlyContinue
        } else {
            $env:RUSTDOCFLAGS = $previousRustdocFlags
        }
    }
    Write-Host ''

    # 完了メッセージを表示
    Write-Host 'すべてのチェックが完了しました'
}
