import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
from matplotlib.ticker import FuncFormatter, FixedLocator


# Configuration (match your MATLAB parameters)
cohort = "one"
# cohort = "two"
session = "LR"
session = "RL"
parcellation = "schaefer100x7"
simplex = "edge"
featureMassaging = "noFeatureMassaging"

print(cohort)
print(session)

# Set font size globally
plt.rcParams.update({'font.size': 18})

# Read the data
output_filename = f"/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/mapper_node_features/mapper_node_features_{simplex}_{cohort}_{session}.csv"
output_table = pd.read_csv(output_filename, sep=',')

# Extract purity values and remove NaNs
pur = output_table['mapper_stat_node_purity'].dropna().values

# Calculate proportions
purity_threshold = 0.6
proportion_perfect_purity = np.sum(pur == 1.0) / len(pur)
proportion_impurity = np.sum(pur <= purity_threshold) / len(pur)
proportion_imperfect_purity = 1 - proportion_perfect_purity - proportion_impurity

# Base path for saving
output_directory = "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/plot_node_purity"
if not os.path.isdir(output_directory):
    os.makedirs(output_directory)
base_filename = os.path.join(output_directory,
    f"plot_purity_distribution_{simplex}_{cohort}_{session}_{parcellation}"
    )

# Plot 1: Auto Y-axis with custom scientific notation
fig, ax = plt.subplots(figsize=(4, 2.4))
ax.hist(pur, bins=20, edgecolor='none')
ax.set_xlim(0, 1)
ax.set_yticks([0, 50000, 100000, 150000])
ax.set_yticklabels([r'0', r'$0.5 \times 10^5$', r'$1.0 \times 10^5$', r'$1.5 \times 10^5$'])
ax.tick_params(labelsize=18)
plt.tight_layout()
plt.savefig(f"{base_filename}_autoYlim.png", dpi=300)

# Plot 2: Fixed Y-axis with scientific notation
fig, ax = plt.subplots(figsize=(4, 2.4))
ax.hist(pur, bins=20, edgecolor='none')
ax.set_xlim(0, 1)
ax.set_ylim(0, 2000)
ax.set_yticks([0, 1000, 2000])
ax.set_yticklabels([r'0', r'$10^3$', r'$2 \times 10^3$'])
ax.tick_params(labelsize=18)
plt.tight_layout()
plt.savefig(f"{base_filename}_fixedYlim.png", dpi=300)

# Plot 3: Log scale Y-axis with custom ticks
fig, ax = plt.subplots(figsize=(4, 2.4))
ax.hist(pur, bins=20, edgecolor='none')
ax.set_xlim(0, 1)
ax.set_yscale('log')
ax.set_yticks([10, 100, 1000, 10000])
ax.set_yticklabels([r'$10^1$', r'$10^2$', r'$10^3$', r'$10^4$'])
ax.tick_params(labelsize=18)
plt.tight_layout()
plt.savefig(f"{base_filename}_logY.png", dpi=300)

print(f"Plots saved to: {base_filename}_*.png")
print(f"Proportion of perfect purity: {proportion_perfect_purity}")
print(f"Proportion of imperfect purity ({purity_threshold} to 1): {proportion_imperfect_purity}")
print(f"Impurity (≤0.6): {proportion_impurity:.3g}")

plt.show()