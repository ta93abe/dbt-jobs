# Auto Release on Merge Design

## Goal

PRがmainにマージされたとき、自動でsemverタグとGitHub Releaseを作成する。

## Approach

単一ワークフロー方式。既存の `release.yml`（タグトリガー）を廃止し、mainプッシュトリガーの新ワークフローに置き換える。

## Trigger

`on: push: branches: [main]` — PRマージおよび直接プッシュで発火。

## Version Determination

1. `git tag -l "v*"` で最新semverタグを取得（なければ `v0.0.0`）
2. `gh pr list --search "<sha>"` でマージされたPRを特定
3. PRラベルでbump種別を判定:
   - `major` → メジャーバンプ
   - `minor` → マイナーバンプ
   - `patch` またはラベルなし → パッチバンプ

## Workflow Steps

1. Checkout
2. YAML lint（品質ゲート）
3. 最新semverタグ取得
4. マージPR特定・ラベル読み取り
5. semverバンプ計算
6. タグ作成・プッシュ
7. GitHub Release作成（`--generate-notes`）
8. メジャータグ更新（`v0` → 同コミットにforce-update）

## Edge Cases

- **ラベルなしPR**: patchとして扱う
- **タグ未存在（初回）**: `v0.0.0` 起点 → `v0.0.1`
- **直接mainプッシュ（PRなし）**: patchバンプ
- **冪等性**: 同タグが既にあればスキップ

## Changes to Existing Files

- **Delete**: `.github/workflows/release.yml`
- **Create**: `.github/workflows/release.yml`（同名で新規作成）
- **No change**: `.github/workflows/ci.yml`
