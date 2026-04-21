#!/usr/bin/env python3
# -*- coding: utf-8 -*-


"""
Created on Tue Nov  4 11:19:02 2025

@author: cameron

When using VS code on Sherlock, first do these
ml python/3.12.1
ml hdf5/1.14.4
source base_env/bin/activate

"""

#%%Import Packages
import os
import pandas as pd
import scipy as sp
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
from scipy.spatial.distance import squareform
from scipy.spatial.distance import squareform
import h5py as h5py
plt.rcParams['font.family'] = 'Helvetica'


# #%%Load Data
# import numpy as np
# import pandas as pd
# import seaborn as sns
# import matplotlib.pyplot as plt
# import scipy as sp

# # Load the .mat files
# # node_file_path = '/Users/cameron/Documents/GitHub/brain_HOI/cameron_code/quadratic-input-files/brain_state_mapper_noFeatureMassaging_100206_LR_node_schaefer100x7_xcpengine_2025_pdist.mat'
# # edge_file_path = '/Users/cameron/Documents/GitHub/brain_HOI/cameron_code/quadratic-input-files/brain_state_mapper_noFeatureMassaging_100206_LR_edge_schaefer100x7_xcpengine_2025_pdist.mat'  

# node_file_path = '/scratch/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/framewise_pairwise_distances_node_100206_LR_schaefer100x7.mat'
# edge_file_path = '/scratch/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/framewise_pairwise_distances_edge_100206_LR_schaefer100x7.mat'


# # Load data from .mat files
# # node_data = sp.io.loadmat(node_file_path)['dist_mat']
# # edge_data = sp.io.loadmat(edge_file_path)['dist_mat']
# with h5py.File(node_file_path) as f:
#     node_data = squareform(f['dist_mat'][:].flatten())
# with h5py.File(edge_file_path) as f:
#     edge_data = squareform(f['dist_mat'][:].flatten())

# # Convert to 1D arrays if necessary # should be already 1D though
# node_data_flat = node_data.flatten()
# edge_data_flat = edge_data.flatten()

# # Create a DataFrame for easier plotting
# data = pd.DataFrame({
#     'Node Data': node_data_flat,
#     'Edge Data': edge_data_flat
# })

# # Calculate the average score for each point
# data['Average Score'] = (data['Node Data'] + data['Edge Data']) / 2

# # Create a figure
# plt.figure(figsize=(4.3,3.6), dpi=1000)

# # Create a scatter plot without a legend
# scatter = sns.scatterplot(data=data, x='Node Data', y='Edge Data',
#                           # color = 'black',
#                           hue='Node Data', palette="crest", 
#                           alpha=0.1, edgecolor='white', s=2, zorder=1, legend=False)

# def load_distance_matrices(node_file_path, edge_file_path):
#     """Load distance matrices from .mat files and return squareform matrices."""
#     #node_data_square = squareform(sp.io.loadmat(node_file_path)['dist_mat'].flatten())
#     #edge_data_square = squareform(sp.io.loadmat(edge_file_path)['dist_mat'].flatten())
#     with h5py.File(node_file_path, 'r') as f:
#         node_data_square = squareform(f['dist_mat'][:].flatten())
#     with h5py.File(edge_file_path, 'r') as f:
#         edge_data_square = squareform(f['dist_mat'][:].flatten())
#     return node_data_square, edge_data_square

# node_data_square, edge_data_square = load_distance_matrices(node_file_path, edge_file_path)

# plt.scatter(node_data_square[362,1957], edge_data_square[362,1957], marker='o', color='black', s=30, zorder=2, label='Point 1')
# plt.scatter(node_data_square[1957,1968], edge_data_square[1957,1968], marker='o', color='black', s=30, zorder=2, label='Point 2')

# # Define the main curve
# x = np.linspace(0, 2, 1000)
# y_main = 1 - (1 - x)**2
# y_second = 1.1 * (1 - 0.5 * (1 - x)**2 - 0.5 * (1 - x)**4)
# y_third = 1 - 0.5 * (1 - x)**2 - 0.5 * abs(1 - x)

# # Plot the main curve with a higher zorder
# plt.plot(x, y_main, color='black', linestyle = '-', linewidth=0.5, zorder=2)
# plt.plot(x, y_second, color='black', linestyle = '--',  linewidth=0.5, zorder=3)
# plt.plot(x, y_third, color='black', linestyle = '--',  linewidth=0.5, zorder=4)

# plt.gca().spines['right'].set_visible(False)
# plt.gca().spines['top'].set_visible(False)

