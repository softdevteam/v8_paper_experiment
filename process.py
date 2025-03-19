import json
import pandas as pd
from scipy.stats import t
from pathlib import Path
import sys
import os
import math

PRETTY_CFGS = {
    "handles": "Handles",
    "handles_no_pc": "Handles (w/o pointer compression)",
    "direct_refs": "Direct Refs.",
    "direct_refs_no_pc": "Direct Refs. (w/o pointer compression)",
}


def ci(stddev, n):
    Z = 2.576  # 99% interval
    return Z * (stddev / math.sqrt(n))


def slowdown(baseline, comparison):
    return ((comparison - baseline) / baseline) * 100


def is_statistically_distinguishable(
    baseline_avg, baseline_ci, comparison_avg, comparison_ci
):
    return not (
        baseline_avg + baseline_ci < comparison_avg - comparison_ci
        or baseline_avg - baseline_ci > comparison_avg + comparison_ci
    )


infile = sys.argv[1]
outfile = sys.argv[2]

with open(infile, "r") as f:
    data = json.load(f)


# Filter only totals and extract averages and standard deviations
def extract(data):
    things_we_care_about = {
        k: {"average": v["average"], "stddev": v["stddev"]} for k, v in data.items()
    }
    return pd.DataFrame.from_dict(things_we_care_about, orient="index")


iters = int(os.environ["ITERS"])
for v in data.values():
    assert all([len(story["values"]) == iters for story in v["data"].values()])

headers = [v["info"]["binary"] for k, v in sorted(data.items())]
data = [extract(v["data"]) for k, v in sorted(data.items())]

# Calculate confidence intervals
for cfg in data:
    cfg["ci"] = cfg["stddev"].apply(lambda x: ci(x, iters))
    cfg["display"] = (
        cfg["average"].round(2).astype(str)
        + " (\u00B1 "
        + cfg["ci"].round(3).astype(str)
        + ")"
    )

merged = {}
for binpath, results in zip(headers, data):
    cfg = binpath.split("/")[-2]
    merged[PRETTY_CFGS[cfg]] = results["display"]

df = pd.DataFrame(merged)
df = df.reset_index().rename(columns={"index": "Test Configuration"})

with open(outfile, "w") as f:
    f.write(df.to_markdown(floatfmt=".2f"))
