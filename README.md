# ReproducibilityNow

A small template for analyses that other people (and future-you) can actually re-run.

It wires together:

- **Nix** for the system tools (R, Python, compilers, CmdStan, …)
- **uv** + `uv.lock` for Python packages
- **renv** + `renv.lock` for R packages
- a shared `analysis/analysis_config.yaml` for paths, seed, etc.

There’s a toy treatment-effect example under `analysis/` in four forms (`.ipynb`, `.py`, `.R`, `.Rmd`). In a real project you’d keep one of those and delete the rest.

## Setup

Install [Nix](https://nixos.org/download/), then:

```bash
nix develop
uv sync
Rscript -e 'renv::restore()'
```

Or just:

```bash
nix develop -c just sync
```

## Run the analysis

From inside `nix develop`:

```bash
just reproduce
```

That picks one entrypoint (first that exists): `analysis.Rmd` → `analysis.ipynb` → `analysis.R` → `analysis.py`.

Force a specific one with `just py`, `just ipynb`, `just r`, or `just rmd`.

One-liner from a cold clone:

```bash
nix develop -c just reproduce
```

Outputs land in `output/` (figures, tables, `results.json`).

```bash
just clean       # wipe .venv, renv library, and output/
just reproduce   # sync + run the active entrypoint
```

## Editing packages

- Python: `pyproject.toml`, then `uv lock && uv sync`
- R: `DESCRIPTION`, then `renv::snapshot()` / `renv::restore()`

## RStudio / Jupyter

RStudio: use your normal install, pointed at Nix’s R (`RSTUDIO_WHICH_R="$(which R)" open -a RStudio` on Mac; `rstudio` on Linux inside the shell).

Jupyter in VS Code/Cursor: `./scripts/register-jupyter-kernel.sh`, then pick the project kernel.
