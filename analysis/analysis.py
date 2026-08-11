# nix develop && uv sync
# python analysis/analysis.py

from __future__ import annotations

import sys
from pathlib import Path

src = next(
    (p / "analysis" / "src")
    for p in (Path.cwd().resolve(), *Path.cwd().resolve().parents)
    if (p / "analysis" / "src" / "util.py").is_file()
)
sys.path.insert(0, str(src))

import arviz as az
import matplotlib.pyplot as plt
import pandas as pd
import pymc as pm
from scipy.stats import ttest_ind
from util import load_config, save_results

ROOT, config = load_config()
pal = config["palette"]["colors"]
fig_dir = ROOT / config["paths"]["figures"]
tab_dir = ROOT / config["paths"]["tables"]
fig_dir.mkdir(parents=True, exist_ok=True)
tab_dir.mkdir(parents=True, exist_ok=True)

df = pd.read_csv(ROOT / config["paths"]["dataset_one"])

treated = df.loc[df["treatment"] == 1, "outcome"]
control = df.loc[df["treatment"] == 0, "outcome"]
tt = ttest_ind(treated, control)
save_results(
    "ttest_ind",
    {"statistic": float(tt.statistic), "pvalue": float(tt.pvalue), "df": float(tt.df)},
    ROOT,
    config,
)

treatment = df["treatment"].to_numpy()
outcome = df["outcome"].to_numpy()

with pm.Model() as model:
    alpha = pm.Normal("alpha", mu=0, sigma=10, shape=2)
    sigma = pm.HalfNormal("sigma", sigma=10)
    pm.Normal("obs", mu=alpha[treatment], sigma=sigma, observed=outcome)
    idata = pm.sample(
        draws=config["python"]["draws"],
        tune=config["python"]["tune"],
        random_seed=config["seed"],
        progressbar=False,
    )

summary = az.summary(idata, var_names=["alpha", "sigma"])
(tab_dir / "pymc_alpha_sigma.tex").write_text(summary.to_latex())

idata.posterior["beta"] = (
    idata.posterior["alpha"].isel(alpha_dim_0=1)
    - idata.posterior["alpha"].isel(alpha_dim_0=0)
)
beta = idata.posterior["beta"]
save_results(
    "treatment_effect",
    {
        "beta": float(beta.mean()),
        "ci_low": float(beta.quantile(0.03)),
        "ci_high": float(beta.quantile(0.97)),
    },
    ROOT,
    config,
)

az.plot_forest(idata, var_names=["beta"], combined=True)
fig = plt.gcf()
fig.patch.set_facecolor(pal["mist_sky"])
for ax in fig.axes:
    ax.set_facecolor(pal["mist_sky"])
    for line in ax.get_lines():
        line.set_color(pal["ember_clay"])
    for coll in ax.collections:
        coll.set_color(pal["cedar_needle"])
plt.savefig(fig_dir / "trace_treatment_effect.png", dpi=150, bbox_inches="tight")
plt.close()