# plt.xticks(fontsize=8)  # Set x ticks font size
# plt.yticks(fontsize=8)  # Set y ticks font size

# plt.xlabel('')
# plt.ylabel('')

# # Show the plot

# plt.savefig('/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/plot_scatter_pairwise_distances_one_subject.png', dpi=600, bbox_inches='tight') # new
# plt.show()
# print("made /home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/plot_scatter_pairwise_distances_one_subject.png")

#%%
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import scipy as sp
from scipy.spatial.distance import squareform
import matplotlib.patches as patches


def load_networks(file_path):
    """Load networks from a CSV file and return a dictionary of first and last indices."""
    
    # if file_path[-4:] == '.mat':
    #     # Extract the field as a 1D array
        
    #     # mat_data = sp.io.loadmat(file_path)
    #     # feature_tasks_instantwise = mat_data['feature_tasks_instantwise'].flatten()
    #     with h5py.File(file_path, 'r') as f:
    #         mat_data = f['feature_tasks_instantwise'][:]
    #         print(mat_data.shape)
    #         feature_tasks_instantwise = mat_data.flatten()
    #         print(feature_tasks_instantwise.shape)        
    #     feature_tasks_instantwise = [str(x[0]) if len(x) > 0 else '' for x in feature_tasks_instantwise]
    #     networks = pd.DataFrame({'feature_tasks_instantwise': feature_tasks_instantwise})
    if file_path[-4:] in ['.csv', '.txt']:
        networks = pd.read_csv(file_path)
    print(file_path)
    index_dict = {}
    for index, string in enumerate(networks.iloc[:, 0]):
        if string not in index_dict:
            index_dict[string] = [index, index]
        else:
            index_dict[string][1] = index
    return index_dict

def load_distance_matrices(node_file_path, edge_file_path):
    """Load distance matrices from .mat files and return squareform matrices."""
    #node_data_square = squareform(sp.io.loadmat(node_file_path)['dist_mat'].flatten())
    #edge_data_square = squareform(sp.io.loadmat(edge_file_path)['dist_mat'].flatten())
    with h5py.File(node_file_path) as f:
        node_data_square = squareform(f['dist_mat'][:].flatten())
    with h5py.File(edge_file_path) as f:
        edge_data_square = squareform(f['dist_mat'][:].flatten())
    return node_data_square, edge_data_square

def create_heatmap(data, title, xlabel, ylabel, index_dict, tick_labels, mask=None, save_flag = 0, save_path = None):
    assert(save_flag == 0 or not save_path is None)
    """Create a heatmap with specified data and add lines based on index_dict."""
    plt.figure(figsize=(4, 3), dpi = 1000)
    sns.heatmap(data, mask=mask, cmap='Blues', square=True, cbar_kws={"shrink": 1}, vmin=0, vmax=2)
    # Add horizontal and vertical lines based on the index_dict
    for indices in index_dict.values():
        plt.axhline(y=indices[0], color='black', linestyle='-', linewidth=0.75)  # Horizontal line
        plt.axvline(x=indices[0], color='black', linestyle='-', linewidth=0.75)  # Vertical line
        plt.axhline(y=indices[1], color='black', linestyle='-', linewidth=0.75)  # Horizontal line
        plt.axvline(x=indices[1], color='black', linestyle='-', linewidth=0.75)  # Vertical line

    # Set custom tick labels
    tick_nums = []
    for bound in index_dict.keys():
        num = index_dict[bound]
        tick_nums += [(num[0] + num[1]) / 2]
        
    plt.xticks(ticks=tick_nums, labels=tick_labels, rotation=90, fontsize=8)
    plt.yticks(ticks=tick_nums, labels=tick_labels, fontsize=8)
    
    

    # Draw a border around the heatmap
    border = patches.Rectangle((0, 0), data.shape[1], data.shape[0], linewidth=1, edgecolor='black', facecolor='none')
    plt.gca().add_patch(border)

    # Overlay a triangle shape for the masked area
    if mask is not None:
        # Get the indices of the masked area
        masked_indices = np.argwhere(mask)
        if masked_indices.size > 0:
            print(masked_indices.size)
            if mask[0,0] and mask[-1,-1]:
                mask_shape = mask.shape
                if mask[0,-1]:
                    print('upper')
                    plt.fill([0, max(mask_shape), max(mask_shape)], [0, max(mask_shape), 0], color='white', alpha=1, zorder=2)

                elif mask[-1,0]:
                    plt.fill([0, 0,max(mask_shape)], [0, max(mask_shape), max(mask_shape)], color='white', alpha=1, zorder=2)
                    print('lower')
                    plt.xticks(ticks=tick_nums, labels=tick_labels, rotation=90, fontsize=8, color = 'white')
                    plt.yticks(ticks=tick_nums, labels=tick_labels, fontsize=8, color = 'white')
                    ax = plt.gca()
                    ax.tick_params(colors='white', which='both')

                plt.plot([0, max(mask_shape)], [0, max(mask_shape)], color = 'black', linewidth = 0.75)
    plt.plot(362,376, 'o', markerfacecolor='none', markeredgecolor='red', markersize = 5)
    plt.plot(1957,1968, 'o', markerfacecolor='none', markeredgecolor='red', markersize = 5)

    if save_flag:
        plt.savefig(save_path, dpi=600, bbox_inches='tight') # new
    plt.show()
    if save_flag:
        print(f"made {save_path}")
    

