---
name: sdd
description: 仕様を唯一の真実（Single Source of Truth）として定義し、実装とテストの基準を作成
---

# Spec-Driven Development Skill

## Goal

要件から曖昧さのない仕様を作成し、後続工程（テスト・実装・レビュー）が参照できる標準成果物を生成する。

> `fdo` スキルの Step 1 (Specification) から `Skill(sdd)` として呼び出される工程。完了後は `tdd` スキルへ引き継ぐ。

## Inputs

* 要件定義
* ユーザーストーリー
* API要求
* 制約条件
* 非機能要件

## Outputs

* `SPEC.md`
* OpenAPI / JSON Schema / Protocol定義
* ドメイン用語集
* エラー一覧
* 非機能要件一覧

## Rules

1. 実装より先に仕様を書く。
2. 曖昧語を禁止する（例: 「適切に」「いい感じに」）。
3. 入力・出力・状態遷移を明示する。
4. 正常系と異常系を必ず定義する。
5. HTTPステータス、エラーコード、メッセージを明記する。
6. 用語は用語集で統一する。

## Workflow

1. 要件分析
2. ドメイン用語抽出
3. API/機能仕様作成
4. エラー仕様作成
5. 非機能要件整理
6. 仕様レビュー（AI自己レビュー）
7. `SPEC.md` 等の成果物ファイルを作成・確定する。

## Quality Checklist

* [ ] 用語が一貫している
* [ ] 入出力が定義されている
* [ ] 異常系が網羅されている
* [ ] 非機能要件が定義されている
* [ ] スキーマ検証が成功している

## Example

```md
# User API Specification

## GET /users/{id}

### Request
Path Parameter: id (integer)

### Success
200 OK

### Error
404 Not Found
```

## Completion Criteria

* 仕様レビュー完了
* スキーマ検証成功
* `SPEC.md` が作成されている
