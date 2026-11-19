# ========================================================================
# Script Name : rename-project.ps1
# Description : テンプレートのプロジェクト名を一括変更する
# Usage       : ./rename-project.ps1 <new-name> [copyright-holder]
# Requires    : PowerShell 7.0+
# ========================================================================

#requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$NewName,

    [Parameter(Position = 1)]
    [string]$CopyrightHolder = ''
)

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

    # UTF-8(BOM なし)読み書き用のヘルパーを定義
    $Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

    function Read-Utf8NoBom {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Path
        )

        return [System.IO.File]::ReadAllText($Path, $Utf8NoBom)
    }

    function Write-Utf8NoBom {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Path,

            [Parameter(Mandatory = $true)]
            [string]$Value
        )

        [System.IO.File]::WriteAllText($Path, $Value, $Utf8NoBom)
    }

    # プロジェクト名の形式を検証(kebab-case)
    if ($NewName -notmatch '^[a-z][a-z0-9]*(-[a-z0-9]+)*$') {
        throw 'エラー: プロジェクト名は kebab-case で指定してください (例: my-project)'
    }

    # Rust 識別子が予約された名前でないか検証(ファイルを書き換える前に弾く)
    $NewIdent = $NewName -replace '-', '_'
    $ReservedNames = @(
        # キーワード(将来の予約語を含む)
        'abstract', 'as', 'async', 'await', 'become', 'box', 'break', 'const', 'continue',
        'crate', 'do', 'dyn', 'else', 'enum', 'extern', 'false', 'final', 'fn', 'for', 'gen',
        'if', 'impl', 'in', 'let', 'loop', 'macro', 'match', 'mod', 'move', 'mut', 'override',
        'priv', 'pub', 'ref', 'return', 'self', 'static', 'struct', 'super', 'trait', 'true',
        'try', 'type', 'typeof', 'unsafe', 'unsized', 'use', 'virtual', 'where', 'while', 'yield',
        # 標準ライブラリのクレート名
        'alloc', 'core', 'proc_macro', 'std', 'test',
        # Cargo のビルドディレクトリ名
        'build', 'deps', 'examples', 'incremental',
        # Windows の予約デバイス名
        'aux', 'con', 'nul', 'prn', 'com1', 'com2', 'com3', 'com4', 'com5', 'com6', 'com7',
        'com8', 'com9', 'lpt1', 'lpt2', 'lpt3', 'lpt4', 'lpt5', 'lpt6', 'lpt7', 'lpt8', 'lpt9'
    )
    if ($ReservedNames -contains $NewIdent) {
        throw "エラー: `"$NewName`" は Rust または Cargo で予約された名前のため使用できません"
    }

    # 著作権者名を検証(Cargo.toml の文字列リテラルを壊す文字は不可)
    if ($CopyrightHolder -match '["\\\p{Cc}]') {
        throw 'エラー: 著作権者名に " \ および制御文字(改行など)は使用できません'
    }

    # 現在のプロジェクト名と Rust 識別子を取得
    $CargoTomlPath = Join-Path $ProjectRoot 'Cargo.toml'
    $CargoToml = Read-Utf8NoBom -Path $CargoTomlPath
    if ($CargoToml -notmatch 'name = "([^"]+)"') {
        throw 'エラー: Cargo.toml から name を読み取れません'
    }

    $CurrentName = $Matches[1]
    $OldIdent = $CurrentName -replace '-', '_'

    # 変更が不要な場合は終了(著作権者のみ更新する場合は続行)
    $NameUnchanged = $CurrentName -eq $NewName
    if ($NameUnchanged -and -not $CopyrightHolder) {
        Write-Host "プロジェクト名は既に `"$NewName`" です"
        return
    }

    if (-not $NameUnchanged) {
        Write-Host "プロジェクト名を `"$CurrentName`" から `"$NewName`" に変更しています..."
        Write-Host ''

        # Cargo.toml の name を更新
        $CargoToml = $CargoToml -replace "name = `"$CurrentName`"", "name = `"$NewName`""

        Write-Utf8NoBom -Path $CargoTomlPath -Value $CargoToml

        # デバッグ設定のパッケージ名 / バイナリ名を更新
        $LaunchJsonPath = Join-Path $ProjectRoot '.vscode\launch.json'
        if (Test-Path -LiteralPath $LaunchJsonPath) {
            $LaunchJson = Read-Utf8NoBom -Path $LaunchJsonPath
            # 項目単位で置換する(部分文字列置換だと 2 回目以降のリネームで名前が壊れる)
            $EscName = [regex]::Escape($CurrentName)
            $EscIdent = [regex]::Escape($OldIdent)
            $NewNameRep = $NewName.Replace('$', '$$')
            $NewIdentRep = $NewIdent.Replace('$', '$$')
            $LaunchJson = $LaunchJson -replace "(--(?:bin|package)=)$EscName`"", "`${1}$NewNameRep`""
            $LaunchJson = $LaunchJson -replace "(`"name`": `")$EscName(`",\s*`"kind`": `"bin`")", "`${1}$NewNameRep`${2}"
            $LaunchJson = $LaunchJson -replace "(`"name`": `")$EscIdent(`",\s*`"kind`": `"lib`")", "`${1}$NewIdentRep`${2}"
            Write-Utf8NoBom -Path $LaunchJsonPath -Value $LaunchJson
        }

        # use 文と doc コメントのクレート名を更新
        foreach ($File in @('src/main.rs', 'tests/integration_test.rs', 'src/lib.rs')) {
            $FilePath = Join-Path $ProjectRoot $File
            $Content = Read-Utf8NoBom -Path $FilePath
            $Content = $Content -replace "use ${OldIdent}::", "use ${NewIdent}::"
            $OldCrateRef = '`' + $CurrentName + '`'
            $NewCrateRef = '`' + $NewName + '`'
            $Content = $Content.Replace($OldCrateRef, $NewCrateRef)
            Write-Utf8NoBom -Path $FilePath -Value $Content
        }

        # README のタイトルを更新し、テンプレートの案内行(と直後の空行)を削除
        $ReadmePath = Join-Path $ProjectRoot 'README.md'
        if (Test-Path -LiteralPath $ReadmePath) {
            $Readme = Read-Utf8NoBom -Path $ReadmePath
            $Readme = $Readme -replace "(?m)^# $([regex]::Escape($CurrentName))(?=\r?$)", ('# ' + $NewName.Replace('$', '$$'))
            $Readme = $Readme -replace '(?m)^.*<!-- template-notice.*\r?\n(\r?\n)?', ''
            Write-Utf8NoBom -Path $ReadmePath -Value $Readme
        }

        # テンプレートの使い方はプロジェクトに不要なため削除
        $TemplateDocPath = Join-Path $ProjectRoot 'TEMPLATE.md'
        if (Test-Path -LiteralPath $TemplateDocPath) {
            Remove-Item -LiteralPath $TemplateDocPath
        }
    }

    # 著作権表記を更新(指定時のみ)
    if ($CopyrightHolder) {
        if ($NameUnchanged) {
            Write-Host "著作権者を `"$CopyrightHolder`" に更新しています..."
            Write-Host ''
        }

        $CopyrightYear = Get-Date -Format 'yyyy'
        $CopyrightLine = "Copyright (c) $CopyrightYear $CopyrightHolder"

        $LicensePath = Join-Path $ProjectRoot 'LICENSE'
        $License = Read-Utf8NoBom -Path $LicensePath
        # 置換文字列中の $ を展開させないようエスケープ
        $CopyrightReplacement = $CopyrightLine.Replace('$', '$$')
        $License = [regex]::Replace($License, '(?m)^Copyright \(c\) .*', $CopyrightReplacement)
        Write-Utf8NoBom -Path $LicensePath -Value $License

        # Cargo.toml は name 更新時に書き込み済みなので読み直す
        $CargoToml = Read-Utf8NoBom -Path $CargoTomlPath
        $LegalCopyright = 'LegalCopyright = "' + $CopyrightReplacement + '"'
        $CargoToml = [regex]::Replace($CargoToml, '(?m)^LegalCopyright = ".*"', $LegalCopyright)
        Write-Utf8NoBom -Path $CargoTomlPath -Value $CargoToml
    }

    # Cargo.lock を更新
    Write-Host 'Cargo.lock を更新しています...'
    Invoke-Native cargo check --quiet
    Write-Host ''

    # 手動更新が必要な項目を案内
    Write-Host '変更が完了しました。必要に応じて以下を手動で更新してください:'
    Write-Host '  - Cargo.toml の description, repository'
    Write-Host '  - README.md の概要'
    Write-Host '  - assets/icon.ico'
    if (-not $CopyrightHolder) {
        Write-Host '  - LICENSE / Cargo.toml の著作権表記(または -CopyrightHolder を指定して再実行)'
    }
}
