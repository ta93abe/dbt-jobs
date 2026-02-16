# Release Cycle Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Establish CI validation and automated tag-based releases for `ta93abe/dbt-jobs`.

**Architecture:** Two GitHub Actions workflows — `ci.yml` for PR validation (YAML lint) and `release.yml` for tag-triggered releases with automatic major version tag updates. Standard pattern used by most GitHub Actions in the marketplace.

**Tech Stack:** GitHub Actions, `npx yaml-lint`, `gh` CLI

---

### Task 1: Create CI workflow

**Files:**
- Create: `.github/workflows/ci.yml`

**Step 1: Create the `.github/workflows` directory and CI workflow**

```yaml
name: CI

on:
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Lint YAML
        run: npx yaml-lint action.yml actions/*/action.yml examples/*.yml .github/workflows/*.yml
```

**Step 2: Validate the YAML locally**

Run: `npx yaml-lint .github/workflows/ci.yml`
Expected: No errors

**Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add YAML lint workflow for pull requests"
```

---

### Task 2: Create Release workflow

**Files:**
- Create: `.github/workflows/release.yml`

**Step 1: Create the release workflow**

```yaml
name: Release

on:
  push:
    tags:
      - "v*.*.*"

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate semver tag
        id: tag
        run: |
          TAG="${GITHUB_REF_NAME}"
          if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "::error::Tag '$TAG' is not valid semver (expected vX.Y.Z)"
            exit 1
          fi
          echo "major=${TAG%%.*}" >> "$GITHUB_OUTPUT"

      - name: Lint YAML
        run: npx yaml-lint action.yml actions/*/action.yml examples/*.yml .github/workflows/*.yml

      - name: Create GitHub Release
        env:
          GH_TOKEN: ${{ github.token }}
        run: gh release create "$GITHUB_REF_NAME" --generate-notes

      - name: Update major version tag
        run: |
          MAJOR="${{ steps.tag.outputs.major }}"
          git tag -f "$MAJOR"
          git push -f origin "$MAJOR"
```

**Step 2: Validate the YAML locally**

Run: `npx yaml-lint .github/workflows/release.yml`
Expected: No errors

**Step 3: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci: add tag-based release workflow with major tag update"
```

---

### Task 3: Clean up stale tags

**Step 1: Remove stale tags from previous experiments**

Current stale tags: `=`, `list` (non-semver tags that exist from earlier work).

```bash
git push origin --delete "=" "list"
git tag -d "=" "list"
```

**Step 2: Verify remaining tags are clean**

Run: `git tag -l`
Expected: Only `v0`, `v0.1.0` remain

---

### Task 4: Validate full setup

**Step 1: Lint all YAML files (simulating what CI would do)**

Run: `npx yaml-lint action.yml actions/*/action.yml examples/*.yml .github/workflows/*.yml`
Expected: All files pass

**Step 2: Final commit with all workflows**

Push to main. Then test the release flow:

```bash
git tag v0.2.0
git push --tags
```

Expected: GitHub Actions creates a release for `v0.2.0` and updates `v0` tag.
