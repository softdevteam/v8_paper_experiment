import json
import pandas as pd
from scipy.stats import t
from pathlib import Path
import sys

def confidence_interval(stddev, n):
    Z = 2.576  # 99% interval
    return Z * (stddev / math.sqrt(n))

def slowdown(baseline, comparison):
    return ((comparison - baseline) / baseline) * 100

def is_statistically_distinguishable(baseline_avg, baseline_ci, comparison_avg, comparison_ci):
    return not (baseline_avg + baseline_ci < comparison_avg - comparison_ci or 
                baseline_avg - baseline_ci > comparison_avg + comparison_ci)


with open('speedometer2.1.json', 'r') as file:
    data = json.load(file)

datafile = sys.argv[1]

# Filter only totals and extract averages and standard deviations
def extract(datafile):
    return {k: {'average': v['average'], 'stddev': v['stddev']} 
            for k, v in data.items() if 'total' in k}

hdata = data['chrome_v133_chrome-handles']['data']
ddata = data['chrome_v133_chrome-direct']['data']
hncdata = data['chrome_v133_chrome-handles-no-compression']['data']
dncdata = data['chrome_v133_chrome-direct-no-compression']['data']

handles_df = pd.DataFrame.from_dict(extract(hdata), orient='index')
direct_df = pd.DataFrame.from_dict(extract(ddata), orient='index')
handles_no_compression_df = pd.DataFrame.from_dict(extract(hncdata), orient='index')
direct_no_compression_df = pd.DataFrame.from_dict(extract(dncdata), orient='index')

assert(len(handles_df) == len(direct_df))

# Calculate confidence intervals
iters = len(handles_df)
handles_df['ci'] = handles_df['stddev'].apply(lambda x: confidence_interval(x, iters))
direct_df['ci'] = direct_df['stddev'].apply(lambda x: confidence_interval(x, iters))

df = pd.DataFrame({
    'handles_avg': handles_df['average'],
    'handles_ci': handles_df['ci'],
    'direct_avg': direct_df['average'],
    'direct_ci': direct_df['ci']
})

# Add slowdown and statistically distinguishable cols
df['slowdown'] = df.apply(lambda row: slowdown(row['handles_avg'], row['direct_avg']), axis=1)
df['statistically_distinguishable'] = df.apply(
    lambda row: is_statistically_distinguishable(row['handles_avg'], row['handles_ci'], 
                                                 row['direct_avg'], row['direct_ci']), axis=1
)

# Formatting
df.columns = ['Chrome-Handles Average', 'Chrome-Handles 99% CI', 
              'Chrome-Direct Average', 'Chrome-Direct 99% CI', 
              'Slowdown (%)', 'Statistically Distinguishable']
df = df.reset_index().rename(columns={'index': 'Test Configuration'})

outfile = Path(datafile).stem + '.md'
with open("w", outfile):
    df.to_markdown(floatfmt=".2f")
