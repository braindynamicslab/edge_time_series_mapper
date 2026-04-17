#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Oct 20 09:01:09 2025

@author: cameron
"""

#%%
import numpy as np
from nilearn.maskers import NiftiLabelsMasker
from nilearn.image import smooth_img, new_img_like
from nilearn.plotting import plot_glass_brain
from nilearn.datasets import fetch_atlas_schaefer_2018  # Import the fetch function
import pandas as pd
import nibabel as nib
import pandas as pd
import glob
import os
from scipy.stats import zscore

#%%Fetch the Schaefer atlas
num_regions = 100
num_networks = 7

atlas = fetch_atlas_schaefer_2018(n_rois=num_regions, yeo_networks=num_networks, resolution_mm=2, data_dir=None, base_url=None, resume=True, verbose=1)

masker = NiftiLabelsMasker(
    labels_img=atlas.maps,
    standardize=False,
    memory=None
)
masker.fit()

#%% Get Data
directory = "./plotting_input_files"
pattern = "*.1D"

dataframes = []

for file_path in glob.glob(os.path.join(directory, pattern)):
    df = pd.read_csv(file_path, delimiter=r'\s+', header=None)
    df.insert(0, 'file_name', os.path.basename(file_path))
    
    # Select numeric columns
    numeric_columns = df.select_dtypes(include=['float64', 'int64']).columns
    
    # Z-score across columns (axis=0)
    df[numeric_columns] = zscore(df[numeric_columns], axis = 0)
    
    # Z-score across rows (axis=1)
    df[numeric_columns] = zscore(df[numeric_columns], axis = 1)
    
    dataframes.append(df)
    pass

parcellated_data = pd.concat(dataframes, ignore_index=True)

filter_data = pd.read_csv('/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/top_pdist_LR_schaefer100x7.csv', delimiter=',', header=0).dropna()

def find_file_path(subject, task):
    """Find the file path matching the pattern for given subject and task."""
    # Determine the acquisition string
    if task == 'REST':
        acq_str = 'LR_run-1'
    else:
        acq_str = 'LR'
    
    # Construct the pattern
    pattern = f'/oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/xa*/sub-{subject}_task-{task}_acq-{acq_str}/fcon/*schaefer100x7*'
    
    # Find matching files
    matches = glob.glob(pattern)
    
    # Return the first match if found, otherwise return None or empty string
    if matches:
        return matches[0]
    else:
        return ''

# Add the Path column
filter_data['Path'] = filter_data.apply(
    lambda row: find_file_path(row['Subject'], row['task 1']), 
    axis=1
)

filter_data['file_name'] = filter_data.iloc[:, -1].apply(os.path.basename)

#%%Loop to plot specific pairs of timepoints

len_filter_data = len(filter_data)
for row_i, row in enumerate(filter_data.iterrows()):
    row_file_name = row[1]['file_name']
    print(f'{row_i + 1} of {len_filter_data}: {row_file_name}')
    
    t1,t2 = int(row[1]['TR 1 within task']), int(row[1]['TR 2 within task'])
    print(f'  | TRS to plot: ({t1}, {t2})')
    
    activity_t1 = pd.to_numeric(parcellated_data.loc[parcellated_data['file_name'] == row_file_name].iloc[t1,1:].values.flatten(), errors='coerce')
    activity_t2 = pd.to_numeric(parcellated_data.loc[parcellated_data['file_name'] == row_file_name].iloc[t2, 1:].values.flatten(), errors='coerce')
    
    if len(activity_t1) < num_regions:
        print(f'  | t1 needs to be padded: Data: {len(activity_t1)} < Atlas: {num_regions}')
        activity_t1 = np.pad(activity_t1, (0, num_regions - len(activity_t1)), 'constant')
        
    if len(activity_t2) < num_regions:
        print(f'| t2 needs to be padded: Data: {len(activity_t2)} < Atlas: {num_regions}')
        activity_t2 = np.pad(activity_t2, (0, num_regions - len(activity_t2)), 'constant')

    activity_t1_2d, activity_t2_2d = activity_t1.reshape(1, -1), activity_t2.reshape(1, -1)
    data_img_t1, data_img_t2 = masker.inverse_transform(activity_t1_2d), masker.inverse_transform(activity_t2_2d)
    data_imgsmooth_t1, data_imgsmooth_t2 = smooth_img(data_img_t1, 4), smooth_img(data_img_t2, 4)
    plot_name_1, plot_name_2 = f'{row_file_name}_timepoint_t1_tr_{t1}', f'{row_file_name}_timepoint_t2_tr_{t2}'
    
    plot_glass_brain(data_imgsmooth_t1, 
                     threshold=0, 
                     cmap='coolwarm', 
                     vmax=1, 
                     title="", 
                     annotate=False, 
                     colorbar=True, 
                     plot_abs=False, 
                     output_file = os.path.join('.','plots', f'{plot_name_1}.png'))
    plot_glass_brain(data_imgsmooth_t2, 
                     threshold=0, 
                     cmap='coolwarm', 
                     vmax=1, 
                     title="", 
                     annotate=False, 
                     colorbar=True, 
                     plot_abs=False, 
                     output_file = os.path.join('.','plots', f'{plot_name_2}.png'))
