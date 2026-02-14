#!/usr/bin/env bash
set -euo pipefail

# resolve-version.sh
# Resolve dbt version from: explicit input > pyproject.toml > requirements.txt > setup.cfg > setup.py > Pipfile > latest
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

# --- requirements.txt ---
REQUIREMENTS="$PROJECT_DIR/requirements.txt"
if [[ -f "$REQUIREMENTS" ]]; then
  version=$(grep -E '^\s*dbt-core\s*[><=!~]' "$REQUIREMENTS" \
    | head -1 \
    | sed -E 's/.*dbt-core\s*[><=!~]+\s*([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/' \
    || true)
  if [[ -n "$version" ]]; then
    echo "$version"
    exit 0
  fi
fi

# --- setup.cfg ---
SETUP_CFG="$PROJECT_DIR/setup.cfg"
if [[ -f "$SETUP_CFG" ]]; then
  version=$(grep -E '^\s*dbt-core\s*[><=!~]' "$SETUP_CFG" \
    | head -1 \
    | sed -E 's/.*dbt-core\s*[><=!~]+\s*([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/' \
    || true)
  if [[ -n "$version" ]]; then
    echo "$version"
    exit 0
  fi
fi

# --- setup.py ---
SETUP_PY="$PROJECT_DIR/setup.py"
if [[ -f "$SETUP_PY" ]]; then
  version=$(grep -E 'dbt-core\s*[><=!~]' "$SETUP_PY" \
    | head -1 \
    | sed -E 's/.*dbt-core\s*[><=!~]+\s*([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/' \
    || true)
  if [[ -n "$version" ]]; then
    echo "$version"
    exit 0
  fi
fi

# --- Pipfile ---
PIPFILE="$PROJECT_DIR/Pipfile"
if [[ -f "$PIPFILE" ]]; then
  version=$(grep -E '^\s*dbt-core\s*=' "$PIPFILE" \
    | head -1 \
    | sed -E 's/.*["'\''"][><=!~^]*([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/' \
    || true)
  if [[ -n "$version" ]]; then
    echo "$version"
    exit 0
  fi
fi

# Fallback: latest
echo ""
exit 0
