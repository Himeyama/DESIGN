#!/usr/bin/env bash
#
# Claude Code に Playwright MCP（ブラウザ自動操作）を導入・設定する。
#
# 使い方:
#   ./scripts/install-playwright-mcp.sh
#   ./scripts/install-playwright-mcp.sh --scope project
#   ./scripts/install-playwright-mcp.sh --scope user --playwright-version 0.0.79
#
# npx（Node.js）や claude コマンドが無い場合は自動でのインストールを試みます
# （brew / apt / dnf / yum / pacman / apk / zypper のいずれかが必要）。

set -euo pipefail

SCOPE=""
PLAYWRIGHT_VERSION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --scope)
            SCOPE="$2"
            shift 2
            ;;
        --playwright-version)
            PLAYWRIGHT_VERSION="$2"
            shift 2
            ;;
        *)
            echo "不明な引数です: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -n "$SCOPE" && "$SCOPE" != "user" && "$SCOPE" != "project" ]]; then
    echo "--scope は user か project を指定してください" >&2
    exit 1
fi

sudo_cmd() {
    if [[ $EUID -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
        echo "sudo"
    fi
}

# --- 1. Node.js / npx の確認・導入 -------------------------------------
install_node() {
    echo "npx（Node.js）が見つかりません。インストールを試みます..." >&2

    local sudo_cmd
    sudo_cmd=$(sudo_cmd)

    if command -v brew >/dev/null 2>&1; then
        brew install node
    elif command -v apt-get >/dev/null 2>&1; then
        $sudo_cmd apt-get update && $sudo_cmd apt-get install -y nodejs npm
    elif command -v dnf >/dev/null 2>&1; then
        $sudo_cmd dnf install -y nodejs npm
    elif command -v yum >/dev/null 2>&1; then
        $sudo_cmd yum install -y nodejs npm
    elif command -v pacman >/dev/null 2>&1; then
        $sudo_cmd pacman -Sy --noconfirm nodejs npm
    elif command -v apk >/dev/null 2>&1; then
        $sudo_cmd apk add nodejs npm
    elif command -v zypper >/dev/null 2>&1; then
        $sudo_cmd zypper install -y nodejs npm
    else
        echo "対応するパッケージマネージャーが見つかりませんでした。https://nodejs.org/ から手動でインストールしてください。" >&2
        exit 1
    fi
}

if ! command -v npx >/dev/null 2>&1; then
    install_node
    if ! command -v npx >/dev/null 2>&1; then
        echo "Node.js のインストール後も npx が見つかりません。新しいシェルを開いて再実行してください。" >&2
        exit 1
    fi
    echo "npx をインストールしました。" >&2
else
    echo "npx は導入済みです。" >&2
fi

# --- 2. claude コマンドの確認・導入 --------------------------------------
if ! command -v claude >/dev/null 2>&1; then
    echo "claude コマンドが見つかりません。npm でインストールします..." >&2
    npm install -g "@anthropic-ai/claude-code"
    if ! command -v claude >/dev/null 2>&1; then
        echo "claude のインストール後も claude コマンドが見つかりません。新しいシェルを開いて再実行してください。" >&2
        exit 1
    fi
    echo "claude をインストールしました。" >&2
else
    echo "claude コマンドは導入済みです。" >&2
fi

# --- 3. 既に設定済みでないか確認 -----------------------------------------
if claude mcp list 2>&1 | grep -q "playwright"; then
    echo "playwright は既に MCP に設定済みです。再導入をスキップします。" >&2
    exit 0
fi

# --- 4. スコープの決定 ----------------------------------------------------
if [[ -z "$SCOPE" ]]; then
    echo ""
    echo "Playwright MCP を追加するスコープを選択してください:"
    echo "  [1] このプロジェクトのみ（推奨・.mcp.json に追加、リポジトリと共有可能）"
    echo "  [2] ユーザー全体（~/.claude.json に追加、全プロジェクトで使用可能）"
    read -r -p "番号を入力してください (既定: 1): " answer
    if [[ "$answer" == "2" ]]; then
        SCOPE="user"
    else
        SCOPE="project"
    fi
fi
echo "スコープ: $SCOPE" >&2

# --- 5. バージョンを固定して追加 ------------------------------------------
if [[ -z "$PLAYWRIGHT_VERSION" ]]; then
    echo "@playwright/mcp の最新安定版バージョンを取得します..." >&2
    PLAYWRIGHT_VERSION=$(npm view "@playwright/mcp" version)
fi
echo "@playwright/mcp@$PLAYWRIGHT_VERSION を追加します（@latest は使用しません）。" >&2

claude mcp add playwright --scope "$SCOPE" -- npx -y "@playwright/mcp@$PLAYWRIGHT_VERSION"

# --- 6. 結果の確認 ---------------------------------------------------------
echo "設定内容を確認します。" >&2
claude mcp list

echo ""
echo "新しく追加した MCP サーバーは現在のセッションには反映されません。Claude Code を再起動してください。" >&2
if [[ "$SCOPE" == "project" ]]; then
    echo "プロジェクトスコープのため、再起動後の初回起動時に信頼確認プロンプトが表示される場合があります。" >&2
fi
