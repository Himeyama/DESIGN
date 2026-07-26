#Requires -Version 7
<#
    DESIGN リポジトリのスキルを対話的に選択し、Claude Code のスキルディレクトリに登録する。

    使い方:
        pwsh -c "irm https://raw.githubusercontent.com/Himeyama/DESIGN/main/scripts/install.ps1 | iex"
        pwsh ./scripts/install.ps1 -Scope User
        pwsh ./scripts/install.ps1 -Scope Project -Skills csharp-coding,shell-scripting -Force
#>

# 全体を script block 化して & で呼び出すことで、`irm | iex` のように呼び出し元スコープで
# 実行される場合でも毎回新しいスコープを得る（同一セッションでの再実行時に前回の
# $Scope 等が残って ValidateSet と衝突するのを防ぐ）。ファイル実行時は param を持たないため
# 未束縛の引数が $args に入り、@args で内側の script block にそのまま渡される。
& {
    [CmdletBinding()]
    param(
        [ValidateSet("User", "Project")]
        [string]$Scope,

        [string[]]$Skills,

        [switch]$Force
    )

    $ErrorActionPreference = "Stop"

    $RepoOwner = "Himeyama"
    $RepoName = "DESIGN"
    $Branch = "main"
    $ApiRoot = "https://api.github.com/repos/$RepoOwner/$RepoName/contents"
    $RawRoot = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"

    function Get-GitHubDirectory {
        param([string]$Path)

        $uri = "$ApiRoot/$Path`?ref=$Branch"
        return Invoke-RestMethod -Uri $uri -Headers @{ "User-Agent" = "DESIGN-installer" }
    }

    function Select-Skills {
        param([string[]]$Names)

        $selected = New-Object bool[] ($Names.Count)
        $cursor = 0

        function Write-Menu {
            Clear-Host
            Write-Host "登録するスキルを選択してください (↑/↓: 移動, Space: 選択, A: 全選択, Enter: 決定)"
            Write-Host ""
            for ($i = 0; $i -lt $Names.Count; $i++) {
                $prefix = if ($i -eq $cursor) { ">" } else { " " }
                $mark = if ($selected[$i]) { "x" } else { " " }
                Write-Host "$prefix [$mark] $($Names[$i])"
            }
        }

        while ($true) {
            Write-Menu
            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                "UpArrow" { $cursor = ($cursor - 1 + $Names.Count) % $Names.Count }
                "K" { $cursor = ($cursor - 1 + $Names.Count) % $Names.Count }
                "DownArrow" { $cursor = ($cursor + 1) % $Names.Count }
                "J" { $cursor = ($cursor + 1) % $Names.Count }
                "Spacebar" { $selected[$cursor] = -not $selected[$cursor] }
                "A" {
                    $allSelected = -not ($selected -contains $false)
                    for ($i = 0; $i -lt $selected.Count; $i++) { $selected[$i] = -not $allSelected }
                }
                "Enter" {
                    $result = @()
                    for ($i = 0; $i -lt $Names.Count; $i++) {
                        if ($selected[$i]) { $result += $Names[$i] }
                    }
                    return $result
                }
            }
        }
    }

    function Select-SingleOption {
        param(
            [string]$Title,
            [string[]]$Labels
        )

        $cursor = 0

        function Write-Menu {
            Clear-Host
            Write-Host "$Title (↑/↓: 移動, Enter: 決定)"
            Write-Host ""
            for ($i = 0; $i -lt $Labels.Count; $i++) {
                $prefix = if ($i -eq $cursor) { ">" } else { " " }
                Write-Host "$prefix $($Labels[$i])"
            }
        }

        while ($true) {
            Write-Menu
            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                "UpArrow" { $cursor = ($cursor - 1 + $Labels.Count) % $Labels.Count }
                "K" { $cursor = ($cursor - 1 + $Labels.Count) % $Labels.Count }
                "DownArrow" { $cursor = ($cursor + 1) % $Labels.Count }
                "J" { $cursor = ($cursor + 1) % $Labels.Count }
                "Enter" { return $cursor }
            }
        }
    }

    function Get-DestinationRoot {
        param([string]$ChosenScope)

        if (-not $ChosenScope) {
            if ([Console]::IsInputRedirected) {
                do {
                    $answer = Read-Host "インストール先を選択してください [User/Project]"
                } while ($answer -notin @("User", "Project"))
                $ChosenScope = $answer
            }
            else {
                $index = Select-SingleOption -Title "インストール先を選択してください" -Labels @("User", "Project")
                $ChosenScope = @("User", "Project")[$index]
            }
        }

        if ($ChosenScope -eq "User") {
            return Join-Path $HOME ".claude/skills"
        }
        return Join-Path (Get-Location).Path ".claude/skills"
    }

    function Install-Skill {
        param(
            [string]$Name,
            [string]$DestinationRoot
        )

        $destDir = Join-Path $DestinationRoot $Name

        if ((Test-Path $destDir) -and -not $Force) {
            $answer = Read-Host "既に存在します: $destDir を上書きしますか？ [y/N]"
            if ($answer -notin @("y", "Y")) {
                Write-Host "スキップ: $Name"
                return $false
            }
        }

        New-Item -ItemType Directory -Path $destDir -Force | Out-Null

        $entries = Get-GitHubDirectory -Path "skills/$Name"
        foreach ($entry in $entries) {
            if ($entry.type -eq "file" -and $entry.name -eq "skill.md") {
                $outFile = Join-Path $destDir "SKILL.md"
                Invoke-WebRequest -Uri "$RawRoot/skills/$Name/skill.md" -OutFile $outFile
            }
            elseif ($entry.type -eq "dir" -and $entry.name -eq "examples") {
                $examplesDir = Join-Path $destDir "examples"
                New-Item -ItemType Directory -Path $examplesDir -Force | Out-Null

                $exampleEntries = Get-GitHubDirectory -Path "skills/$Name/examples"
                foreach ($exampleEntry in $exampleEntries) {
                    if ($exampleEntry.type -eq "file") {
                        $outFile = Join-Path $examplesDir $exampleEntry.name
                        Invoke-WebRequest -Uri "$RawRoot/skills/$Name/examples/$($exampleEntry.name)" -OutFile $outFile
                    }
                }
            }
        }

        Write-Host "インストール完了: $Name -> $destDir"
        return $true
    }

    Write-Host "スキル一覧を取得しています..."
    $rootEntries = Get-GitHubDirectory -Path "skills"
    $skillDirs = $rootEntries | Where-Object { $_.type -eq "dir" } | Select-Object -ExpandProperty name

    if (-not $skillDirs -or $skillDirs.Count -eq 0) {
        throw "スキル一覧の取得に失敗しました。"
    }

    if ($Skills) {
        $requested = $Skills -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        $chosen = $requested | Where-Object { $_ -in $skillDirs }
        $missing = $requested | Where-Object { $_ -notin $skillDirs }
        if ($missing) {
            Write-Warning "存在しないスキル名を無視しました: $($missing -join ', ')"
        }
    }
    elseif ([Console]::IsInputRedirected) {
        throw "対話的な選択には端末の標準入力が必要です。標準入力経由でスクリプト全体を渡す方法では選択 UI が使えません。代わりに次のいずれかを使ってください:`n  pwsh -c `"irm $RawRoot/scripts/install.ps1 | iex`"`n  curl -sL $RawRoot/scripts/install.ps1 -o install.ps1; pwsh ./install.ps1`n  pwsh ./scripts/install.ps1 -Skills <name1>,<name2>"
    }
    else {
        $chosen = Select-Skills -Names $skillDirs
    }

    if (-not $chosen -or $chosen.Count -eq 0) {
        Write-Host "選択されたスキルがありません。終了します。"
        return
    }

    $destinationRoot = Get-DestinationRoot -ChosenScope $Scope

    $installed = @()
    foreach ($name in $chosen) {
        if (Install-Skill -Name $name -DestinationRoot $destinationRoot) {
            $installed += $name
        }
    }

    Write-Host ""
    Write-Host "=== 完了 ==="
    if ($installed.Count -eq 0) {
        Write-Host "インストールされたスキルはありません。"
    }
    else {
        foreach ($name in $installed) {
            Write-Host " - $name -> $(Join-Path $destinationRoot $name)"
        }
    }
} @args
