---
name: powershell-scripting
description: PowerShell 7 (Core) のスクリプト設計原則。安全性・エラー処理・引数解析など。
---

# PowerShell Script Design Guide

堅牢で保守性の高い PowerShell スクリプトの設計原則。PowerShell 7 (Core) 以降を前提とする。

## 基本的な安全性

スクリプトの先頭に以下を配置する：

```powershell
#Requires -Version 7.0

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
```

- `#Requires -Version 7.0`: 必要なバージョンを満たさない場合は実行を拒否
- `Set-StrictMode -Version Latest`: 未定義変数の参照や不正なプロパティアクセスでエラー（`set -u` に相当）
- `$ErrorActionPreference = 'Stop'`: コマンドレットのエラーで即座に終了（`set -e` に相当）
- `$PSNativeCommandUseErrorActionPreference = $true`: 外部コマンド（ネイティブコマンド）の非ゼロ終了も例外として扱う（`set -o pipefail` の思想に相当、PowerShell 7.3+）

## カラー出力の制御

出力がリダイレクトされているか判定して、カラーを条件付きで有効にする：

```powershell
# 標準出力がターミナルか（リダイレクトされていないか）で判定、NO_COLOR も確認
if (-not [Console]::IsOutputRedirected -and -not $env:NO_COLOR) {
    $script:Red     = "`e[0;31m"
    $script:Yellow  = "`e[0;33m"
    $script:Green   = "`e[1;32m"
    $script:Cyan    = "`e[0;36m"
    $script:CyanDim = "`e[36m"
    $script:Gray    = "`e[0;90m"
    $script:Nc      = "`e[0m"
} else {
    $script:Red = $script:Yellow = $script:Green = ''
    $script:Cyan = $script:CyanDim = $script:Gray = $script:Nc = ''
}
```

- `[Console]::IsOutputRedirected`: 標準出力がパイプ/リダイレクトされていると `$true`。`-not` でターミナル判定（`-t 1` に相当）
- `$env:NO_COLOR`: 環境変数で強制的にカラーを無効化
- `` `e `` は PowerShell 7+ の ESC エスケープシーケンス（旧バージョンでは `$([char]27)`）
- パイプ経由の場合は、カラーコードが空文字列に設定される

> **補足**: PowerShell 7.2+ には組み込みの `$PSStyle` があり、`$PSStyle.Foreground.Red` などで色を扱える。`$PSStyle.OutputRendering = 'Host'` にするとリダイレクト時に自動でエスケープを除去する。シンプルな用途ではこちらも検討する。

## バージョン・ヘルプ表示

### バージョン表示

```powershell
function Show-Version {
    Write-Output 'Command 1.0.0'
}
```

### ヘルプ表示

PowerShell ではコメントベースヘルプ（`<# .SYNOPSIS ... #>`）を書くと `Get-Help` で参照できるが、CLI ツールとして整形した独自ヘルプを出す場合は次のようにする：

```powershell
function Show-Help {
    Write-Output 'Command'
    Write-Output ''
    Write-Output "$Green`Usage:$Nc hoge.ps1 [OPTIONS] <COMMAND>`n"
    Write-Output "$Green`Options:$Nc"
    Write-Output "  $Cyan-v$Nc, $Cyan--verbose$Nc                  Enable verbose output"
    Write-Output "  $Cyan-o$Nc, $Cyan--output$Nc $CyanDim`FILE$Nc            Write output to FILE"
    Write-Output "  $Cyan-h$Nc, $Cyan--help$Nc                    Show this help message"
    Write-Output "  $Cyan-V$Nc, $Cyan--version$Nc                 Show version"
    Write-Output ''
    Write-Output "$Green`Commands:$Nc"
    Write-Output "  $Cyan`run$Nc                        Run a command or script"
    Write-Output "  $Cyan`version$Nc                    Read or update the project's version"
}
```

> 文字列補間で変数の直後に英字が続く場合は `` `e ``→`$Green`` のように、変数名の終端を `` ` `` で明示するか `${Green}` の形を使う。

### カラー分類

- **強調緑**: Options:、Commands:、Usage: などのセクション名
- **強調シアン**: オプション名（`-v`, `--verbose`）、サブコマンド
- **通常シアン**: パラメーター値（FILE など）

## エラーハンドリングとログ

### ログ設計

タイムスタンプ、ログレベル、メッセージを統一フォーマットで出力する：

