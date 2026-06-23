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