def create_bounded_heatmap(data, title, xlabel, ylabel, index_dict, tick_labels, bounds, save_flag = 0, save_path = None):
    assert(save_flag == 0 or not save_path is None)
    """Create a heatmap with specified data within provided bounds."""
    plt.figure(figsize=(5, 4))
    
    # Apply bounds to the data
    bounded_data = data  # Clip data to the specified bounds
    
    # Create a mask for values outside the bounds
    mask = np.where((data < bounds[0]) | (data > bounds[1]), True, False)
    
#    sns.heatmap(bounded_data, cmap="magma", square=True, cbar_kws={"shrink": .8}, vmin=0, vmax=2)
    sns.heatmap(bounded_data, cmap="Greys", square=True, cbar_kws={"shrink": .8}, vmin=0, vmax=2)
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)

    # Add horizontal and vertical lines based on the index_dict
    for indices in index_dict.values():
        plt.axhline(y=indices[0], color='black', linestyle='-', linewidth=1)  # Horizontal line
        plt.axvline(x=indices[0], color='black', linestyle='-', linewidth=1)  # Vertical line
        plt.axhline(y=indices[1], color='black', linestyle='-', linewidth=1)  # Horizontal line
        plt.axvline(x=indices[1], color='black', linestyle='-', linewidth=1)  # Vertical line

    # Set custom tick labels
    tick_nums = []
    for bound in index_dict.keys():
        num = index_dict[bound]
        tick_nums += [(num[0] + num[1]) / 2]
        
    plt.xticks(ticks=tick_nums, labels=tick_labels, rotation=90, fontsize=8)
    plt.yticks(ticks=tick_nums, labels=tick_labels, fontsize=8)
    if save_flag:
        plt.savefig(save_path, dpi=600, bbox_inches='tight')
    plt.show()
    if save_flag:
        print(f"made {save_path}")

def plot_upper_lower_triangles(node_data_square, edge_data_square, index_dict, save_flag = 0, save_directory = ""):
    assert(save_flag == 0 or os.path.isdir(save_directory))
    """Plot upper and lower triangles of the correlation matrices."""
    # Create masks for upper and lower triangles
    mask_upper_node = np.triu(np.ones_like(node_data_square, dtype=bool))
    mask_lower_node = np.tril(np.ones_like(node_data_square, dtype=bool))

    mask_upper_edge = np.triu(np.ones_like(edge_data_square, dtype=bool))
    mask_lower_edge = np.tril(np.ones_like(edge_data_square, dtype=bool))

    # Plot upper triangle for node data
    create_heatmap(node_data_square, 'Upper Triangle of Node Data', 'Nodes', 'Nodes', index_dict, list(index_dict.keys()), mask=mask_upper_node, 
                   save_flag = save_flag,
                   save_path = os.path.join(save_directory, "plot_scatter_pairwise_distances_one_subject_node_upper.png")) #new
    

    # Plot lower triangle for node data
    create_heatmap(node_data_square, 'Lower Triangle of Node Data', 'Nodes', 'Nodes', index_dict, list(index_dict.keys()), mask=mask_lower_node,save_flag = save_flag,
    save_path = os.path.join(save_directory, "plot_scatter_pairwise_distances_one_subject_node_lower.png")) #new

    # Plot upper triangle for edge data
    create_heatmap(edge_data_square, 'Upper Triangle of Edge Data', 'Edges', 'Edges', index_dict, list(index_dict.keys()), mask=mask_upper_edge,
                   save_flag = save_flag,
                   save_path = os.path.join(save_directory, "plot_scatter_pairwise_distances_one_subject_edge_upper.png")) #new

    # Plot lower triangle for edge data
    create_heatmap(edge_data_square, 'Lower Triangle of Edge Data', 'Edges', 'Edges', index_dict, list(index_dict.keys()), mask=mask_lower_edge,
                   save_flag = save_flag,
                   save_path = os.path.join(save_directory, "plot_scatter_pairwise_distances_one_subject_edge_lower.png")) #new

