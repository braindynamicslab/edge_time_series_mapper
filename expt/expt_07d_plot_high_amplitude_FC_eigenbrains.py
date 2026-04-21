#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Apr 16 15:30:36 2026

@author: siuc
"""

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jan 20 10:50:12 2026

@author: siuc
"""
import re
import glob
import numpy as np
import matplotlib.pyplot as plt
import os

def plot_schaefer_brain(vector_data, num_networks, size_voxel, save_flag = 0, output_directory = None, name = None, title = "", vmax = None):
    from nilearn.datasets import fetch_atlas_schaefer_2018
    from nilearn.maskers import NiftiLabelsMasker
    from nilearn.image import smooth_img
    from nilearn.plotting import plot_glass_brain
    from scipy.stats import zscore

    len_vector = len(vector_data)

    atlas = fetch_atlas_schaefer_2018(
        n_rois=len_vector,
        yeo_networks=num_networks,
        resolution_mm=size_voxel,
        data_dir=None,
        base_url=None,
        resume=True,
        verbose=1
    )

    masker = NiftiLabelsMasker(
        labels_img=atlas.maps,
        standardize=False,
        memory=None
    )
    masker.fit()
    normalized_data = vector_data/np.linalg.norm(vector_data)
    print(normalized_data[23:29])
    print(normalized_data[73:77])
    data_img = masker.inverse_transform(normalized_data)
    data_imgsmooth = smooth_img(data_img, 4)
    
    if save_flag:
        output_file = os.path.join(output_directory, f'{name}.png')
    else:
        output_file = None                         
    plot_glass_brain(
        data_imgsmooth,
        threshold=0,
        cmap='coolwarm',
        vmax=vmax,
        title=title,
        annotate=False,
        colorbar=True,
        plot_abs=False,
        output_file=output_file
    )
    plt.show()

#%%


# files = glob.glob('/Users/camglick/Downloads/high_amplitude_FC/*.csv')
# files = (glob.glob('/Users/siuc/Documents/GitHub/brain_HOI/data_output/high_amplitude_FC-6/*WM*.csv') +
#          glob.glob('/Users/siuc/Documents/GitHub/brain_HOI/data_output/high_amplitude_FC-6/*MOTOR*.csv'))
files = (glob.glob('/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/high_amplitude_functional_connectivity/*WM*_one_*1.csv') + 
         glob.glob('/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/high_amplitude_functional_connectivity/*MOTOR*_one_*1.csv') + 
         glob.glob('/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/high_amplitude_functional_connectivity/*WM*_two_*1.csv') +
         glob.glob('/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/high_amplitude_functional_connectivity/*MOTOR*_two_*1.csv')) # 1 stands for subtract rest flag


entries_VIS = np.concatenate([np.arange(1, 10), np.arange(51, 59)])
entries_VIS -= 1

entries_VIS_L = np.arange(1, 10)
entries_VIS_L -= 1


entries_SOM_L = np.arange(10, 16) - 1

entries_SOM = np.concatenate([np.arange(10, 16), np.arange(59, 67)])
entries_SOM -= 1

entries_FPC = np.concatenate([np.arange(34, 38), np.arange(81, 90)])
entries_FPC -= 1

entries_FPC_R = np.arange(81, 90)
entries_FPC_R -= 1

num_eigenvectors = 3

title_flag = 1

output_directory = '/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/high_amplitude_FC_eigenbrains/'
if not os.path.isdir(output_directory):
    os.mkdir(output_directory)
# output_directory = "/Users/camglick/Downloads/high_amplitude_FC_png",
#print(output_directory)

biggest = []
for file in files:
    match_parts = re.match(r'data_high_amp_FC_([^_]+)_([^_]+)_([^_]+)_(.+)_([01]).csv$', os.path.basename(file))
    if match_parts:
        task, cohort, session, FC_type, subtract_rest_flag = match_parts.groups()
        print(f"Task: {task}")
        print(f"Cohort: {cohort}")
        print(f"Session: {session}")
        print(f"FC type: {FC_type}")
        print(f"subtract rest: {subtract_rest_flag}")
    data = np.genfromtxt(file, delimiter=',', skip_header=0)
    eigenvalues, eigenvectors = np.linalg.eig(data)
    indices = np.argsort(eigenvalues)[::-1]
    print(file)
    variance_explained = eigenvalues[indices[:num_eigenvectors]]/sum(eigenvalues[eigenvalues > 0])
    first_few_eigenvectors = eigenvectors[:, indices[:num_eigenvectors]]

    name = os.path.basename(file)[:-4]

    #print(name)

    biggest += [first_few_eigenvectors.max()]
    
    for eigenvector_id in range(num_eigenvectors):
        eigenvector = first_few_eigenvectors[:, eigenvector_id]
        variance_explained_percentage = variance_explained[eigenvector_id] * 100
        if eigenvector_id == 2:
            if task == "WM":
                positive_entries = entries_FPC_R
            else:
                positive_entries = entries_SOM_L
        else:
            positive_entries = entries_VIS_L
        if sum(eigenvector[positive_entries]) < 0:
            eigenvector *= -1
        title = f"{task}, {cohort}, {session}, subtract rest: {subtract_rest_flag}, eigenindex: {eigenvector_id}, {variance_explained_percentage:.3g}%"
        print(title)
        if not title_flag:
            title = ""
        plot_schaefer_brain(
            eigenvector,
            num_networks = 7,
            size_voxel = 2,
            save_flag = 1,
            vmax = 0.3,
            title = title,
            output_directory = output_directory,
            name = name + f"_{eigenvector_id + 1}_title_flag_{title_flag}"
        )
        fig, ax = plt.subplots()
        ax.plot(eigenvector/np.linalg.norm(eigenvector))
        ax.set_title(title)
        ax.vlines([23, 29, 73, 77], ymin = -.4, ymax = .4)
        ax.hlines([-0.25, -0.3, -0.35, 0.25, 0.3, 0.35], xmin = 0, xmax = 100)
        ax.set_title(title)

import seaborn as sns
sns.displot(biggest)
plt.show()


