# DESIGN

コーディング規約とデザインスタイルガイドをまとめたリポジトリです。
個人プロジェクトで一貫した書き方・見た目を保つための「単一の情報源」として使い、
AI コーディングエージェントが参照することを想定しています。

各ガイドは AI が解釈しやすいよう、簡潔な指示と最小限のコード例で構成しています。

## 構成

```
.
├── AGENTS.md          AI エージェント向けの共通指示
├── programming/       言語別コーディング規約
│   ├── csharp.md      C# (.NET 8+ / C# 12+)
│   └── python.md      Python (3.13+)
├── styles/            デザインスタイルガイド
│   └── WEB_STYLE.md   ウェブサイトのデザイン方針
└── sample_profile.html  WEB_STYLE.md を適用したサンプル
```

## ガイド一覧

### programming/csharp.md
.NET 8+ / C# 12+ を対象とした C# の規約。
`var` を使わず明示的な型を書く方針のほか、nullable 参照型・コレクション式・
パターンマッチング・primary constructor・record・LINQ・async・最小 API・命名規則などを扱います。

### programming/python.md
Python 3.13+ を対象とした規約。
`uv` によるプロジェクト管理を前提に、型ヒント・dataclass・パターンマッチング・
async (TaskGroup)・エラーハンドリング・pathlib・Ruff・pytest・命名規則などを扱います。

### styles/WEB_STYLE.md
ウェブサイトのデザイン方針。レイアウト (余白・角丸・影)、フォント
(本文は明朝、強調はゴシック、英数字はセリフ)、配色などを定めます。
[sample_profile.html](sample_profile.html) はこの方針を適用した実例です。

## 使い方

新しくコードやウェブページを書くときに、対象に応じたガイドを参照してください。
AI エージェントに作業を依頼する場合は、該当するガイドを読み込ませることで、
このリポジトリの規約に沿った出力が得られます。
