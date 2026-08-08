---
name: gh-issue-auto-resolve
description: 問題調査から Issue 作成・修正・テスト・コミット・Issue コメント・クローズまでを一気通貫で行う。
---

# GitHub Issue Auto-Resolve Skill

## Goal

問題の発生から解決までを、Issue 起票・修正・検証・報告・クローズまで通しで扱う。`gh-issue` スキルの Issue 起票を起点に、修正から後始末までを一つの流れとして完結させる。

## Managed Skills

1. GitHub Issue Skill (`Skill(gh-issue)`) — Issue 起票
2. Git Commit Skill (`Skill(git-commit)`) — コミット作成・push

## Inputs

* 問題の報告内容（エラーメッセージ、不具合の症状、要望など）
* 対象リポジトリ（未指定時は現在の作業ディレクトリのリポジトリ）

## End-to-End Flow

```text
Investigation
   ↓
Issue 起票 (gh-issue)
   ↓
Fix
   ↓
Test
   ↓
独立レビュー
   ↓
Commit & Push (git-commit)
   ↓
Issue Comment & Close
```

## Workflow

### Step 1: Issue 起票

* `Skill(gh-issue)` を呼び出し、問題を調査して Issue を起票する。重複確認は `gh-issue` の手順に従う。
* 起票された Issue 番号・URL を後続工程で使うため保持する。

### Step 2: Fix

* Issue に記載した原因・再現手順に基づき、該当コードを修正する。
* 修正範囲は Issue の内容に対応する分だけに留め、無関係な変更を混ぜない。

### Step 3: Test

* 既存のテストを実行し、回帰がないことを確認する。
* 再現手順に対応するテストが存在しない場合は追加する（`tdd` スキルの Test Design Rules に準拠）。
* テストが失敗する場合は Fix に戻る。

### Step 4: 独立レビュー

* Fix を行った文脈を引き継がない別のエージェント（`Agent` ツールで新規起動、または `code-review` スキル）に差分をレビューさせる。修正担当が自分の成果物を採点しない。
* レビューで問題が見つかった場合は Step 2 (Fix) へ戻る。

### Step 5: Commit & Push

* `Skill(git-commit)` を呼び出してコミットを作成し、リモートへ push する。
* コミットメッセージには対応する Issue 番号を含める（例: `#<issue番号> の不具合を修正` のように、末尾ではなく本文で言及する）。
* `Fixes #<issue番号>` のような GitHub の自動クローズ構文は使わない。クローズは Step 6 で明示的に行う。

### Step 6: Issue Comment & Close

* 修正内容・対応コミット・テスト結果・独立レビュー結果をまとめる。
* `gh issue comment <issue番号>` で対応内容を報告する。
* 続けて `gh issue close <issue番号>` で Issue をクローズする。

## Rules

1. Fix は Issue に記載された原因・範囲を超えない。
2. テストが通らない状態でコミットしない。
3. 独立レビューで問題が見つかった状態でコミットしない。
4. コミットメッセージや Issue コメントに秘密情報を含めない。
5. `git push --force` は行わない。

## Failure Handling

* Fix後にテスト失敗 → Fix へ戻る
* 独立レビューで問題を指摘された → Fix へ戻る
* コミット時の pre-commit フック失敗 → 原因を修正し Fix またはコミットをやり直す（`--no-verify` は使わない）
* Issue 起票時に重複 Issue が見つかった → 新規起票せず、既存 Issue に対して Step 2 以降を行う

## Quality Checklist

* [ ] Issue に再現手順・原因・影響範囲が記載されている
* [ ] 修正が Issue の範囲に対応している
* [ ] テストが全て成功している
* [ ] 独立レビューを通過している
* [ ] コミットメッセージが Issue 番号を参照している

## Completion Criteria

* Issue が作成されている
* 修正がコミットされ、リモートに push されている
* テストが成功している
* Issue に対応報告がコメントされ、クローズされている
