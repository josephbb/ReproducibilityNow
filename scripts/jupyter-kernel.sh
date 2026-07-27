#!/usr/bin/env bash
# Jupyter kernel entrypoint: ensure Nix runtime libs are available, then start ipykernel.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_PY="$ROOT/.venv/bin/python"

if [[ ! -x "$VENV_PY" ]]; then
  echo "Missing $VENV_PY — run: uv sync" >&2
  exit 1
fi

# Prefer libs captured during registration (from nix develop); fall back to existing env.
ENV_FILE="$ROOT/scripts/.jupyter-ld-library-path"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

exec "$VENV_PY" -Xfrozen_modules=off -m ipykernel_launcher "$@"
