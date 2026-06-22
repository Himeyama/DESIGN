---
name: shell-scripting
description: bash の堅牢なスクリプト設計原則。安全性・ログ・引数解析・エラー処理など。
---

# Shell Script Design Guide

堅牢で保守性の高いシェルスクリプトの設計原則。

## 基本的な安全性

スクリプトの先頭に以下を配置する：

```bash
#!/usr/bin/env bash

set -euo pipefail
```

- `set -e`: コマンドが失敗したら即座に終了
- `set -u`: 未定義の変数参照でエラー
- `set -o pipefail`: パイプ内のコマンド失敗を検知

## カラー出力の制御

ターミナル判定して、カラーを条件付きで有効にする：

```bash
# 標準出力がターミナル（TTY）かどうかで判定、NO_COLOR も確認
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  readonly RED='\033[0;31m'
  readonly YELLOW='\033[0;33m'
  readonly GREEN='\033[1;32m'
  readonly CYAN='\033[0;36m'
  readonly CYAN_DIM='\033[36m'
  readonly GRAY='\033[0;90m'
  readonly NC='\033[0m'
else
  readonly RED=''
  readonly YELLOW=''
  readonly GREEN=''
  readonly CYAN=''
  readonly CYAN_DIM=''
  readonly GRAY=''
  readonly NC=''
fi
```

- `-t 1`: ファイルディスクリプタ 1（標準出力）がターミナルかどうか判定
- `NO_COLOR` 環境変数で強制的にカラーを無効化
- パイプ経由の場合は、カラーコードが空文字列に設定される

## バージョン・ヘルプ表示

### バージョン表示

```bash
show_version() {
  echo "Command 1.0.0"
}

if [[ "${1:-}" == "-V" ]] || [[ "${1:-}" == "--version" ]]; then
  show_version
  exit 0
fi
```

### ヘルプ表示

```bash
show_help() {
  echo "Command"
  echo
  printf "%bUsage:%b hoge.sh [OPTIONS]<COMMAND>\n\n" "${GREEN}" "${NC}"
  printf "%bOptions:%b\n" "${GREEN}" "${NC}"
  printf "  %b-h%b, %b--help%b                    Show this help message\n" "${CYAN}" "${NC}" "${CYAN}" "${NC}"
  printf "  %b-V%b, %b--version%b                 Show version\n" "${CYAN}" "${NC}" "${CYAN}" "${NC}"
  printf "\n"
  printf "%bCommands:%b\n" "${GREEN}" "${NC}"
  printf "  %brun%b                        Run a command or script\n" "${CYAN}" "${NC}"
  printf "  %bversion%b                    Read or update the project's version\n" "${CYAN}" "${NC}"
}

if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
  show_help
  exit 0
fi
```

### カラー分類

- **強調緑**: Options:、Commands:、Usage: などのセクション名
- **強調シアン**: オプション名（`-v`, `--verbose`）、サブコマンド
- **通常シアン**: パラメーター値（FILE など）

## エラーハンドリングとログ

### ログ設計

タイムスタンプ、ログレベル、メッセージを統一フォーマットで出力する：

```
YYYY-MM-DD HH:mm:ss [LEVEL] message
```

### ログレベル

| レベル | 用途 | 色 |
|--------|------|-----|
| ERROR  | エラー、致命的な問題 | 赤 |
| WARN   | 警告、注意が必要な状態 | 黄 |
| INFO   | 情報、重要なイベント | シアン |
| DEBUG  | デバッグ情報、詳細トレース | グレー |

### ログ出力例

```
2026-06-09 18:18:30 [INFO]  Application started
2026-06-09 18:18:31 [WARN]  Configuration validation failed
2026-06-09 18:18:32 [ERROR] Database connection timeout
2026-06-09 18:18:33 [DEBUG] Processing request id=12345
```

### ログ関数の実装

```bash
log_error() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "%s %b[ERROR]%b %s\n" "$timestamp" "${RED}" "${NC}" "$1" >&2
}

log_warn() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "%s %b[WARN]%b  %s\n" "$timestamp" "${YELLOW}" "${NC}" "$1" >&2
}

log_info() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "%s %b[INFO]%b  %s\n" "$timestamp" "${CYAN}" "${NC}" "$1"
}

log_debug() {
  [[ "${VERBOSE}" == "true" ]] || return 0
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "%s %b[DEBUG]%b %s\n" "$timestamp" "${GRAY}" "${NC}" "$1"
}
```

### 実装のポイント

- **タイムスタンプ**: 無色（ISO 8601形式: `YYYY-MM-DD HH:mm:ss`）
- **ログレベル部分**: `[ERROR]` など括弧内が色付き
- **固定幅**: 最長のログレベル（ERROR）を基準に位置揃え
- **出力先**: エラーメッセージは標準エラー出力 (`>&2`)、その他は標準出力

### 色付けの制御

#### 自動判定（デフォルト）

- ターミナル出力: 色付けあり
- パイプ/リダイレクト: 色付けなし（TTY 判定で自動制御）

#### 強制無効化

`NO_COLOR` 環境変数で色付けを無効化：

```bash
$ NO_COLOR=1 ./script.sh
```

この場合、ターミナル出力でも色が付きません。

### トラップ処理

```bash
cleanup() {
  local exit_code=$?
  # クリーンアップ処理
  if [[ $exit_code -ne 0 ]]; then
    log_error "Script failed with exit code $exit_code"
  fi
  exit "$exit_code"
}

trap cleanup EXIT
```

## 関数設計

### ローカル変数の使用

```bash
process_file() {
  local file="$1"
  local result
  
  # local で変数を宣言
  result=$(some_command "$file")
  echo "$result"
}
```

### 関数の終了コード

