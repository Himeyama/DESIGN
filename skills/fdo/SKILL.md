---
name: fdo
description: 仕様駆動・テスト駆動・AI駆動を統合し、一貫した開発フローを提供する。
---

# Fusion Development Orchestrator Skill

## Goal

仕様からリリース候補生成までを自動化可能な形で統制する。

## Managed Skills

1. Spec-Driven Development Skill (`Skill(sdd)`)
2. Test-Driven Development Skill (`Skill(tdd)`)
3. AI-Driven Development Skill (`Skill(aidd)`)

## End-to-End Flow

```text
Requirements
   ↓
Spec-Driven Development
   ↓
Test-Driven Development
   ↓
AI-Driven Development
   ↓
Verification
   ↓
Release Candidate
```

## Orchestration Steps

### Step 1: Specification

* `Skill(sdd)` を呼び出して実行する。
* `SPEC.md`生成
* スキーマ検証
* 用語整合性確認

### Step 2: Test Generation

* `Skill(tdd)` を呼び出して実行する。
* 受け入れテスト生成
* 単体テスト生成
* 契約テスト生成

### Step 3: AI Implementation

* `Skill(aidd)` を呼び出して実行する。
* 実装生成
* コード整形
* ドキュメント生成

### Step 4: Verification

* テスト実行
* 静的解析
* セキュリティチェック
* パフォーマンス確認

### Step 5: Human Approval

* 差分レビュー
* 承認記録
* リリース判定

## Quality Gates

| Gate          | Condition |
| ------------- | --------- |
| Spec Gate     | 仕様レビュー済み  |
| Test Gate     | テスト生成済み   |
| Build Gate    | ビルド成功     |
| Quality Gate  | 全テスト成功    |
| Security Gate | 重大脆弱性なし   |
| Review Gate   | 人間承認済み    |

## Failure Handling

* Spec失敗 → Specificationへ戻る
* Test失敗 → Test Generationへ戻る
* Build失敗 → AI Implementationへ戻る
* Verification失敗 → 該当工程へ戻る
* Review却下 → AI Implementationへ戻る

## Required Artifacts

```text
specs/SPEC.md
tests/
src/
docs/
reports/
```

## CI/CD Integration Example

```yaml
stages:
  - spec
  - test
  - build
  - verify
  - review
```

## Audit Requirements

以下を記録すること。

* 仕様バージョン
* テスト結果
* AI生成コミット
* レビュー担当者
* 承認日時

## Completion Criteria

* 全品質ゲート通過
* 監査ログ保存済み
* リリース候補生成済み
* 人間承認済み