# File paths
#csv_file_path = '/Users/cameron/Documents/GitHub/brain_HOI/cameron_code/quadratic-input-files/heatmap_networks.csv'
#node_file_path = '/Users/cameron/Documents/GitHub/brain_HOI/cameron_code/quadratic-input-files/brain_state_mapper_noFeatureMassaging_100206_LR_node_schaefer100x7_xcpengine_2025_pdist.mat'
#edge_file_path = '/Users/cameron/Documents/GitHub/brain_HOI/cameron_code/quadratic-input-files/brain_state_mapper_noFeatureMassaging_100206_LR_edge_schaefer100x7_xcpengine_2025_pdist.mat'
#mat_file_path = '/scratch/users/siuc/edge_time_series_mapper/simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7/simplexMapper_edge_100206_LR_schaefer100x7_data.mat'
csv_file_path = '/home/users/siuc/edge_time_series_mapper/data_pipeline_gitignore/tasks_instantwise_tmp.txt'
node_file_path = '/scratch/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/framewise_pairwise_distances_node_100206_LR_schaefer100x7.mat'
edge_file_path = '/scratch/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/framewise_pairwise_distances_edge_100206_LR_schaefer100x7.mat'

# Load networks and distance matrices
#index_dict = load_networks(csv_file_path)
#index_dict = load_networks(mat_file_path)
print(f"If {csv_file_path} does not load properly, manually extract it from the field feature_tasks_instantwise in /scratch/users/siuc/edge_time_series_mapper/simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7/simplexMapper_edge_100206_LR_schaefer100x7_data.mat")
index_dict = load_networks(csv_file_path)
node_data_square, edge_data_square = load_distance_matrices(node_file_path, edge_file_path)

# Plot upper and lower triangles
plot_upper_lower_triangles(node_data_square, edge_data_square, index_dict, save_flag = 1, save_directory = '/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/')

# Example of using the bounded heatmap function
bounds = (0.5, 1.5)  # Define your bounds here
create_bounded_heatmap(node_data_square, '', 'Nodes', 'Nodes', index_dict, list(index_dict.keys()), bounds, save_flag = 1, save_path = '/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/plot_scatter_pairwise_distances_one_subject_node_bounded')
create_bounded_heatmap(edge_data_square, '', 'Edges', 'Edges', index_dict, list(index_dict.keys()), bounds, save_flag = 1, save_path = '/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/plot_scatter_pairwise_distances_one_subject_edge_bounded')

#%%NEW PARABOLA PLOT CODE

tasks_array = np.array([])
nodes_array = np.array([])
edges_array = np.array([])
#USE INDEX DICT TO GET REGIONS OF INTEREST ON THE DIAG
for task_type in list(index_dict.keys()):
    print(f'Task: {task_type}')
    indicies = index_dict[task_type]
    i_1 = indicies[0]
    i_2 = indicies[1]
    print(f'  | Index: [{i_1}:{i_2},{i_1}:{i_2}]')
    
    node_subset = node_data_square[i_1:i_2,i_1:i_2]
    edge_subset = edge_data_square[i_1:i_2,i_1:i_2]
    print(f'  | Node Shape: {node_subset.shape}')
    print(f'  | Edge Shape: {edge_subset.shape}')
    
    node_subset_flatten = node_subset.flatten()
    edge_subset_flatten = edge_subset.flatten()
    print(f'  | Node New Shape: {node_subset_flatten.shape}')
    print(f'  | Edge New Shape: {edge_subset_flatten.shape}')
    

    task_subset = np.array([task_type] * len(node_subset_flatten))
    print(f'  | Task Reference Shape: {task_subset.shape}')
    
    tasks_array = np.concatenate((tasks_array, task_subset))
    nodes_array = np.concatenate((nodes_array, node_subset_flatten))
    edges_array = np.concatenate((edges_array, edge_subset_flatten))

print(f'Total Node Shape: {nodes_array.shape}')
print(f'Total Edge Shape: {edges_array.shape}')
print(f'Total Tasks Shape: {tasks_array.shape}')

plot_df = pd.DataFrame({'Tasks':tasks_array, 'Nodes': nodes_array, 'Edges': edges_array})
#%%
# Create a figure
plt.figure(figsize=(4.3, 3.6), dpi=1000)


