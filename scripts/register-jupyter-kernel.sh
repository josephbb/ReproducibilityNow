#!/usr/bin/env bash
# Register a Jupyter kernel for VS Code / Jupyter that uses this project's .venv.
# Run from the project root inside `nix develop` (needs LD_LIBRARY_PATH).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -x .venv/bin/python ]]; then
  echo "No .venv found. Run: uv sync" >&2
  exit 1
fi

if [[ -z "${LD_LIBRARY_PATH:-}" ]]; then
  echo "LD_LIBRARY_PATH is empty. Enter the Nix shell first: nix develop" >&2
  exit 1
fi

chmod +x scripts/jupyter-kernel.sh

# Persist libs for kernels started outside nix develop (e.g. Cursor).
cat > scripts/.jupyter-ld-library-path <<EOF
export LD_LIBRARY_PATH=$(printf '%q' "$LD_LIBRARY_PATH")
EOF

# Point kernel argv at our wrapper (more reliable than baking env into kernel.json).
mkdir -p "$HOME/.local/share/jupyter/kernels/reproducibility-now"
cat > "$HOME/.local/share/jupyter/kernels/reproducibility-now/kernel.json" <<EOF
{
  "argv": [
    "$ROOT/scripts/jupyter-kernel.sh",
    "-f",
    "{connection_file}"
  ],
  "display_name": "Python (ReproducibilityNow)",
  "language": "python",
  "metadata": {
    "debugger": true
  }
}
EOF

echo "Kernel registered: Python (ReproducibilityNow)"
echo "In Cursor: Notebook: Shutdown All Kernels, then pick Python (ReproducibilityNow)"
echo "Or select interpreter: $ROOT/.venv/bin/python"