```
yyyy-MM-dd HH:mm:ss [LEVEL] message
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

エラー・警告は標準エラー出力（`[Console]::Error`）、情報・デバッグは標準出力（`[Console]::Out`）へ書き込む：

```powershell
function Write-LogError {
    param([Parameter(Mandatory)][string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    [Console]::Error.WriteLine("$timestamp $Red[ERROR]$Nc $Message")
}

function Write-LogWarn {
    param([Parameter(Mandatory)][string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    [Console]::Error.WriteLine("$timestamp $Yellow[WARN]$Nc  $Message")
}

function Write-LogInfo {
    param([Parameter(Mandatory)][string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    [Console]::Out.WriteLine("$timestamp $Cyan[INFO]$Nc  $Message")
}

function Write-LogDebug {
    param([Parameter(Mandatory)][string]$Message)
    if (-not $script:Verbose) { return }
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    [Console]::Out.WriteLine("$timestamp $Gray[DEBUG]$Nc $Message")
}
```

### 実装のポイント

- **タイムスタンプ**: 無色（`yyyy-MM-dd HH:mm:ss`）
- **ログレベル部分**: `[ERROR]` など括弧内が色付き
- **固定幅**: 最長のログレベル（ERROR）を基準に位置揃え
- **出力先**: エラー・警告は標準エラー出力（`[Console]::Error`）、その他は標準出力（`[Console]::Out`）。`Write-Host` はホストへの書き込みでストリーム制御が効かないため、リダイレクト可能な出力には `[Console]::Out`/`Out` を使う

> **PowerShell ネイティブの代替**: PowerShell には `Write-Error` / `Write-Warning` / `Write-Verbose` / `Write-Debug` / `Write-Information` という専用ストリームが標準で備わっている。`$VerbosePreference` や `-Verbose` 共通パラメーターで出力を制御でき、呼び出し側でストリームごとにリダイレクトできるのが利点。整形済みの一貫した CLI 出力が不要なら、こちらを使うのが PowerShell 流。

### 色付けの制御

#### 自動判定（デフォルト）

- ターミナル出力: 色付けあり
- パイプ/リダイレクト: 色付けなし（`IsOutputRedirected` 判定で自動制御）

#### 強制無効化

`NO_COLOR` 環境変数で色付けを無効化：

```powershell
$env:NO_COLOR = 1; ./script.ps1
```

この場合、ターミナル出力でも色が付きません。

### トラップ処理

PowerShell では `trap` で終端エラーを捕捉し、`try`/`finally` で確実なクリーンアップを行う：

```powershell
# 終端エラーをまとめて捕捉
trap {
    Write-LogError "Script failed: $_"
    exit 1
}

# 後始末を確実に実行
try {
    # メイン処理
} finally {
    # クリーンアップ処理（一時ファイルの削除など）
}
```

- `trap`: バッシュの `trap ... ERR` に近く、終端エラーを一括処理
- `try`/`finally`: バッシュの `trap ... EXIT` に近く、成功・失敗を問わず実行

## 関数設計

### パラメーターと変数のスコープ

PowerShell の関数内変数は既定で関数スコープに閉じる（`local` 宣言は不要）。引数は `param()` で型付きで受け取る：

```powershell
function Invoke-FileProcess {
    param([Parameter(Mandatory)][string]$File)

    $result = Get-SomeData -Path $File
    return $result
}
```

- スクリプト全体で共有する変数は `$script:Verbose` のようにスコープ修飾子を明示する
- 関数の戻り値はパイプラインに出力されたオブジェクト。`return` は早期脱出に使い、`Write-Output` を多用すると意図しない値が混ざるので注意

### 関数の成否を返す

シェルの終了コードと異なり、PowerShell の関数は値を返す。成否は真偽値を返すか、失敗時に `throw` する：

```powershell
function Test-Input {
    param([string]$InputValue)
    return -not [string]::IsNullOrEmpty($InputValue)
}

if (-not (Test-Input -InputValue $Arg)) {
    Write-LogError "Invalid input: $Arg"
    exit 1
}
```

## クォート処理

PowerShell では bash のような単語分割（word splitting）は起こらないが、引用符の使い分けが重要：

```powershell
# 単一引用符: リテラル（変数展開なし）
$path = 'C:\Program Files\app'

# 二重引用符: 変数展開・式の評価あり
Write-LogInfo "Processing $file"

# 変数をそのまま渡す（空白を含むパスも安全）
Remove-Item -Path $file
```

- 変数展開が不要なら単一引用符を使う（誤った展開・エスケープを防ぐ）
- パスを渡すときは `-Path $var` のように名前付きパラメーターで渡し、空白を含む値も安全に扱う
- 外部コマンドへ配列を渡す際はスプラッティング（`@args`）を使う

## 終了コードの規約

- `0`: 成功
- `1`: 一般的なエラー
- `2`: コマンドラインの使用法エラー
- `127`: コマンドが見つからない（シェルの慣例）

```powershell
Show-Help
exit 2
```

- `exit <code>` でスクリプトの終了コードを設定する
- 直前の外部コマンドの終了コードは `$LASTEXITCODE`、直前のコマンドレットの成否は `$?` で確認できる

## 引数解析

PowerShell は組み込みのパラメーターバインディングが強力なため、`param()` ブロックで宣言的に定義するのが基本：

```powershell
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('run', 'version')]
    [string]$Command,

    [Alias('o')]
    [string]$Output,

    [Alias('V')]
    [switch]$Version,

    [Alias('h')]
    [switch]$Help,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)
```

### 設計のポイント

- **宣言的定義**: 型・別名・位置・必須・検証を属性で宣言し、バインディングは PowerShell に任せる
- **`[switch]`**: 値を取らないフラグ（`-Version`, `-Help`）に使う
- **`[Alias('v')]`**: 短形式エイリアスを定義（PowerShell はプレフィックス一致もするため、`-Verb` で `-Verbose` に解決される点に注意）
- **`[ValidateSet(...)]`**: 取り得る値を限定し、不正値を自動的に拒否
- **`[Parameter(Position = 0)]`**: 位置パラメーターでサブコマンドを受け取る
- **`ValueFromRemainingArguments`**: bash の `--` 以降に相当する残りの引数をまとめて取得
- **`-Verbose` 共通パラメーター**: `[CmdletBinding()]` を付けると `-Verbose` が自動で使える。独自の `-v` を作らず、これと `Write-Verbose` を活用する選択肢もある

## テンプレート

```powershell
#Requires -Version 7.0

<#
.SYNOPSIS
    Run a command or script.
.DESCRIPTION
    Example CLI tool template for PowerShell.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Alias('o')]
    [string]$Output = '',

    [Alias('V')]
    [switch]$Version,

    [Alias('h')]
    [switch]$Help,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

# ====================
# Global Variables
# ====================

$script:ScriptName = Split-Path -Leaf $PSCommandPath
$script:ScriptDir  = $PSScriptRoot
$script:Verbose    = $VerbosePreference -ne 'SilentlyContinue'

# ====================
# Color codes
# ====================

if (-not [Console]::IsOutputRedirected -and -not $env:NO_COLOR) {
    $script:Red     = "`e[0;31m"
    $script:Yellow  = "`e[0;33m"
    $script:Green   = "`e[1;32m"
    $script:Cyan    = "`e[0;36m"
    $script:CyanDim = "`e[36m"
    $script:Gray    = "`e[0;90m"
    $script:Nc      = "`e[0m"
} else {
    $script:Red = $script:Yellow = $script:Green = ''
    $script:Cyan = $script:CyanDim = $script:Gray = $script:Nc = ''
}

# ====================
# Functions
# ====================

function Write-LogError {
    param([Parameter(Mandatory)][string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    [Console]::Error.WriteLine("$timestamp $Red[ERROR]$Nc $Message")
}

function Write-LogWarn {
    param([Parameter(Mandatory)][string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    [Console]::Error.WriteLine("$timestamp $Yellow[WARN]$Nc  $Message")
}

function Write-LogInfo {
    param([Parameter(Mandatory)][string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    [Console]::Out.WriteLine("$timestamp $Cyan[INFO]$Nc  $Message")
}

function Write-LogDebug {
    param([Parameter(Mandatory)][string]$Message)
    if (-not $script:Verbose) { return }
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    [Console]::Out.WriteLine("$timestamp $Gray[DEBUG]$Nc $Message")
}

function Show-Help {
    Write-Output 'Command'
    Write-Output ''
    Write-Output "$Green`Usage:$Nc $ScriptName [OPTIONS] <COMMAND>`n"
    Write-Output "$Green`Options:$Nc"
    Write-Output "  $Cyan-v$Nc, $Cyan--verbose$Nc                  Enable verbose output"
    Write-Output "  $Cyan-o$Nc, $Cyan--output$Nc $CyanDim`FILE$Nc            Write output to FILE"
    Write-Output "  $Cyan-h$Nc, $Cyan--help$Nc                    Show this help message"
    Write-Output "  $Cyan-V$Nc, $Cyan--version$Nc                 Show version"
    Write-Output ''
    Write-Output "$Green`Commands:$Nc"
    Write-Output "  $Cyan`run$Nc                        Run a command or script"
    Write-Output "  $Cyan`version$Nc                    Read or update the project's version"
}

function Show-Version {
    Write-Output 'Command 1.0.0'
}

# ====================
# Main
# ====================

trap {
    Write-LogError "Script failed: $_"
    exit 1
}

try {
    if ($Help) {
        Show-Help
        exit 0
    }

    if ($Version) {
        Show-Version
        exit 0
    }

    Write-LogDebug "Verbose=$script:Verbose, Output=$Output, Command=$Command"

    if ([string]::IsNullOrEmpty($Command)) {
        Write-LogError 'No command specified'
        Show-Help
        exit 2
    }

    switch ($Command) {
        'run' {
            Write-LogInfo 'Running...'
            Write-LogDebug 'Verbose mode enabled'
            if (-not [string]::IsNullOrEmpty($Output)) {
                Write-LogDebug "Output file: $Output"
            }
        }
        'version' {
            Show-Version
        }
        default {
            Write-LogError "Unknown command: $Command"
            Show-Help
            exit 2
        }
    }
} finally {
    # クリーンアップ処理（一時ファイルの削除など）
}
```
