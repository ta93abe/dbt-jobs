# Auto Release on Merge Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** PRがmainにマージされたとき、PRラベルに応じて自動でsemverタグとGitHub Releaseを作成する。

**Architecture:** 既存の `release.yml`（タグトリガー）を廃止し、mainプッシュトリガーの新ワークフローに置き換える。PRラベル（`patch`/`minor`/`major`）でバージョンバンプ種別を制御。PRスキルにラベル付けステップを追加。

**Tech Stack:** GitHub Actions, `gh` CLI, bash

---

### Task 1: Create release labels on GitHub

**Step 1: Create the three release labels**

Run:
```bash
gh label create patch --color "0E8A16" --description "Patch version bump (bug fixes)" --force
gh label create minor --color "1D76DB" --description "Minor version bump (new features)" --force
gh label create major --color "D93F0B" --description "Major version bump (breaking changes)" --force
```

Expected: Three labels created (or updated if they exist)

---

### Task 2: Replace release.yml with auto-release workflow

**Files:**
- Replace: `.github/workflows/release.yml`

**Step 1: Write the new workflow**

Replace `.github/workflows/release.yml` with:

```yaml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
          fetch-tags: true

      - name: Lint YAML
        run: npx yaml-lint@1.7.0 action.yml actions/*/action.yml examples/*.yml .github/workflows/*.yml

      - name: Get latest semver tag
        id: latest
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          TAG=$(gh api repos/${{ github.repository }}/releases/latest --jq '.tag_name' 2>/dev/null || echo "")
          if [ -z "$TAG" ]; then
            TAG=$(git tag -l "v[0-9]*.[0-9]*.[0-9]*" --sort=-v:refname | head -n1)
          fi
          echo "tag=${TAG:-v0.0.0}" >> "$GITHUB_OUTPUT"

      - name: Determine bump type from PR labels
        id: bump
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          SHA="${{ github.sha }}"
          LABELS=$(gh pr list --search "$SHA" --state merged --json labels --jq '.[0].labels[].name' 2>/dev/null || echo "")
          if echo "$LABELS" | grep -q "^major$"; then
            echo "type=major" >> "$GITHUB_OUTPUT"
          elif echo "$LABELS" | grep -q "^minor$"; then
            echo "type=minor" >> "$GITHUB_OUTPUT"
          else
            echo "type=patch" >> "$GITHUB_OUTPUT"
          fi

      - name: Calculate next version
        id: next
        env:
          CURRENT: ${{ steps.latest.outputs.tag }}
          BUMP: ${{ steps.bump.outputs.type }}
        run: |
          VERSION="${CURRENT#v}"
          IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
          case "$BUMP" in
            major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
            minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
            patch) PATCH=$((PATCH + 1)) ;;
          esac
          echo "tag=v${MAJOR}.${MINOR}.${PATCH}" >> "$GITHUB_OUTPUT"
          echo "major=v${MAJOR}" >> "$GITHUB_OUTPUT"

      - name: Create tag and GitHub Release
        env:
          GH_TOKEN: ${{ github.token }}
          NEXT_TAG: ${{ steps.next.outputs.tag }}
        run: |
          if gh release view "$NEXT_TAG" >/dev/null 2>&1; then
            echo "Release $NEXT_TAG already exists. Skipping."
          else
            gh release create "$NEXT_TAG" --generate-notes
          fi

      - name: Update major version tag
        env:
          MAJOR: ${{ steps.next.outputs.major }}
        run: |
          git tag -f "$MAJOR"
          git push -f origin "$MAJOR"
```

**Step 2: Validate YAML locally**

Run: `npx yaml-lint@1.7.0 .github/workflows/release.yml`
Expected: No errors

**Step 3: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci: replace tag-triggered release with auto-release on merge"
```

---

### Task 3: Update PR skill to add release labels

**Files:**
- Modify: `~/.claude/skills/pr/skill.md`

**Step 1: Update the `/pr create` section**

Add step 5 (label selection) and step 6 (label application) to the `/pr create` flow:

```markdown
### /pr create (デフォルト)

PRを作成する。

**動作:**
1. `git status` で現在のブランチと変更を確認
2. `git log main..HEAD` でコミット履歴を確認
3. `git diff main...HEAD` で全体の変更を確認
4. 変更内容を分析してPRの説明文を生成
5. `gh pr create` でPRを作成
6. 変更の種類を確認し、リリースラベル（`patch`/`minor`/`major`）を付与

**リリースラベル判断基準:**
- `patch`: バグ修正、ドキュメント更新、リファクタリング
- `minor`: 新機能追加、既存機能の拡張
- `major`: 破壊的変更（後方互換性のない変更）
```

**Step 2: Commit (if in a repo that tracks skills)**

This file is outside the repository, so no git commit needed.

---

### Task 4: Validate full setup

**Step 1: Lint all YAML**

Run: `npx yaml-lint@1.7.0 action.yml actions/*/action.yml examples/*.yml .github/workflows/*.yml`
Expected: All files pass

**Step 2: Push and create PR**

```bash
git push -u origin feat/auto-release
gh pr create --title "ci: auto-release on merge with PR label versioning" --label patch
```

---
