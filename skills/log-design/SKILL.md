---
name: log-design
description: タイムスタンプ・ログレベル・色付きメッセージを統一フォーマットで出力する設計。
---

# ログ設計

## 概要

Messages のようなログ出力を実現するための設計。タイムスタンプ、ログレベル、メッセージを統一フォーマットで出力する。

## ログフォーマット

```
YYYY-MM-DD HH:mm:ss [LEVEL] message
```

### 要素

- **YYYY-MM-DD HH:mm:ss**: ISO 8601形式のタイムスタンプ
- **[LEVEL]**: ログレベル（色付き、5文字で固定幅）
- **message**: ログメッセージ本体（位置揃え）

### 例

```
1999-01-01 20:08:30 [INFO]  Application started
1999-01-01 20:08:31 [WARN]  Configuration validation failed
1999-01-01 20:08:32 [ERROR] Database connection timeout
1999-01-01 20:08:33 [DEBUG] Processing request id=12345
```

### ログレベルの色

- **ERROR**: 赤 (`\x1b[31m`)
- **WARN**: 黄 (`\x1b[33m`)
- **INFO**: シアン (`\x1b[36m`)
- **DEBUG**: グレー (`\x1b[90m`)

## ログレベル

| レベル | 用途 |
|--------|------|
| ERROR  | エラー、致命的な問題 |
| WARN   | 警告、注意が必要な状態 |
| INFO   | 情報、重要なイベント |
| DEBUG  | デバッグ情報、詳細トレース |

## 出力例

実際の出力は以下のようになります（ログレベルが色付きで表示される）：

```
1999-01-01 20:08:30 [INFO]  Application started
1999-01-01 20:08:31 [WARN]  Configuration validation failed
1999-01-01 20:08:32 [ERROR] Database connection timeout
1999-01-01 20:08:33 [DEBUG] Processing request id=12345
```

### 色付け

- `[INFO]` → シアン色
- `[WARN]` → 黄色
- `[ERROR]` → 赤色
- `[DEBUG]` → グレー色

### ポイント

- `]` の後に調整スペースを挿入
- 最長のログレベル（ERROR）を基準に位置揃え
- すべてのメッセージの開始位置が揃う
- ログレベルの部分（括弧内）が色で区別される

## 環境別の動作

### ターミナル出力

ターミナル直接出力時は色が付く：

```
1999-01-01 20:08:30 [INFO]  Application started     # シアン色
1999-01-01 20:08:31 [WARN]  Configuration failed    # 黄色
1999-01-01 20:08:32 [ERROR] Database timeout        # 赤色
```

### パイプ / リダイレクト

パイプやリダイレクトで処理する場合は色コードが自動的に無効化される：

```bash
$ node app.js | grep ERROR
1999-01-01 20:08:32 [ERROR] Database timeout
```

## 色付けの制御

### 自動判定（デフォルト）

- `process.stdout.isTTY === true` → 色付け有効
- パイプ / リダイレクト → 色付け無効

### 強制無効化

`NO_COLOR` 環境変数を設定：

```bash
$ NO_COLOR=1 node app.js
```

この場合、ターミナル出力でも色が付きません。
