# DESIGN

個人的な経験に基づくソフトウェア開発スキルを集めたリポジトリです。
AI コーディングエージェントが参照することを想定しています。

各スキルは AI が解釈しやすいよう、簡潔な指示と最小限のコード例で構成しています。

## スキル一覧

```
skills/
├── csharp-coding/          C# (.NET 8+ / C# 12+) コーディング規約
├── python-coding/          Python (3.13+) コーディング規約
├── javascript-coding/      JavaScript (Node.js) 設計ガイド
├── typescript-coding/      TypeScript コーディング規約
├── powershell-scripting/   PowerShell スクリプト設計ガイド
├── shell-scripting/        シェルスクリプト設計ガイド
├── terminal-ui/            ターミナル UI 実装ガイド（JavaScript）
├── web-style/              ウェブサイトデザインスタイル
├── fluent-icon/            Fluent Design アイコン作成
├── log-design/             ログ設計
├── winui3-app/             WinUI3 デスクトップアプリ作成
└── cloudformation-template/ AWS CloudFormation テンプレート設計
```

各スキルフォルダの構成：
- `skill.md` — スキルの内容（規約・手順・設計方針）
- `examples/` — コード例・サンプルファイル

## 使い方

新しくコードやウェブページを書くときに、対象に応じたスキルの `skill.md` を参照してください。
AI エージェントに作業を依頼する場合は、該当するスキルを読み込ませることで、
このリポジトリの規約に沿った出力が得られます。

## インストール

以下のコマンドで、登録したいスキルを対話的に選択して Claude Code のスキルディレクトリ
（`~/.claude/skills` または `./.claude/skills`）にインストールできます（PowerShell 7 が必要です）。

```powershell
pwsh -c "irm https://raw.githubusercontent.com/Himeyama/DESIGN/main/scripts/install.ps1 | iex"
```

PowerShell 7 が無い場合は `winget install Microsoft.PowerShell`（Windows）や
`brew install --cask powershell`（macOS）などでインストールしてください。

> [!NOTE]
> `curl ... | pwsh -c -` のように標準入力経由でスクリプトを渡す方法は、対話的な選択 UI が
> 標準入力を使えなくなるため動作しません。上記の `irm | iex` 形式を使ってください。

スキル名や配置先をあらかじめ指定して非対話で実行することもできます（CI などでも利用可能）。

```powershell
pwsh ./scripts/install.ps1 -Scope Project -Skills csharp-coding,shell-scripting -Force
```

macOS / Linux の場合は bash 版のインストーラーも利用できます（`jq` が必要です）。

```bash
curl -fsSL https://raw.githubusercontent.com/Himeyama/DESIGN/main/scripts/install.sh -o install.sh
bash ./install.sh
```

`jq` が無い場合は `brew install jq`（macOS）や `apt install jq`（Debian/Ubuntu）などでインストールしてください。

> [!NOTE]
> PowerShell 版と同様に、標準入力経由でスクリプト全体を渡す方法（`curl ... | bash`）は
> 対話的な選択 UI が使えないため動作しません。上記のように一度ファイルに保存してから実行してください。

スキル名や配置先をあらかじめ指定して非対話で実行することもできます（CI などでも利用可能）。

```bash
bash ./scripts/install.sh --scope project --skills csharp-coding,shell-scripting --force
```
