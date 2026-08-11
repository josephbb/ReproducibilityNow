#!/usr/bin/env bash
# Launch system RStudio pointed at Nix R. Run from inside `nix develop`.
set -euo pipefail

if [[ -z "${IN_NIX_SHELL:-}" ]]; then
  echo "Run this from inside \`nix develop\` (or: nix develop -c just rstudio)" >&2
  exit 1
fi

R_BIN="$(command -v R)"
case "$R_BIN" in
  /nix/store/*) ;;
  *)
    echo "R is not the Nix binary (got: $R_BIN). Enter a fresh \`nix develop\` first." >&2
    exit 1
    ;;
esac

export RSTUDIO_WHICH_R="$R_BIN"
export cmdstanr_no_ver_check="${cmdstanr_no_ver_check:-TRUE}"

# Prefer writable ~/.cmdstan over Nix store (read-only → PCH rebuild fails).
if [[ -d "${HOME}/.cmdstan" ]]; then
  _user_cmdstan="$(ls -d "${HOME}/.cmdstan"/cmdstan-* 2>/dev/null | sort -V | tail -1 || true)"
  if [[ -n "${_user_cmdstan}" && -x "${_user_cmdstan}/bin/stanc" ]]; then
    export CMDSTAN="${_user_cmdstan}"
  fi
  unset _user_cmdstan
fi
export CMDSTAN="${CMDSTAN:-}"

echo "RSTUDIO_WHICH_R=$RSTUDIO_WHICH_R"
echo "CMDSTAN=${CMDSTAN:-<unset>}"

if [[ "$(uname -s)" == "Darwin" ]]; then
  open -a RStudio "$@"
elif command -v rstudio >/dev/null 2>&1 && [[ "$(command -v rstudio)" == /nix/store/* ]]; then
  # flake-provided Linux wrapper
  exec rstudio "$@"
elif [[ -x /usr/bin/rstudio ]]; then
  exec /usr/bin/rstudio "$@"
else
  echo "Could not find system RStudio." >&2
  exit 1
fi
