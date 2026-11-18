# ========================================================================
# Script Name : build.ps1
# Description : Windows用のビルド実行スクリプト
# Usage       : ./build.ps1 [--release|-r]
# Requires    : PowerShell 7.0+
# ========================================================================

#requires -Version 7.0

param(
    [switch]$Release
)

# シェルオプションを設定(エラー時に即終了)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# README の --release / -r もスイッチとして扱う
# (Invoke-ScriptMain の scriptblock 内 $args はスクリプト引数ではない)
$IsRelease = [bool]$Release
$UnknownArgs = @()
foreach ($arg in $args) {
    if ($arg -eq '--release' -or $arg -eq '-r') {
        $IsRelease = $true
    } else {
        $UnknownArgs += $arg
    }
}

# ダブルクリック実行時の Enter 待ちヘルパーを読み込み
. (Join-Path $PSScriptRoot '..\common\wait-if-double-clicked.ps1')

# ネイティブコマンドの終了コード検査ヘルパーを読み込み
. (Join-Path $PSScriptRoot '..\common\invoke-native.ps1')

Invoke-ScriptMain {
    # 未知の引数は打ち間違いの可能性が高いため、ビルド前にエラーにする
    if ($UnknownArgs.Count -gt 0) {
        throw "不明な引数です: $($UnknownArgs -join ' ')`n使い方: ./build.ps1 [--release|-r]"
    }

    # プロジェクトルートへ移動
    . (Join-Path $PSScriptRoot '..\common\cd-project-root.ps1')

    # ビルドを実行
    Write-Host 'Rust プロジェクトのビルドを実行しています...'
    Write-Host ''

    if ($IsRelease) {
        Write-Host 'リリースビルドを実行中...'
        Invoke-Native cargo build --release
    } else {
        Write-Host 'デバッグビルドを実行中...'
        Invoke-Native cargo build
    }

    Write-Host ''
    Write-Host 'ビルドが完了しました'
}
