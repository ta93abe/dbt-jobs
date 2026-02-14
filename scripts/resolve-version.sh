#!/usr/bin/env bash
set -euo pipefail

# resolve-version.sh
# Resolve dbt version from: explicit input > pyproject.toml > latest
#
# Usage: ./resolve-version.sh [explicit-version] [project-dir]

EXPLICIT_VERSION="${1:-}"
PROJECT_DIR="${2:-.}"

if [[ -n "$EXPLICIT_VERSION" ]]; then
  echo "$EXPLICIT_VERSION"
  exit 0
fi

PYPROJECT="$PROJECT_DIR/pyproject.toml"

if [[ -f "$PYPROJECT" ]]; then
  # Try PEP 621 format: [project] dependencies = ["dbt-core>=1.7,<1.9"]
  version=$(grep -E '^\s*"dbt-core[><=!~]' "$PYPROJECT" \
    | head -1 \
    | sed -E 's/.*dbt-core[><=!~]+([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/' \
    || true)

  if [[ -z "$version" ]]; then
    # Try Poetry format: dbt-core = "^1.7" or dbt-core = {version = "^1.7"}
    version=$(grep -E '^\s*dbt-core\s*=' "$PYPROJECT" \
      | head -1 \
      | sed -E 's/.*["'\''][\^~>=<]*([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/' \
      || true)
  fi

  if [[ -n "$version" ]]; then
    echo "$version"
    exit 0
  fi
fi

# Fallback: latest
echo ""
exit 0
