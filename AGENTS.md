# Repository Guidelines

## Project Structure & Module Organization
- Root composite action: `action.yml` (main entrypoint for CI/merge/deploy dbt jobs).
- Setup pipeline is modular:
  - `actions/setup/action.yml`: adapter normalization, install, and profile setup.
- Command execution helper: `actions/run/action.yml`.
- Utility scripts: `scripts/` (for example `scripts/resolve-version.sh`).
- Usage examples: `examples/ci.yml`, `examples/merge.yml`, `examples/deploy.yml`.

## Build, Test, and Development Commands
- Validate YAML syntax:
  ```bash
  ruby -e "require 'yaml'; Dir.glob('{action.yml,actions/*/action.yml,examples/*.yml}').each{|f| YAML.load_file(f)}; puts 'yaml-ok'"
  ```
- Lint shell scripts:
  ```bash
  shellcheck -S warning scripts/resolve-version.sh
  ```
- Inspect local changes:
  ```bash
  git status --short
  git diff
  ```
- Note: `actionlint` expects `.github/workflows`; this repo primarily ships reusable actions and examples.

## Coding Style & Naming Conventions
- YAML: 2-space indentation, descriptive step names, clear `inputs` descriptions.
- Shell: `set -euo pipefail` for scripts, quote variables, avoid `eval`/`bash -c`.
- Prefer environment variables (`env:`) over direct expression interpolation in `run` blocks.
- Keep adapter mapping centralized in `actions/setup/action.yml` unless adapter-specific logic becomes materially different.

## Testing Guidelines
- No dedicated test framework exists yet.
- Minimum checks before PR:
  - YAML parse check (command above).
  - `shellcheck` on changed shell scripts.
  - Dry review of `examples/*.yml` for input compatibility when changing interfaces.

## Commit & Pull Request Guidelines
- Follow Conventional Commits as used in history:
  - `feat: ...`, `fix: ...`, `chore: ...`, `rename: ...`.
- Keep commits scoped (one logical change per commit when possible).
- PRs should include:
  - What changed and why.
  - Impacted files/inputs (for example `action.yml`, `actions/setup/*`).
  - Migration notes for breaking input changes.
  - Example workflow snippet when behavior changes.

## Security & Configuration Tips
- Treat all action inputs as untrusted.
- Restrict command execution to dbt commands and validate user-controlled values.
- Use least-privilege `permissions:` in consuming workflows.
