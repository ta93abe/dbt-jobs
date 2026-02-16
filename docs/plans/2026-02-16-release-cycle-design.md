# Release Cycle Design

## Goal

Establish a release cycle for `ta93abe/dbt-job` with automated CI validation and tag-based releases.

## Workflows

### 1. CI (`ci.yml`)

- **Trigger:** `pull_request` targeting `main`
- **Job:** YAML lint on `action.yml`, `actions/*/action.yml`, `examples/*.yml`
- **Tool:** `npx yaml-lint`

### 2. Release (`release.yml`)

- **Trigger:** `push` tags matching `v*.*.*`
- **Steps:**
  1. Validate tag is semver (`vX.Y.Z`)
  2. Run YAML lint
  3. Create GitHub Release with auto-generated notes
  4. Update major version tag (e.g., `v1.2.3` -> force-update `v1`)

### Major Tag Update Logic

Extract major version from tag, force-push the major tag to the same commit. This allows users to pin `@v1` and always get the latest patch.

## Release Flow

```
developer: git tag v1.2.3 && git push --tags
  -> GitHub Actions: validate semver
  -> GitHub Actions: yaml lint
  -> GitHub Actions: gh release create v1.2.3 --generate-notes
  -> GitHub Actions: git tag -f v1 && git push -f origin v1
```

## Files to Create

- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`