custom_palette = {
    'WM': '#DE745F',
    'SOCIAL': '#E59B4B',
    'RELATIONAL': '#609EF2',
    'MOTOR': '#78B6D2',
    'LANGUAGE': '#C4DFEB',
    'GAMBLING': '#ED549F',
    'EMOTION': '#F6DC6C',
    'REST': '#808080',
}

scatter = sns.scatterplot(data=plot_df, x='Nodes', y='Edges',
                          hue='Tasks', palette = custom_palette,
                          alpha=0.1, edgecolor='white', s=1, zorder=1, legend=False)



# Add specific points
plt.scatter(node_data_square[362, 1957], edge_data_square[362, 1957], marker='o', color='black', s=30, zorder=2, label='Point 1')
plt.scatter(node_data_square[1957, 1968], edge_data_square[1957, 1968], marker='o', color='black', s=30, zorder=2, label='Point 2')

# Define the main curve
x = np.linspace(0, 2, 1000)
y_main = 1 - (1 - x)**2
y_second = 1.1 * (1 - 0.5 * (1 - x)**2 - 0.5 * (1 - x)**4)
y_third = 1 - 0.5 * (1 - x)**2 - 0.5 * abs(1 - x)

# Plot the main curve with a higher zorder
plt.plot(x, y_main, color='black', linestyle='-', linewidth=0.5, zorder=2)
plt.plot(x, y_second, color='black', linestyle='--', linewidth=0.5, zorder=3)
plt.plot(x, y_third, color='black', linestyle='--', linewidth=0.5, zorder=4)

# Optional: Add grid
# plt.grid()

plt.gca().spines['right'].set_visible(False)
plt.gca().spines['top'].set_visible(False)

plt.xticks(fontsize=8)  # Set x ticks font size
plt.yticks(fontsize=8)  # Set y ticks font size

plt.xlabel('')
plt.ylabel('')
# Show the plot
plt.show()


for task in plot_df['Tasks'].unique():
    print(task)
    
    plot_df_i = plot_df[plot_df['Tasks'] == task]
    
    scatter = sns.scatterplot(data=plot_df_i, x='Nodes', y='Edges',
                              hue='Tasks', palette = custom_palette,
                              alpha=0.1, edgecolor='white', s=1, zorder=1, legend=False)

    # Add specific points
    plt.scatter(node_data_square[362, 1957], edge_data_square[362, 1957], marker='o', color='black', s=30, zorder=2, label='Point 1')
    plt.scatter(node_data_square[1957, 1968], edge_data_square[1957, 1968], marker='o', color='black', s=30, zorder=2, label='Point 2')

    # Define the main curve
    x = np.linspace(0, 2, 1000)
    y_main = 1 - (1 - x)**2
    y_second = 1.1 * (1 - 0.5 * (1 - x)**2 - 0.5 * (1 - x)**4)
    y_third = 1 - 0.5 * (1 - x)**2 - 0.5 * abs(1 - x)

    # Plot the main curve with a higher zorder
    plt.plot(x, y_main, color='black', linestyle='-', linewidth=0.5, zorder=2)
    plt.plot(x, y_second, color='black', linestyle='--', linewidth=0.5, zorder=3)
    plt.plot(x, y_third, color='black', linestyle='--', linewidth=0.5, zorder=4)

    # Optional: Add grid
    # plt.grid()

    plt.gca().spines['right'].set_visible(False)
    plt.gca().spines['top'].set_visible(False)

    plt.xticks(fontsize=8)  # Set x ticks font size
    plt.yticks(fontsize=8)  # Set y ticks font size

    plt.xlabel('')
    plt.ylabel('')
    plt.title(task)
    # Show the plot
    plt.show()

#%%Parabolas 1 far
# Load data
#p_data_1 = pd.read_csv('/Users/cameron/Documents/GitHub/brain_HOI/cameron_code/quadratic-input-files/quadratic_approximation_one_LR_schaefer100x7.csv')
p_data_1 = pd.read_csv('/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/quadratic_approximation_one_LR_schaefer100x7.csv')
a = list(p_data_1['Coeff Est (linear)'])
b = list(p_data_1['Coeff Est (quadratic)'])
c = list(p_data_1['Coeff Est (constant)'])

# Set the range of x values
x = np.linspace(-9, 11, 100000)

# Define color palette
colors = sns.color_palette("Spectral", len(c))  # Color palette

# Create a figure
plt.figure(figsize=(2.5, 2), dpi = 1000)

