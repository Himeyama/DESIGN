---
name: aidd
description: AI を用いた設計・実装・レビューを安全かつ効率的に実行する。
---

# AI-Driven Development Skill

## Goal

AIを活用して開発速度を向上させつつ、品質と安全性を維持する。

> `fdo` スキルの Step 3 (AI Implementation) から `Skill(aidd)` として呼び出される工程。入力は `sdd`/`tdd` の成果物、完了後は Verification / Human Approval 工程へ進む。

## Inputs

* `SPEC.md`
* テストコード
* コーディング規約
* アーキテクチャ方針
* セキュリティポリシー

## Outputs

* 実装コード
* リファクタリング提案
* ドキュメント
* AIレビュー結果
* 改善提案一覧

## Allowed Usage

* ボイラープレート生成
* テストケース生成
* ドキュメント生成
* リファクタリング提案
* 静的解析補助

## Prohibited Usage

* 秘密情報の入力
* 未レビューコードの本番投入
* 仕様変更の自動確定
* セキュリティ設定変更の自動適用

## Review Checklist

* [ ] 仕様と一致している
* [ ] テストが通過している
* [ ] セキュリティ問題がない
* [ ] パフォーマンス上の懸念がない
* [ ] 可読性が確保されている
* [ ] 不要な依存が追加されていない

## AI Output Template

```md
## AI Review

- Spec Compliance: PASS
- Tests: PASS
- Security: PASS
- Performance: WARN
- Readability: PASS
```

## Human-in-the-Loop Policy

AI 生成物は必ず人間がレビューし、承認後にマージする。

## Completion Criteria

* 人間レビュー承認済み
* テスト成功
* 静的解析成功
* セキュリティチェック成功
