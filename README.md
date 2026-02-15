# dbt Job

GitHub Actions composite action for running dbt in CI/CD pipelines. Currently supports Snowflake and is structured to add more adapters incrementally.

## Quick Start

```yaml
- uses: ta93abe/dbt-job@v1
  with:
    type: ci
    adapter: snowflake
    command: |
      dbt build --select state:modified+
    deferral: main
    post-pr-comment: true
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `type` | yes | - | Job type: `ci`, `merge`, or `deploy` |
| `adapter` | yes | - | dbt adapter short name (currently `snowflake`) |
| `command` | yes | - | dbt commands to run (multi-line supported) |
| `project-dir` | no | `"."` | Path to the dbt project root |
| `profile-dir` | no | `"."` | Directory containing `profiles.yml` |
| `deferral` | no | `""` | Branch to fetch production manifest from |
| `target` | no | `""` | dbt target to use |
| `run-timeout` | no | `"0"` | Timeout in seconds per command (0 = unlimited) |
| `dbt-version` | no | `""` | dbt-core version (empty or `latest` = auto-resolve) |
| `threads` | no | `""` | Number of dbt threads |
| `source-freshness` | no | `"false"` | Run `dbt source freshness` |
| `post-pr-comment` | no | `"false"` | Post build results as PR comment (ci only) |
| `ci-schema-prefix` | no | `"dbt_pr_job"` | Schema prefix for CI. Sets `SNOWFLAKE_SCHEMA` to `<prefix>_<PR number>` |

## Job Types

### `ci` - Pull Request Checks

Runs commands with `set +e` to capture all failures, optionally posts a PR comment with build results, then propagates the failure.

### `merge` - Post-Merge Build

Runs commands with `set -e` (fail-fast) and uploads `manifest.json` + `run_results.json` as artifacts for Slim CI deferral.

### `deploy` - Production Deploy

Same as `merge`, plus optional source freshness checks.

## Auto-Injected Flags

Each line in the `command` input gets flags injected automatically (if not already present):

- `--profiles-dir` / `--project-dir` -- always
- `--target` / `--threads` -- if configured
- `--defer --state ./prod-manifest` -- if `deferral` is set, manifest was downloaded, and command contains `state:`

## Version Resolution

dbt-core version is resolved in this order:

1. **Explicit input** -- `dbt-version: "1.8.0"`
2. **pyproject.toml** -- PEP 621 `dependencies` or Poetry `[tool.poetry.dependencies]`
3. **requirements.txt** -- `dbt-core>=1.7.0`
4. **setup.cfg** -- `dbt-core>=1.7.0` in `install_requires`
5. **setup.py** -- `dbt-core>=1.7.0` in `install_requires`
6. **Pipfile** -- `dbt-core = "==1.7.0"`
7. **Latest** -- if no version is found

## Adapter Handling

Adapter setup is centralized in `actions/setup/action.yml`.
When adding a new adapter, extend the adapter normalization/validation case and map it to the correct package name.

## Authentication

Set credentials as environment variables at the workflow level. Point `profile-dir` to a `profiles.yml` in your repository that references them via `env_var()`.

```yaml
env:
  SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
  SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_USER }}
  SNOWFLAKE_PRIVATE_KEY: ${{ secrets.SNOWFLAKE_PRIVATE_KEY }}
```

## Examples

See the [`examples/`](./examples) directory for complete workflow configurations:

- [CI (Pull Request)](./examples/ci.yml) -- Slim CI with PR comment
- [Merge](./examples/merge.yml) -- Post-merge build with artifact upload
- [Deploy](./examples/deploy.yml) -- Scheduled production deploy

## License

[MIT](./LICENSE)