# Plot the parabola for each set of coefficients
for i, (a_coeff, b_coeff, c_coeff) in enumerate(zip(a, b, c)):
    y = c_coeff + a_coeff * (1 - x) + b_coeff * (1 - x)**2
    plt.plot(x, y, color=colors[i], linewidth=0.1)  # Use alpha for transparency
    
y_main = 1 - (1 - x)**2
plt.plot(x, y, color = 'black', linewidth = 0.5)

# Remove all spines
# plt.gca().spines['left'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.gca().spines['top'].set_visible(False)
# plt.gca().spines['bottom'].set_visible(False)

# Remove ticks
plt.xticks(fontsize = 8)  # Remove x ticks
plt.yticks(fontsize = 8)  # Remove y ticks

# Set limits
plt.xlim(-0.1, 2.1)
plt.ylim(0, 1.1)

# Show the plot
save_path = '/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/plot_cohortwide_one_parabolas.png'
plt.savefig(save_path, dpi = 600, bbox_inches='tight')
plt.show()
print(f"made {save_path}")


#%%Parabolas 1 close 
# Load data
#p_data_1 = pd.read_csv('/Users/cameron/Documents/GitHub/brain_HOI/cameron_code/quadratic-input-files/quadratic_approximation_one_LR_schaefer100x7.csv')
p_data_1 = pd.read_csv('/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/quadratic_approximation_one_LR_schaefer100x7.csv')
a = list(p_data_1['Coeff Est (linear)'])
b = list(p_data_1['Coeff Est (quadratic)'])
c = list(p_data_1['Coeff Est (constant)'])

# Set the range of x values
x = np.linspace(-9, 11, 100000)

# Define color palette
colors = sns.color_palette("Spectral", len(c))  # Color palette

# Create a figure
plt.figure(figsize=(10, 10), dpi = 1000)

# Plot the parabola for each set of coefficients
for i, (a_coeff, b_coeff, c_coeff) in enumerate(zip(a, b, c)):
    y = c_coeff + a_coeff * (1 - x) + b_coeff * (1 - x)**2
    plt.plot(x, y, color=colors[i], linewidth=0.5)  # Use alpha for transparency
    
y_main = 1 - (1 - x)**2
plt.plot(x, y, color = 'black', linewidth = 10)

