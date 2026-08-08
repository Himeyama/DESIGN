#Requires -Version 7
<#
    Claude Code に Playwright MCP（ブラウザ自動操作）を導入・設定する。

    使い方:
        pwsh ./scripts/install-playwright-mcp.ps1
        pwsh ./scripts/install-playwright-mcp.ps1 -Scope Project
        pwsh ./scripts/install-playwright-mcp.ps1 -Scope User -PlaywrightVersion 0.0.79
#>

& {
    [CmdletBinding()]
    param(
        [ValidateSet("Project", "User")]
        [string]$Scope,

        # 省略時は npm から最新安定版を取得してピン留めする
        [string]$PlaywrightVersion
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    function Write-Info { param([string]$Message) Write-Host "[INFO]  $Message" -ForegroundColor Cyan }
    function Write-Warn { param([string]$Message) Write-Host "[WARN]  $Message" -ForegroundColor Yellow }
    function Write-Err  { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

    function Test-CommandExists {
        param([string]$Name)
        return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
    }

    # --- 1. Node.js / npx の確認・導入 ---------------------------------
    if (-not (Test-CommandExists "npx")) {
        Write-Warn "npx（Node.js）が見つかりません。winget でインストールします。"
        if (-not (Test-CommandExists "winget")) {
            Write-Err "winget が利用できないため Node.js を自動インストールできません。https://nodejs.org/ から手動でインストールしてください。"
            exit 1
        }
        winget install --id OpenJS.NodeJS.LTS -e --source winget
        if (-not (Test-CommandExists "npx")) {
            Write-Err "Node.js のインストール後も npx が見つかりません。新しいシェルを開いて再実行してください。"
            exit 1
        }
    }
    else {
        Write-Info "npx は導入済みです。"
    }

    # --- 2. claude コマンドの確認・導入 ---------------------------------
    if (-not (Test-CommandExists "claude")) {
        Write-Warn "claude コマンドが見つかりません。npm でインストールします。"
        npm install -g "@anthropic-ai/claude-code"
        if (-not (Test-CommandExists "claude")) {
            Write-Err "claude のインストール後も claude コマンドが見つかりません。新しいシェルを開いて再実行してください。"
            exit 1
        }
    }
    else {
        Write-Info "claude コマンドは導入済みです。"
    }

    # --- 3. 既に設定済みでないか確認 -------------------------------------
    $mcpList = & claude mcp list 2>&1
    if ($mcpList -match "playwright") {
        Write-Info "playwright は既に MCP に設定済みです。再導入をスキップします。"
        exit 0
    }

    # --- 4. スコープの決定 ------------------------------------------------
    if (-not $Scope) {
        Write-Host ""
        Write-Host "Playwright MCP を追加するスコープを選択してください:"
        Write-Host "  [1] このプロジェクトのみ（推奨・.mcp.json に追加、リポジトリと共有可能）"
        Write-Host "  [2] ユーザー全体（~/.claude.json に追加、全プロジェクトで使用可能）"
        $answer = Read-Host "番号を入力してください (既定: 1)"
        $Scope = if ($answer -eq "2") { "user" } else { "project" }
    }
    else {
        $Scope = $Scope.ToLower()
    }
    Write-Info "スコープ: $Scope"

    # --- 5. バージョンを固定して追加 ---------------------------------------
    if (-not $PlaywrightVersion) {
        Write-Info "@playwright/mcp の最新安定版バージョンを取得します。"
        $PlaywrightVersion = (npm view "@playwright/mcp" version).Trim()
    }
    Write-Info "@playwright/mcp@$PlaywrightVersion を追加します（@latest は使用しません）。"

    & claude mcp add playwright --scope $Scope -- npx -y "@playwright/mcp@$PlaywrightVersion"

    # --- 6. 結果の確認 -----------------------------------------------------
    Write-Info "設定内容を確認します。"
    & claude mcp list

    Write-Host ""
    Write-Warn "新しく追加した MCP サーバーは現在のセッションには反映されません。Claude Code を再起動してください。"
    if ($Scope -eq "project") {
        Write-Warn "プロジェクトスコープのため、再起動後の初回起動時に信頼確認プロンプトが表示される場合があります。"
    }
} @args
