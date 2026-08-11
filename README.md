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

## Just commands

Run these from inside `nix develop` (or as `nix develop -c just <recipe>`).

| Command | What it does |
| --- | --- |
| `just` / `just --list` | List recipes |
| `just sync-py` | Restore Python deps (`uv sync`) |
| `just sync-r` | Restore R deps (`renv::restore()`) |
| `just sync` | Both of the above |
| `just py` | Run `analysis/analysis.py` |
| `just ipynb` | Execute `analysis/analysis.ipynb` in place |
| `just r` | Run `analysis/analysis.R` |
| `just rmd` | Render `analysis/analysis.Rmd` → `output/analysis.nb.html` |
| `just reproduce` | Sync + run the first existing entrypoint (see below) |
| `just rstudio` | Open system RStudio pointed at Nix R |
| `just clean` | Wipe `.venv`, renv library caches, and generated `output/` |

`just reproduce` picks one entrypoint (first that exists): `analysis.Rmd` → `analysis.ipynb` → `analysis.R` → `analysis.py`.

One-liner from a cold clone:

```bash
nix develop -c just reproduce
```

Outputs land in `output/` (figures, tables, `results.json`).

## Editing packages

- Python: `pyproject.toml`, then `uv lock && uv sync`
- R: `DESCRIPTION`, then `renv::snapshot()` / `renv::restore()`

## RStudio / Jupyter

RStudio (system GUI, Nix R):

```bash
nix develop
just rstudio
```

That sets `RSTUDIO_WHICH_R` to the Nix `R` and launches your normal RStudio. Prefer fitting models with `just r` / `Rscript` if GUI library loading acts up on macOS.

If CmdStan complains about precompiled headers / `rebuild_cmdstan()`, the Nix CmdStan path is read-only. Install a writable copy once:

```r
cmdstanr::install_cmdstan()
```

`nix develop` and `just rstudio` then prefer `~/.cmdstan/cmdstan-*` over the store path.

Jupyter in VS Code/Cursor: `./scripts/register-jupyter-kernel.sh`, then pick the project kernel.
