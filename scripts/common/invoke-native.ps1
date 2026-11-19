# ========================================================================
# Script Name : invoke-native.ps1
# Description : ネイティブコマンドを実行し、終了コードが 0 以外なら例外を投げる
# Usage       : . (Join-Path $PSScriptRoot '..\common\invoke-native.ps1')
#               Invoke-Native cargo clippy --all-targets '--' -D warnings
# Requires    : PowerShell 7.0+
# ========================================================================

#requires -Version 7.0

# 先頭の引数をコマンド、残りをその引数として実行する
# (パラメーターバインドを避けて $args を使う。裸の `--` はバインダーに消費されるため、必要なら '--' と引用符で囲む)
function Invoke-Native {
    $command = $args[0]
    # 引数が 1 つでも配列にする(文字列のままだとスプラットで 1 文字ずつに分解される)
    $arguments = @($args | Select-Object -Skip 1)

    & $command @arguments

    if ($LASTEXITCODE -ne 0) {
        $commandLine = (@($command) + $arguments) -join ' '
        throw "エラー: $commandLine が終了コード $LASTEXITCODE で失敗しました"
    }
}
