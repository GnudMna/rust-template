# ========================================================================
# Script Name : wait-if-double-clicked.ps1
# Description : エクスプローラーからのダブルクリック実行時にウィンドウを開いたままにする
# Usage       : . (Join-Path $PSScriptRoot '..\common\wait-if-double-clicked.ps1')
#               Invoke-ScriptMain { ... }
# Requires    : PowerShell 7.0+
# ========================================================================

#requires -Version 7.0

# pwsh がスクリプトファイル実行用に起動されたか (対話セッションで .\script.ps1 した場合は false)
function Test-StartedAsFileInvocation {
    $arguments = @([Environment]::GetCommandLineArgs())
    if ($arguments.Count -lt 2) {
        return $false
    }

    for ($i = 1; $i -lt $arguments.Count; $i++) {
        $argument = $arguments[$i]
        if ($argument -match '^-(File|f|Command|c|EncodedCommand)(:.*)?$') {
            return $true
        }
        if ($argument -match '\.ps1$') {
            return $true
        }
    }

    return $false
}

# エクスプローラー経由の起動かどうかを直接の親プロセスで判定する
# (端末の一覧を管理せずに済むよう、親が explorer.exe / OpenWith.exe の場合のみ対象とする)
function Test-LaunchedFromExplorer {
    try {
        # 対話ホスト内での実行は、親が explorer でも待たない
        if (-not (Test-StartedAsFileInvocation)) {
            return $false
        }

        $self = Get-CimInstance Win32_Process -Filter "ProcessId=$PID" -ErrorAction Stop
        if (-not $self -or $self.ParentProcessId -eq 0) {
            return $false
        }

        $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$($self.ParentProcessId)" -ErrorAction Stop
        if (-not $parent) {
            return $false
        }

        return @('explorer.exe', 'openwith.exe') -contains $parent.Name.ToLowerInvariant()
    } catch {
        return $false
    }
}

# ダブルクリック実行時のみ Enter 待ちでウィンドウを開いたままにする
function Wait-IfDoubleClicked {
    if (-not (Test-LaunchedFromExplorer)) {
        return
    }

    Write-Host ''
    Read-Host '終了するには Enter キーを押してください'
}

# スクリプト本体を実行し、エラー時も Enter 待ち後に静かに終了する
function Invoke-ScriptMain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Body
    )

    $exitCode = 0

    # カレントディレクトリはセッション全体で共有されるため、終了時に呼び出し元へ戻す
    Push-Location

    try {
        # StrictMode 下の未設定参照エラーと、直前コマンドの終了コード混入を防ぐ
        $global:LASTEXITCODE = 0
        & $Body

        if ($LASTEXITCODE -ne 0) {
            $exitCode = $LASTEXITCODE
        }
    } catch {
        $exitCode = 1

        # Write-Error は $ErrorActionPreference = 'Stop' 下で再スローされるため、stderr へ直接書く
        [Console]::Error.WriteLine('')

        if ($_.Exception.Message) {
            [Console]::Error.WriteLine($_.Exception.Message)
        } else {
            [Console]::Error.WriteLine([string]$_)
        }
    } finally {
        Pop-Location
        Wait-IfDoubleClicked
    }

    if ($exitCode -ne 0) {
        exit $exitCode
    }
}
