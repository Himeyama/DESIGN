---
name: tdd
description: 仕様からテストを生成し、品質基準を固定する
---

# Test-Driven Development Skill

## Goal

仕様を実行可能なテストへ変換し、品質ゲートを定義する。

> `fdo` スキルの Step 2 (Test Generation) から `Skill(tdd)` として呼び出される工程。入力は `sdd` の成果物、完了後は `aidd` スキルへ引き継ぐ。

## Inputs

* `SPEC.md`
* APIスキーマ
* 受け入れ条件
* 非機能要件

## Outputs

* 単体テスト
* 結合テスト
* 契約テスト
* E2Eテスト
* テストデータ
* テスト実行レポート

## Core Cycle

1. **Red**: 失敗するテストを書く
2. **Green**: 最小実装で通す
3. **Refactor**: 重複と設計を整理する

## Required Test Categories

* 正常系
* 異常系
* 境界値
* 型不一致
* タイムアウト
* 権限エラー
* 並行実行（必要時）

## Test Design Rules

* 1テスト1責務
* テスト名は期待結果を表現する
* 外部依存はモック化する
* テストは独立して実行可能にする

## Quality Checklist

* [ ] 仕様項目ごとにテストが存在する
* [ ] 異常系テストが存在する
* [ ] テスト名が明確である
* [ ] テストが再現可能である
* [ ] カバレッジ基準を満たしている

## Completion Criteria

* 全テスト成功
* カバレッジ閾値達成
* CI で再現可能
* テストレポート生成済み
