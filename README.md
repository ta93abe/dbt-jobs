# dbt-runner

GitHub Actions package for running dbt in CI/CD pipelines. Provides composite actions and reusable workflows for any dbt adapter.

## Quick Start

Add dbt CI to your repository in 3 lines:

```yaml
jobs:
  dbt:
    uses: ta93abe/dbt-runner/.github/workflows/dbt-ci.yml@v1
    with:
      dbt-adapter: dbt-bigquery
    secrets:
      profiles-yml: ${{ secrets.DBT_PROFILES_YML }}
```

## Actions

### `actions/setup`

Sets up Python, dbt-core, and a dbt adapter.

```yaml
- uses: ta93abe/dbt-runner/actions/setup@v1
  with:
    dbt-adapter: dbt-bigquery
    dbt-version: "1.8.0"        # optional: resolved from pyproject.toml or latest
    python-version: "3.11"       # optional
    profiles-yml: |              # optional
      my_project:
        target: dev
        outputs:
          dev:
            type: bigquery
            method: service-account
            project: my-project
            dataset: dbt_dev
    project-dir: "."             # optional
```

| Input | Required | Default | Description |
|---|---|---|---|
| `dbt-adapter` | yes | - | Adapter pip package name (e.g. `dbt-bigquery`, `dbt-snowflake`) |
| `dbt-version` | no | `""` | Explicit dbt-core version. Empty = resolve from pyproject.toml or latest |
| `python-version` | no | `"3.11"` | Python version |
| `profiles-yml` | no | `""` | Contents of `profiles.yml` to write |
| `profiles-dir` | no | `"~/.dbt"` | Directory to write `profiles.yml` into |
| `project-dir` | no | `"."` | dbt project root |

**Outputs:**

| Output | Description |
|---|---|
| `dbt-version` | Installed dbt-core version |

### `actions/run`

Executes a dbt command with automatic `--profiles-dir` and `--target` injection.

```yaml
- uses: ta93abe/dbt-runner/actions/run@v1
  with:
    command: dbt build --select tag:critical
    target: ci              # optional
```

| Input | Required | Default | Description |
|---|---|---|---|
| `command` | yes | - | dbt command to execute |
| `project-dir` | no | `"."` | dbt project root |
| `profiles-dir` | no | `"~/.dbt"` | Directory containing `profiles.yml` |
| `target` | no | `""` | dbt target |

**Outputs:**

| Output | Description |
|---|---|
| `result` | `success` or `failure` |
| `log` | Path to `dbt.log` |
| `run-results` | Path to `run_results.json` |
| `manifest` | Path to `manifest.json` |

## Reusable Workflows

### `dbt-ci.yml` - Full CI Pipeline

Checkout -> Setup -> deps -> build -> (docs) -> artifact upload.

```yaml
jobs:
  dbt:
    uses: ta93abe/dbt-runner/.github/workflows/dbt-ci.yml@v1
    with:
      dbt-adapter: dbt-bigquery
      upload-artifacts: true    # save manifest for Slim CI
      generate-docs: false      # optional: run dbt docs generate
    secrets:
      profiles-yml: ${{ secrets.DBT_PROFILES_YML }}
```

| Input | Required | Default | Description |
|---|---|---|---|
| `dbt-adapter` | yes | - | Adapter package name |
| `dbt-version` | no | `""` | dbt-core version |
| `python-version` | no | `"3.11"` | Python version |
| `project-dir` | no | `"."` | Project root |
| `target` | no | `""` | dbt target |
| `upload-artifacts` | no | `false` | Upload manifest.json and run_results.json |
| `generate-docs` | no | `false` | Run `dbt docs generate` |

### `dbt-slim-ci.yml` - Slim CI (Modified Only)

Runs `dbt build --select state:modified+` using production manifest. Falls back to full build if manifest is not available. Optionally posts results as a PR comment.

```yaml
jobs:
  dbt:
    uses: ta93abe/dbt-runner/.github/workflows/dbt-slim-ci.yml@v1
    with:
      dbt-adapter: dbt-bigquery
      post-pr-comment: true
    secrets:
      profiles-yml: ${{ secrets.DBT_PROFILES_YML }}
```

| Input | Required | Default | Description |
|---|---|---|---|
| `dbt-adapter` | yes | - | Adapter package name |
| `dbt-version` | no | `""` | dbt-core version |
| `python-version` | no | `"3.11"` | Python version |
| `project-dir` | no | `"."` | Project root |
| `target` | no | `""` | dbt target |
| `prod-artifact-name` | no | `"dbt-artifacts"` | Artifact name for production manifest |
| `prod-branch` | no | `"main"` | Branch producing production artifacts |
| `post-pr-comment` | no | `true` | Post build results as PR comment |

**Slim CI Setup:**

1. Enable `upload-artifacts: true` in your `dbt-ci.yml` workflow on the main branch
2. Use `dbt-slim-ci.yml` for pull request workflows
3. The first PR run will fall back to full build until artifacts are available

### `dbt-docs.yml` - Documentation

Generates dbt docs and optionally deploys to GitHub Pages.

```yaml
jobs:
  docs:
    uses: ta93abe/dbt-runner/.github/workflows/dbt-docs.yml@v1
    with:
      dbt-adapter: dbt-bigquery
      deploy-to-gh-pages: true
    secrets:
      profiles-yml: ${{ secrets.DBT_PROFILES_YML }}
```

| Input | Required | Default | Description |
|---|---|---|---|
| `dbt-adapter` | yes | - | Adapter package name |
| `deploy-to-gh-pages` | no | `false` | Deploy to GitHub Pages |
| `gh-pages-branch` | no | `"gh-pages"` | Pages branch name |

## Authentication

Store your `profiles.yml` as a GitHub Actions secret (`DBT_PROFILES_YML`). The secret value should be the full YAML content of your profiles file.

**Example for BigQuery (service account):**

```yaml
my_project:
  target: ci
  outputs:
    ci:
      type: bigquery
      method: service-account
      project: my-gcp-project
      dataset: dbt_ci
      keyfile_json: "{{ env_var('BIGQUERY_KEYFILE_JSON') }}"
```

You can use `env_var()` in profiles.yml to reference additional secrets set as environment variables.

## Version Resolution

dbt-core version is resolved in this order:

1. **Explicit input** - `dbt-version: "1.8.0"` in workflow inputs
2. **pyproject.toml** - Parsed from `[project] dependencies` (PEP 621) or `[tool.poetry.dependencies]` (Poetry)
3. **Latest** - If no version is specified, the latest release is installed

## Examples

See the [`examples/`](./examples) directory for complete workflow configurations:

- [BigQuery CI](./examples/bigquery-ci.yml)
- [Snowflake CI](./examples/snowflake-ci.yml)
- [Postgres CI](./examples/postgres-ci.yml) (with service container)
- [Slim CI for PRs](./examples/slim-ci-pr.yml)

## Design Decisions

- **Adapter name = pip package name** - Specify `dbt-bigquery` directly. No mapping table needed, works with any third-party adapter.
- **Single `profiles-yml` secret** - Avoids adapter-specific inputs. Future-proof against new adapters.
- **Separate setup and run actions** - Use setup alone for custom scripts, or compose multiple run steps.
- **pip-based (no Docker)** - Fast, lightweight, easy to customize.

## License

[Apache-2.0](./LICENSE)
