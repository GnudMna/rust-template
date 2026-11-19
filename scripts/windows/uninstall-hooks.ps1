# ========================================================================
# Script Name : uninstall-hooks.ps1
# Description : install-hooks.ps1 で有効にした Git フック(.githooks)を無効にする
# Usage       : ./uninstall-hooks.ps1
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

    # install-hooks.ps1 が core.hooksPath に設定するフックの配置先
    $HooksPath = '.githooks'

    # Git リポジトリであることを確認
    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'エラー: Git リポジトリではありません'
    }

    # 他のツールなどが設定した core.hooksPath は解除しない
    # (未設定の場合の終了コード 1 は失敗ではないため、Invoke-ScriptMain に失敗と判定させないよう戻す)
    $CurrentHooksPath = git config --local --get core.hooksPath
    if ($LASTEXITCODE -gt 1) {
        throw "エラー: git config が終了コード $LASTEXITCODE で失敗しました"
    }
    $global:LASTEXITCODE = 0

    if (-not $CurrentHooksPath) {
        Write-Host 'Git フックは有効になっていません'
        return
    }
    if ($CurrentHooksPath -ne $HooksPath) {
        throw "エラー: core.hooksPath は `"$CurrentHooksPath`" に設定されています ($HooksPath ではないため解除しません)"
    }

    # Git フックを無効化
    Invoke-Native git config --local --unset core.hooksPath

    # 完了メッセージを表示
    Write-Host 'Git フックを無効にしました'
}
