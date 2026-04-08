% viz_stat_shuffled_modularity_swarm.m
% Create swarm plots for shuffled modularity comparisons
%
% For peak_density_threshold = 0.9, cohort = "one"
% Creates swarm plots with 9 columns: node-none, node-peak_dense, node-all,
%                                      edge-none, edge-peak_dense, edge-all,
%                                      triangle-none, triangle-peak_dense, triangle-all

%% Setup
clear; close all; clc;

% Get repository root
repo_root = fcn_utils_detect_repo_root();

% Configuration
cohort = "one";
session = "LR";
peak_threshold = 0.95;
purity_threshold = 0.75;
peak_density_threshold = 0.9;
threshold_str = sprintf('%d', round(peak_density_threshold*100));

simplices = ["node", "edge", "triangle"];
conditions = ["none", sprintf("peak_dense_%s", threshold_str), "all"];
condition_labels = ["None", "Peak Dense", "All"];

% Define paths
data_dir = fullfile(repo_root, "data_pipeline", "shuffled_modularity");
output_dir = fullfile(repo_root, "output", "figures", "stat_shuffled_modularity");

% Create output directory
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    fprintf('Created output directory: %s\n', output_dir);
end

%% Load data for all simplices
fprintf('Loading data for cohort %s...\n', cohort);

simplex_data = struct();

for simplex = simplices
    delta_filename = sprintf('shuffled_modularity_mean_with_delta_%s_%s_%s_peak_%d_purity_%d.csv', ...
        simplex, cohort, session, round(peak_threshold*100), round(purity_threshold*100));
    delta_filepath = fullfile(data_dir, delta_filename);
    
    if ~exist(delta_filepath, 'file')
        error('Delta file not found: %s', delta_filepath);
    end
    
    simplex_data.(simplex) = readtable(delta_filepath, "FileType", "text", ...
        "TextType", "string", ...
        "VariableNamingRule", "preserve");
    
    fprintf('  Loaded %s: %d subjects\n', simplex, height(simplex_data.(simplex)));
end

%% Prepare data for plotting
fprintf('\nPreparing data for swarm plot...\n');

% Collect all data into vectors
all_values = [];
all_groups = [];
all_colors = [];

% Define colors for each simplex
simplex_colors = [
    0.2, 0.4, 0.7;   % Node: blue
    0.8, 0.3, 0.3;   % Edge: red
    0.3, 0.7, 0.3    % Triangle: green
];

% Define x-positions (grouping by simplex, with gaps)
x_positions = [];
x_tick_positions = [];
x_tick_labels = {};

x_pos = 1;
for s_idx = 1:length(simplices)
    simplex = simplices(s_idx);
    data = simplex_data.(simplex);
    
    for c_idx = 1:length(conditions)
        condition = conditions(c_idx);
        
        % Get modularity values for this condition
        values = data.(condition);
        
        % Remove missing values
        valid_idx = ~ismissing(values);
        values_clean = values(valid_idx);
        
        % Add to vectors
        all_values = [all_values; values_clean];
        all_groups = [all_groups; repmat(x_pos, length(values_clean), 1)];
        all_colors = [all_colors; repmat(simplex_colors(s_idx, :), length(values_clean), 1)];
        
        % Store x position and label
        x_positions = [x_positions, x_pos];
        x_tick_labels{end+1} = sprintf('%s\n%s', simplex, condition_labels(c_idx));
        
        x_pos = x_pos + 1;
    end
    
    % Store middle position for simplex label
    x_tick_positions = [x_tick_positions, x_positions(end-1)];
    
    % Add gap between simplices
    x_pos = x_pos + 0.5;
end

fprintf('Total data points: %d\n', length(all_values));
fprintf('Number of groups: %d\n', length(unique(all_groups)));

%% Create swarm plot
fprintf('\nCreating swarm plot...\n');

fig = figure('Position', [100, 100, 1400, 600]);

