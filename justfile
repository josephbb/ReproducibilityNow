# One-liner analysis runners. Use inside `nix develop`.
#   just --list
#
# `just reproduce` runs a single entrypoint (first match wins):
#   analysis.Rmd → analysis.ipynb → analysis.R → analysis.py
# Delete or rename the others if you only want one.

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
    @just --list

# Python deps from uv.lock
sync-py:
    uv sync

# R deps from renv.lock
sync-r:
    Rscript -e 'renv::restore(prompt = FALSE)'

# Both lockfile restores
sync: sync-py sync-r

# System RStudio + Nix R (run inside nix develop)
rstudio:
    ./scripts/rstudio-nix.sh

# Wipe local installs + generated outputs (keeps lockfiles / source)
clean:
    #!/usr/bin/env bash
    rm -rf .venv
    rm -rf renv/library renv/local renv/cellar renv/lock renv/python renv/staging
    rm -rf __pycache__ analysis/__pycache__ analysis/src/__pycache__
    rm -rf .ipynb_checkpoints analysis/.ipynb_checkpoints
    rm -f .Rhistory .RData scripts/.jupyter-ld-library-path
    mkdir -p output/figures output/tables
    find output/figures output/tables -type f ! -name '.gitkeep' -delete
    rm -f output/results.json output/analysis.nb.html output/*.html
    # empty results file so paths stay valid
    printf '{}\n' > output/results.json
    echo "Cleaned .venv, renv library caches, and output/"

# Python script
py: sync-py
    uv run python analysis/analysis.py

# Jupyter notebook (execute in place)
ipynb: sync-py
    uv run jupyter nbconvert --to notebook --execute analysis/analysis.ipynb --inplace

# R script
r: sync-r
    Rscript analysis/analysis.R

# R Markdown → output/analysis.nb.html
rmd: sync-r
    Rscript -e 'rmarkdown::render("analysis/analysis.Rmd", output_dir = "output")'

# Reproduce via the highest-precedence entrypoint that exists
reproduce:
    #!/usr/bin/env bash
    if [[ -f analysis/analysis.Rmd ]]; then
      echo "→ analysis.Rmd"
      just rmd
    elif [[ -f analysis/analysis.ipynb ]]; then
      echo "→ analysis.ipynb"
      just ipynb
    elif [[ -f analysis/analysis.R ]]; then
      echo "→ analysis.R"
      just r
    elif [[ -f analysis/analysis.py ]]; then
      echo "→ analysis.py"
      just py
    else
      echo "No analysis entrypoint found (expected analysis.Rmd/.ipynb/.R/.py)" >&2
      exit 1
    fi
    echo "Done. See output/results.json, output/figures/, output/tables/"
