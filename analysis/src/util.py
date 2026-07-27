"""Small shared helpers for analysis notebooks/scripts."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import yaml


def project_root() -> Path:
    """Return the repository root (parent of ``analysis/``)."""
    # analysis/src/util.py → parents[0]=src, [1]=analysis, [2]=repo root
    return Path(__file__).resolve().parents[2]


def analysis_dir() -> Path:
    """Return the ``analysis/`` directory."""
    return Path(__file__).resolve().parents[1]


def analysis_src() -> Path:
    """Return ``analysis/src``."""
    return Path(__file__).resolve().parent


def ensure_src_on_path() -> Path:
    """Put ``analysis/src`` on ``sys.path`` (idempotent). Return the project root."""
    root = project_root()
    src = str(analysis_src())
    if src not in sys.path:
        sys.path.insert(0, src)
    return root


def load_config(name: str = "analysis_config.yaml") -> tuple[Path, dict[str, Any]]:
    """Load ``analysis/analysis_config.yaml``. Returns ``(project_root, config)``."""
    root = ensure_src_on_path()
    with open(analysis_dir() / name) as f:
        return root, yaml.safe_load(f)


def results_path(root: Path | None = None, config: dict[str, Any] | None = None) -> Path:
    """Return the path to ``output/results.json`` from config."""
    if root is None or config is None:
        root, config = load_config()
    return root / config["paths"]["results"]


def load_results(
    root: Path | None = None,
    config: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Load ``results.json``, or ``{}`` if missing / unreadable."""
    path = results_path(root, config)
    if not path.is_file():
        return {}
    try:
        with open(path) as f:
            return json.load(f)
    except json.JSONDecodeError:
        return {}


def save_results(
    namespace: str,
    payload: dict[str, Any],
    root: Path | None = None,
    config: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Merge ``payload`` under ``namespace`` in ``results.json`` and write it back.

    Example::

        save_results("ttest_ind", {"statistic": 1.2, "pvalue": 0.03}, ROOT, config)
    """
    path = results_path(root, config)
    results = load_results(root, config)
    results[namespace] = payload
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with open(tmp, "w") as f:
        json.dump(results, f, indent=2)
        f.write("\n")
    tmp.replace(path)
    return results