# Remove all spines
plt.gca().spines['left'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['bottom'].set_visible(False)

# Remove ticks
plt.xticks([])  # Remove x ticks
plt.yticks([])  # Remove y ticks

# Set limits
plt.xlim(0.98, 1.02)
plt.ylim(1.0085, 1.01)

# Show the plot
save_path = '/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/plot_cohortwide_one_parabolas_zoomed.png'
plt.savefig(save_path, dpi = 600, bbox_inches='tight')
plt.show()
print(f"made {save_path}")

#%%Parabolas 2 far
# Load data
#p_data_1 = pd.read_csv('/Users/cameron/Documents/GitHub/brain_HOI/cameron_code/quadratic-input-files/quadratic_approximation_two_LR_schaefer100x7.csv')
p_data_1 = pd.read_csv('/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/quadratic_approximation_two_LR_schaefer100x7.csv')
a = list(p_data_1['Coeff Est (linear)'])
b = list(p_data_1['Coeff Est (quadratic)'])
c = list(p_data_1['Coeff Est (constant)'])

# Set the range of x values
x = np.linspace(-9, 11, 100000)

# Define color palette
colors = sns.color_palette("Spectral", len(c))  # Color palette

# Create a figure
plt.figure(figsize=(2.5, 2), dpi = 1000)

# Plot the parabola for each set of coefficients
for i, (a_coeff, b_coeff, c_coeff) in enumerate(zip(a, b, c)):
    y = c_coeff + a_coeff * (1 - x) + b_coeff * (1 - x)**2
    plt.plot(x, y, color=colors[i], linewidth=0.1)  # Use alpha for transparency
    
y_main = 1 - (1 - x)**2
plt.plot(x, y, color = 'black', linewidth = 0.5)

# Remove all spines
# plt.gca().spines['left'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.gca().spines['top'].set_visible(False)
# plt.gca().spines['bottom'].set_visible(False)

# Remove ticks
plt.xticks(fontsize = 8)  # Remove x ticks
plt.yticks(fontsize = 8)  # Remove y ticks

# Set limits
plt.xlim(-0.1, 2.1)
plt.ylim(0, 1.1)

# Show the plot
save_path = '/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/plot_cohortwide_two_parabolas.png'
plt.savefig(save_path, dpi = 600, bbox_inches='tight')
plt.show()
print(f"made {save_path}")


#%%Parabolas 2 close 
# Load data
#p_data_1 = pd.read_csv('/Users/cameron/Documents/GitHub/brain_HOI/cameron_code/quadratic-input-files/quadratic_approximation_two_LR_schaefer100x7.csv')
p_data_1 = pd.read_csv('/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/quadratic_approximation_two_LR_schaefer100x7.csv')
a = list(p_data_1['Coeff Est (linear)'])
b = list(p_data_1['Coeff Est (quadratic)'])
c = list(p_data_1['Coeff Est (constant)'])

# Set the range of x values
x = np.linspace(-9, 11, 100000)

# Define color palette
colors = sns.color_palette("Spectral", len(c))  # Color palette

# Create a figure
plt.figure(figsize=(10, 10), dpi = 1000)

# Plot the parabola for each set of coefficients
for i, (a_coeff, b_coeff, c_coeff) in enumerate(zip(a, b, c)):
    y = c_coeff + a_coeff * (1 - x) + b_coeff * (1 - x)**2
    plt.plot(x, y, color=colors[i], linewidth=0.5)  # Use alpha for transparency
    
y_main = 1 - (1 - x)**2
plt.plot(x, y, color = 'black', linewidth = 10)

# Remove all spines
plt.gca().spines['left'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.gca().spines['top'].set_visible(False)
plt.gca().spines['bottom'].set_visible(False)

# Remove ticks
plt.xticks([])  # Remove x ticks
plt.yticks([])  # Remove y ticks

# Set limits
plt.xlim(0.98, 1.02)
plt.ylim(1.0082, 1.0101)

# Show the plot
save_path = '/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/plot_cohortwide_two_parabolas_zoomed.png'
plt.savefig(save_path, dpi = 600, bbox_inches='tight')
plt.show()
print(f"made {save_path}")

#%%Cohort 1 and 2 r distribution
# Load data
# p_data_1 = pd.read_csv('/Users/cameron/Documents/GitHub/brain_HOI/cameron_code/quadratic-input-files/quadratic_approximation_one_LR_schaefer100x7.csv')
# p_data_2 = pd.read_csv('/Users/cameron/Documents/GitHub/brain_HOI/cameron_code/quadratic-input-files/quadratic_approximation_two_LR_schaefer100x7.csv')

p_data_1 = pd.read_csv('/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/quadratic_approximation_one_LR_schaefer100x7.csv')
p_data_2 = pd.read_csv('/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/quadratic_approximation_two_LR_schaefer100x7.csv')

# Extract R squared values
r_distribution_data_1_fit = list(p_data_1['R squared'])
r_distribution_data_1_hypothesis = list(p_data_1['R squared hypothesis'])
r_distribution_data_2_fit = list(p_data_2['R squared'])
r_distribution_data_2_hypothesis = list(p_data_2['R squared hypothesis'])

# Create a figure
plt.figure(figsize=(2.5, 2), dpi = 1000)

# Plot histogram for the best fit
sns.histplot(r_distribution_data_1_fit, binwidth=0.002, binrange = (0.9, 1), color='#008ECC', label='Best Fit', kde=False, stat='count', alpha=0.8)

# Plot histogram for the hypothesis
sns.histplot(r_distribution_data_1_hypothesis, binwidth=0.002, binrange = (0.9, 1), color='#CB3D4C', label='Hypothesis', kde=False, stat='count', alpha=0.8)


# Add labels and title
# plt.title('R-squared Distribution Comparison')
# plt.xlabel('R-squared Values')
plt.ylabel('')
# plt.gca().spines['left'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.gca().spines['top'].set_visible(False)
# plt.gca().spines['bottom'].set_visible(False)

plt.xticks(fontsize = 8)  # Remove x ticks
plt.yticks(fontsize = 8)  # Remove y ticks
plt.xlim(0.9 ,1)
plt.ylim(0, 80)

# Show the plot
save_path = '/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/plot_R_squared_one.png'
plt.savefig(save_path, dpi = 600, bbox_inches='tight')
plt.show()
print(f"made {save_path}")

# Create a figure
plt.figure(figsize=(2.5, 2), dpi = 1000)

# Plot histogram for the best fit
sns.histplot(r_distribution_data_2_fit, binwidth=0.002, binrange = (0.9, 1), color='#008ECC', label='Best Fit', kde=False, stat='count', alpha=0.8)

# Plot histogram for the hypothesis
sns.histplot(r_distribution_data_2_hypothesis, binwidth=0.002, binrange = (0.9, 1), color='#CB3D4C', label='Hypothesis', kde=False, stat='count', alpha=0.8)


# Add labels and title
# plt.title('R-squared Distribution Comparison')
# plt.xlabel('R-squared Values')
plt.ylabel('')
# plt.gca().spines['left'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.gca().spines['top'].set_visible(False)
# plt.gca().spines['bottom'].set_visible(False)

plt.xticks(fontsize = 8)  # Remove x ticks
plt.yticks(fontsize = 8)  # Remove y ticks

plt.ylim(0, 80)
plt.xlim(0.9 ,1)

# Show the plot
save_path = '/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/plot_R_squared_two.png'
plt.savefig(save_path, dpi = 600, bbox_inches='tight')
plt.show()
print(f"made {save_path}")

#%%Cohort 1 and 2 deviation distribution
# Load data
# p_data_1 = pd.read_csv('/Users/cameron/Documents/GitHub/brain_HOI/cameron_code/quadratic-input-files/quadratic_approximation_one_LR_schaefer100x7.csv')
# p_data_2 = pd.read_csv('/Users/cameron/Documents/GitHub/brain_HOI/cameron_code/quadratic-input-files/quadratic_approximation_two_LR_schaefer100x7.csv')

p_data_1 = pd.read_csv('/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/quadratic_approximation_one_LR_schaefer100x7.csv')
p_data_2 = pd.read_csv('/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/quadratic_approximation_two_LR_schaefer100x7.csv')

# Extract R squared values
r_distribution_data_1_fit = list(p_data_1['Upper bound violation'])
r_distribution_data_1_hypothesis = list(p_data_1['Lower bound violation'])
r_distribution_data_2_fit = list(p_data_2['Upper bound violation'])
r_distribution_data_2_hypothesis = list(p_data_2['Lower bound violation'])

# Create a figure
plt.figure(figsize=(2.5, 2), dpi = 1000)

# Plot histogram for the best fit
sns.histplot(r_distribution_data_1_fit, binwidth = 0.00002,binrange = (0 ,0.001), color='#008ECC', label='Upper', kde=False, stat='count', alpha=0.8)

# Plot histogram for the hypothesis
sns.histplot(r_distribution_data_1_hypothesis, binwidth = 0.00002,binrange = (0 ,0.001), color='#CB3D4C', label='Lower', kde=False, stat='count', alpha=0.8)


# Add labels and title
# plt.title('R-squared Distribution Comparison')
# plt.xlabel('R-squared Values')
plt.ylabel('')
# plt.gca().spines['left'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.gca().spines['top'].set_visible(False)
# plt.gca().spines['bottom'].set_visible(False)

plt.xticks(fontsize = 8)  # Remove x ticks
plt.yticks(fontsize = 8)  # Remove y ticks
plt.xlim(0 ,0.001)
plt.ylim(0, 400)

# Show the plot
save_path = '/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/plot_bound_violation_one.png'
plt.savefig(save_path, dpi = 600, bbox_inches='tight')
plt.show()
print(f"made {save_path}")

# Create a figure
plt.figure(figsize=(2.5, 2), dpi = 1000)

# Plot histogram for the best fit
sns.histplot(r_distribution_data_2_fit, binwidth = 0.00002,binrange = (0 ,0.001),  color='#008ECC', label='Upper', kde=False, stat='count', alpha=0.8)

# Plot histogram for the hypothesis
sns.histplot(r_distribution_data_2_hypothesis, binwidth = 0.00002,binrange = (0 ,0.001), color='#CB3D4C', label='Lower', kde=False, stat='count', alpha=0.8)


# Add labels and title
# plt.title('R-squared Distribution Comparison')
# plt.xlabel('R-squared Values')
plt.ylabel('')
# plt.gca().spines['left'].set_visible(False)
plt.gca().spines['right'].set_visible(False)
plt.gca().spines['top'].set_visible(False)
# plt.gca().spines['bottom'].set_visible(False)

plt.xticks(fontsize = 8)  # Remove x ticks
plt.yticks(fontsize = 8)  # Remove y ticks

# plt.ylim(0, 100)
plt.xlim(0 ,0.001)
plt.ylim(0, 400)

# Show the plot
save_path = '/home/users/siuc/edge_time_series_mapper/data_pipeline/pairwise_distances/plot_bound_violation_two.png'
plt.savefig(save_path, dpi = 600, bbox_inches='tight')
plt.show()
print(f"made {save_path}")










