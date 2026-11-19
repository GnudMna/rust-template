# ========================================================================
# Script Name : install-hooks.ps1
# Description : プロジェクトの Git フック(.githooks)を有効にする
# Usage       : ./install-hooks.ps1
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

    # core.hooksPath に設定するフックの配置先(作業ツリーのルートからの相対パス)
    $HooksPath = '.githooks'

    # Git リポジトリであることを確認
    $Prefix = git rev-parse --show-prefix 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'エラー: Git リポジトリではありません (git init を実行してください)'
    }

    # core.hooksPath の相対パスは作業ツリーのルートを基準とするため、プロジェクトルートがそれと一致することを確認
    if ($Prefix) {
        throw 'エラー: プロジェクトルートが Git リポジトリのルートではありません'
    }

    if (-not (Test-Path -LiteralPath $HooksPath -PathType Container)) {
        throw "エラー: $HooksPath がありません"
    }

    # 他のツールなどが設定した core.hooksPath は上書きしない
    # (未設定の場合の終了コード 1 は失敗ではないため、Invoke-ScriptMain に失敗と判定させないよう戻す)
    $CurrentHooksPath = git config --local --get core.hooksPath
    if ($LASTEXITCODE -gt 1) {
        throw "エラー: git config が終了コード $LASTEXITCODE で失敗しました"
    }
    $global:LASTEXITCODE = 0

    if ($CurrentHooksPath -eq $HooksPath) {
        Write-Host "Git フックは既に有効です (core.hooksPath = $HooksPath)"
        return
    }
    if ($CurrentHooksPath) {
        throw "エラー: core.hooksPath は既に `"$CurrentHooksPath`" に設定されています`n置き換える場合は git config --local --unset core.hooksPath で解除してから再実行してください"
    }

    # 有効にすると、これまでのフックの配置先(.git/hooks やグローバル設定の core.hooksPath)は使われなくなる
    $CurrentHooksDir = Invoke-Native git rev-parse --git-path hooks
    $ExistingHooks = @()
    if (Test-Path -LiteralPath $CurrentHooksDir -PathType Container) {
        $ExistingHooks = @(
            Get-ChildItem -LiteralPath $CurrentHooksDir -File |
                Where-Object Extension -ne '.sample' |
                ForEach-Object Name
        )
    }

    # Git フックを有効化
    Invoke-Native git config --local core.hooksPath $HooksPath

    # 完了メッセージを表示
    Write-Host "Git フックを有効にしました (core.hooksPath = $HooksPath)"
    Write-Host '  - pre-push: push 前に品質チェック (check スクリプト) を実行'
    if ($ExistingHooks.Count -gt 0) {
        Write-Host "注意: $CurrentHooksDir にある次のフックは使われなくなります: $($ExistingHooks -join ' ')"
    }
    Write-Host '無効にする場合は uninstall-hooks.ps1 を実行してください'
}