```bash
validate_input() {
  local input="$1"
  
  if [[ -z "$input" ]]; then
    return 1
  fi
  
  return 0
}

if ! validate_input "$arg"; then
  log_error "Invalid input: $arg"
  exit 1
fi
```

## クォート処理

常に変数をダブルクォートで囲む：

```bash
# 悪い
rm -f $file

# 良い
rm -f "$file"
```

## 終了コードの規約

- `0`: 成功
- `1`: 一般的なエラー
- `2`: コマンドラインの使用法エラー
- `127`: コマンドが見つからない（シェルの慣例）

```bash
show_help >&2
exit 2
```

## 引数解析

専用の関数で引数を解析し、スクリプト先頭で定義したグローバル変数に直接設定する：

```bash
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        show_help
        exit 0
        ;;
      -V | --version)
        show_version
        exit 0
        ;;
      -v | --verbose)
        VERBOSE=true
        shift
        ;;
      -o | --output)
        if [[ -z "${2:-}" ]]; then
          log_error "Option $1 requires a value"
          show_help >&2
          exit 2
        fi
        OUTPUT="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        log_error "Unknown option: $1"
        show_help >&2
        exit 2
        ;;
      *)
        COMMAND="$1"
        shift
        break
        ;;
    esac
  done
  
  ARGS=("$@")
}
```

### 設計のポイント

- **グローバル変数を直接更新**: VERBOSE、OUTPUT、COMMAND をグローバル変数として先頭で定義し、parse_arguments で直接更新
- **値を取るオプション**: `-o FILE` 形式で、次の引数を値として取得
- **-- の処理**: `--` 以降をすべて位置パラメーターとして扱う
- **エラー処理**: 不正なオプションや欠落した値を検出
- **短・長形式**: `-v` と `--verbose` の両方をサポート

## テンプレート

```bash
#!/usr/bin/env bash
set -euo pipefail

# ====================
# Global Variables
# ====================

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERBOSE=false
OUTPUT=""
COMMAND=""
declare -a ARGS=()

# ====================
# Color codes
# ====================

if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  readonly RED='\033[0;31m'
  readonly YELLOW='\033[0;33m'
  readonly GREEN='\033[1;32m'
  readonly CYAN='\033[0;36m'
  readonly CYAN_DIM='\033[36m'
  readonly GRAY='\033[0;90m'
  readonly NC='\033[0m'
else
  readonly RED=''
  readonly YELLOW=''
  readonly GREEN=''
  readonly CYAN=''
  readonly CYAN_DIM=''
  readonly GRAY=''
  readonly NC=''
fi

# ====================
# Functions
# ====================

log_error() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "%s %b[ERROR]%b %s\n" "$timestamp" "${RED}" "${NC}" "$1" >&2
}

log_warn() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "%s %b[WARN]%b  %s\n" "$timestamp" "${YELLOW}" "${NC}" "$1" >&2
}

log_info() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "%s %b[INFO]%b  %s\n" "$timestamp" "${CYAN}" "${NC}" "$1"
}

log_debug() {
  [[ "${VERBOSE}" == "true" ]] || return 0
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "%s %b[DEBUG]%b %s\n" "$timestamp" "${GRAY}" "${NC}" "$1"
}

show_help() {
  echo "Command"
  echo
  printf "%bUsage:%b hoge.sh [OPTIONS] <COMMAND>\n\n" "${GREEN}" "${NC}"
  printf "%bOptions:%b\n" "${GREEN}" "${NC}"
  printf "  %b-v%b, %b--verbose%b                  Enable verbose output\n" "${CYAN}" "${NC}" "${CYAN}" "${NC}"
  printf "  %b-o%b, %b--output%b %bFILE%b            Write output to FILE\n" "${CYAN}" "${NC}" "${CYAN}" "${NC}" "${CYAN_DIM}" "${NC}"
  printf "  %b-h%b, %b--help%b                    Show this help message\n" "${CYAN}" "${NC}" "${CYAN}" "${NC}"
  printf "  %b-V%b, %b--version%b                 Show version\n" "${CYAN}" "${NC}" "${CYAN}" "${NC}"
  printf "\n"
  printf "%bCommands:%b\n" "${GREEN}" "${NC}"
  printf "  %brun%b                        Run a command or script\n" "${CYAN}" "${NC}"
  printf "  %bversion%b                    Read or update the project's version\n" "${CYAN}" "${NC}"
}

show_version() {
  echo "Command 1.0.0"
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        show_help
        exit 0
        ;;
      -V | --version)
        show_version
        exit 0
        ;;
      -v | --verbose)
        VERBOSE=true
        shift
        ;;
      -o | --output)
        if [[ -z "${2:-}" ]]; then
          log_error "Option $1 requires a value"
          show_help >&2
          exit 2
        fi
        OUTPUT="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        log_error "Unknown option: $1"
        show_help >&2
        exit 2
        ;;
      *)
        COMMAND="$1"
        shift
        break
        ;;
    esac
  done
  
  ARGS=("$@")
}

cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log_error "Script failed with exit code $exit_code"
  fi
  exit "$exit_code"
}

# ====================
# Main
# ====================

trap cleanup EXIT

parse_arguments "$@"

log_debug "VERBOSE=$VERBOSE, OUTPUT=$OUTPUT, COMMAND=$COMMAND"

if [[ -z "$COMMAND" ]]; then
  log_error "No command specified"
  show_help >&2
  exit 2
fi

case "$COMMAND" in
  run)
    log_info "Running..."
    log_debug "Verbose mode enabled"
    if [[ -n "$OUTPUT" ]]; then
      log_debug "Output file: $OUTPUT"
    fi
    ;;
  version)
    show_version
    ;;
  *)
    log_error "Unknown command: $COMMAND"
    show_help >&2
    exit 2
    ;;
esac
```