% Create swarm plot using custom function or scatter with jitter
% If you have swarmchart (R2020b+):
if exist('swarmchart', 'file')
    swarmchart(all_groups, all_values, 36, all_colors, 'filled', 'MarkerFaceAlpha', 0.6);
else
    % Manual jitter for older MATLAB versions
    hold on;
    for group = unique(all_groups)'
        idx = all_groups == group;
        y_vals = all_values(idx);
        n_points = length(y_vals);
        
        % Add jitter
        jitter_amount = 0.15;
        x_jitter = group + (rand(n_points, 1) - 0.5) * jitter_amount;
        
        scatter(x_jitter, y_vals, 36, all_colors(idx, :), 'filled', ...
                'MarkerFaceAlpha', 0.6);
    end
    hold off;
end

% Formatting
set(gca, 'XTick', x_positions, 'XTickLabel', x_tick_labels, ...
    'FontSize', 10, 'TickLabelInterpreter', 'none');
xtickangle(45);

ylabel('Modularity', 'FontSize', 14, 'FontWeight', 'bold');
title(sprintf('Shuffled Modularity Comparison (Cohort %s, Peak Density Threshold = %.2f)', ...
      cohort, peak_density_threshold), ...
      'FontSize', 16, 'FontWeight', 'bold');

grid on;
box on;

% Add vertical lines to separate simplices
hold on;
for s_idx = 1:(length(simplices)-1)
    separator_x = x_positions(s_idx*3) + 0.75;
    plot([separator_x, separator_x], ylim, 'k--', 'LineWidth', 1.5);
end
hold off;

% Add legend
legend_entries = arrayfun(@(s) sprintf('%s', s), simplices, 'UniformOutput', false);
legend(legend_entries, 'Location', 'best', 'FontSize', 12);

%% Add statistical annotations
fprintf('\nAdding statistical annotations...\n');

% Load statistical results
stat_filename = sprintf('stat_shuffled_modularity_ttest_all_%s.csv', threshold_str);
stat_filepath = fullfile(repo_root, "data_pipeline", "stat_shuffled_modularity", stat_filename);

if exist(stat_filepath, 'file')
    stat_results = readtable(stat_filepath, "FileType", "text", ...
        "TextType", "string", ...
        "VariableNamingRule", "preserve");
    
    % Filter for cohort one and within-simplex comparisons
    cohort_results = stat_results(stat_results.cohort == cohort, :);
    
    % Add significance markers above each group
    y_max = max(all_values);
    y_offset = (max(all_values) - min(all_values)) * 0.05;
    
    for s_idx = 1:length(simplices)
        simplex = simplices(s_idx);
        
        % Get results for this simplex
        simplex_results = cohort_results(cohort_results.test_type == "within_simplex" & ...
                                         cohort_results.simplex == simplex, :);
        
        if height(simplex_results) > 0
            % Find comparisons and add significance markers
            for row_idx = 1:height(simplex_results)
                comparison = simplex_results.comparison{row_idx};
                significance = simplex_results.significance_bonferroni{row_idx};
                
                if ~ismissing(significance) && strlength(significance) > 0
                    % Determine x positions for the comparison
                    % This requires parsing the comparison string
                    % For example: "peak_dense_90_vs_none"
                    
                    fprintf('  %s %s: %s\n', simplex, comparison, significance);
                end
            end
        end
    end
else
    warning('Statistical results file not found: %s', stat_filepath);
end

%% Save figure
output_filename = sprintf('swarm_shuffled_modularity_cohort_%s_threshold_%s.png', ...
                          cohort, threshold_str);
output_filepath = fullfile(output_dir, output_filename);

fprintf('\nSaving figure to: %s\n', output_filepath);
saveas(fig, output_filepath);

% Also save as vector format
output_filepath_pdf = strrep(output_filepath, '.png', '.pdf');
saveas(fig, output_filepath_pdf);

fprintf('\nSwarm plot creation complete!\n');
