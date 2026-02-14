# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GitHub Actions composite action (`ta93abe/dbt-job@v1`) for running dbt in CI/CD pipelines. Supports any dbt adapter. The repository is being renamed from `dbt-actions` to `dbt-job`.

## Validation

```bash
npx yaml-lint action.yml examples/*.yml
```

No test suite exists. Validation is YAML lint + manual verification that example `with:` keys match `action.yml` inputs.

## Architecture

### Entry Point: `action.yml` (root composite action)

Called as a step via `uses: ta93abe/dbt-job@v1`. Three modes controlled by `type` input:

- **ci**: Runs commands with `set +e` (captures failures), posts PR comment, then propagates failure
- **merge**: Runs commands with `set -e` (fail-fast), uploads artifacts
- **deploy**: Same as merge, plus optional source freshness checks

10-step pipeline: validate type -> override schema (ci) -> setup dbt -> deps -> download manifest -> extract manifest -> execute commands -> source freshness -> upload artifacts -> PR comment -> check build result

### Internal Actions (under `actions/`)

- **`actions/setup`**: Installs Python + dbt-core + adapter via pip. Resolves dbt version from explicit input > `pyproject.toml` > `requirements.txt` > `setup.cfg` > `setup.py` > `Pipfile` > latest (via `scripts/resolve-version.sh`). Referenced from root action as `uses: ./actions/setup`.
- **`actions/run`**: Single dbt command executor with `--profiles-dir` and `--target` injection. Not used by root action (root action handles multi-line commands and richer injection itself).

### Command Auto-Injection (Step 6)

Each line in the multi-line `command` input gets flags injected automatically:
- `--profiles-dir` / `--project-dir` — always (if not already present)
- `--target` / `--threads` — if configured and not already present
- `--defer --state ./prod-manifest` — if deferral is set, manifest was downloaded, and command contains `state:`

### Key Design Decisions

- **Composite action, not reusable workflow** — enables step-level `uses:`, no `secrets:` parameter (users set env vars at workflow level instead, with `profile-dir` pointing to in-repo `profiles.yml`)
- **Adapter input is short name** (e.g. `snowflake`) — `dbt-` prefix added automatically
- **`dbt-version: "latest"` maps to empty string** — triggers auto-resolve logic
- **Artifact name hardcoded to `dbt-artifacts`** — manifest.json + run_results.json, 90-day retention

### Examples (`examples/`)

Working workflow samples for ci/merge/deploy. Each uses `ta93abe/dbt-job@v1` with Snowflake adapter. Environment secrets are set at the workflow `env:` level (not via `secrets:` block).
