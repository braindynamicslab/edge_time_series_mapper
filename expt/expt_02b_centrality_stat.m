% expt_02b_centrality_stat.m
% Statistical analysis of within-task centrality in peak-dense pure nodes
%
% This script:
%   1. Loads mapper node features and head motion data
%   2. Identifies pure nodes (purity >= threshold)
%   3. Identifies peak-dense pure nodes (subject-wise peak density quantile)
%   4. Performs two-sample t-test comparing centrality between peak-dense pure nodes and other pure nodes
%   5. Performs ANCOVA (LME) with head motion covariate
%   6. Applies Bonferroni correction for multiple comparisons
%   7. Saves results to CSV

%% Setup
clear; close all; clc;

% Get repository root
repo_root = fcn_utils_detect_repo_root();

%% Configuration
cohorts = ["one", "two"];
session = "LR";
simplex = "edge";
purity_threshold = 0.75;
peak_density_threshold = 0.9;  % Subject-wise quantile threshold

num_external_tests = 24;  % From expt_03c_shuffled_modularity_stat.m
num_tests = 26;  % Total including this analysis

% Define paths
data_dir = fullfile(repo_root, "data_pipeline", "mapper_node_features");
head_motion_dir = fullfile(repo_root, "data_pipeline_gitignore", "mean_head_motion");
output_dir = fullfile(repo_root, "data_pipeline", "stat_centrality");

% Create output directory if needed
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    fprintf('Created output directory: %s\n', output_dir);
end

output_filename = "stat_centrality.csv";
output_filepath = fullfile(output_dir, output_filename);

%% Load head motion data
head_motion_filename = sprintf('mean_head_motion_cohort_all_session_%s.csv', session);
head_motion_filepath = fullfile(head_motion_dir, head_motion_filename);

if ~exist(head_motion_filepath, 'file')
    error('Head motion file not found: %s', head_motion_filepath);
end

head_motion_data = readtable(head_motion_filepath, "FileType", "text", ...
    "TextType", "string", ...
    "VariableNamingRule", "preserve");

fprintf('Loaded head motion data: %d subjects\n', height(head_motion_data));

%% Preallocate results table
% 2 analyses per cohort × 2 cohorts = 4 rows
num_rows = 2 * numel(cohorts);

results_table = table('Size', [num_rows, 15], ...
    'VariableTypes', {'string', 'string', 'string', 'string', ...
                      'double', 'double', 'double', 'double', 'double', ...
                      'double', 'double', 'double', 'double', 'double', 'string'}, ...
    'VariableNames', {'cohort', 'session', 'analysis_type', 'comparison', ...
                      'num_na_in_either_samples', 'mean_peak_dense_pure', ...
                      'sd_peak_dense_pure', 'mean_pure_non_peak_dense', ...
                      'sd_pure_non_peak_dense', 't_statistic', ...
                      'degree_of_freedom', 'p_value', ...
                      'effect_size_cohens_d_or_coeff_estimate', ...
                      'standard_error', 'significance_bonferroni'});

row_idx = 1;

%% Process each cohort
for cohort = cohorts
    fprintf('\n========================================\n');
    fprintf('Processing cohort: %s\n', cohort);
    fprintf('========================================\n');
    
    % Load cohort data
    cohort_filename = sprintf('cohort_%s_session_%s.csv', cohort, session);
    cohort_filepath = fullfile(repo_root, "data_pipeline", "data_cohort", cohort_filename);
    
    if ~exist(cohort_filepath, 'file')
        error('Cohort file not found: %s', cohort_filepath);
    end
    
    cohort_data = readtable(cohort_filepath, "FileType", "text", ...
        "TextType", "string", ...
        "VariableNamingRule", "preserve");
    
    fprintf('Loaded cohort data: %d subjects\n', height(cohort_data));
    
    % Load mapper node features
    data_filename = sprintf('mapper_node_features_%s_%s_%s.csv', simplex, cohort, session);
    data_filepath = fullfile(data_dir, data_filename);
    
    if ~exist(data_filepath, 'file')
        error('Mapper node features file not found: %s', data_filepath);
    end
    
    data = readtable(data_filepath, "FileType", "text", ...
        "TextType", "string", ...
        "VariableNamingRule", "preserve");
    data.normalized_centrality = normalize(data.mapper_stat_within_task_centrallity);
    
    fprintf('Loaded mapper node features: %d rows\n', height(data));
    
    % Add is_pure_node column
    data.is_pure_node = data.mapper_stat_node_purity >= purity_threshold;
    
    % Preallocate new columns with NaN
    data.is_peak_dense_pure_node = nan(height(data), 1);
    data.mean_head_motion = nan(height(data), 1);
    
    % Get unique subjects
    unique_subjects = unique(data.subject);
    fprintf('Processing %d unique subjects\n', numel(unique_subjects));
    
    % Process each subject
    for subj_idx = 1:numel(unique_subjects)
        current_subject = unique_subjects(subj_idx);
        
        % Find rows for this subject
        subject_rows = data.subject == current_subject;
        
        % Extract peak density for this subject's nodes
        peak_density = data.amplitude_peak_density_peak_threshold_95(subject_rows);
        is_pure_node_subject = data.is_pure_node(subject_rows);
        
        % Compute quantile threshold for pure nodes only
        if sum(is_pure_node_subject) > 0
            pure_peak_density = peak_density(is_pure_node_subject);
            is_peak_dense_pure = is_pure_node_subject & (peak_density > quantile(pure_peak_density, peak_density_threshold));
            data.is_peak_dense_pure_node(subject_rows) = double(is_peak_dense_pure);
        else
            % No pure nodes for this subject
            data.is_peak_dense_pure_node(subject_rows) = 0;
        end
        
        % Find head motion for this subject
        head_motion_row = head_motion_data.subject == current_subject;
        
        if sum(head_motion_row) == 1
            subject_head_motion = head_motion_data.mean_head_motion(head_motion_row);
            data.mean_head_motion(subject_rows) = subject_head_motion;
        else
            warning('Head motion not found for subject %s', current_subject);
        end
    end
    
    fprintf('\nNode classification summary:\n');
    fprintf('  Total nodes: %d\n', height(data));
    fprintf('  Pure nodes: %d (%.1f%%)\n', sum(data.is_pure_node), ...
        100 * sum(data.is_pure_node) / height(data));
    fprintf('  Peak-dense pure nodes: %d (%.1f%%)\n', sum(data.is_peak_dense_pure_node == 1, 'omitnan'), ...
        100 * sum(data.is_peak_dense_pure_node == 1, 'omitnan') / height(data));
    fprintf('  Other pure nodes: %d (%.1f%%)\n', ...
        sum(data.is_pure_node & data.is_peak_dense_pure_node == 0, 'omitnan'), ...
        100 * sum(data.is_pure_node & data.is_peak_dense_pure_node == 0, 'omitnan') / height(data));
    
    %% Analysis 1: Two-sample t-test
    fprintf('\n--------------------------------------------------\n');
    fprintf('Analysis 1: Two-sample t-test (unequal variance)\n');
    fprintf('--------------------------------------------------\n');
    
    % Group 1: Peak-dense pure nodes
    group1_idx = data.is_peak_dense_pure_node == 1;
    group1_centrality = data.normalized_centrality(group1_idx);
    
    % Group 2: Other pure nodes (pure but not peak-dense)
    group2_idx = data.is_pure_node & data.is_peak_dense_pure_node == 0;
    group2_centrality = data.normalized_centrality(group2_idx);
    
    % Remove NaN values
    group1_centrality_clean = group1_centrality(~isnan(group1_centrality));
    group2_centrality_clean = group2_centrality(~isnan(group2_centrality));
    
    num_na = sum(isnan(group1_centrality)) + sum(isnan(group2_centrality));
    
    fprintf('  Group 1 (peak-dense pure): n = %d\n', numel(group1_centrality_clean));
    fprintf('  Group 2 (other pure): n = %d\n', numel(group2_centrality_clean));
    fprintf('  Missing values: %d\n', num_na);
    
    % Compute descriptive statistics
    mean_group1 = mean(group1_centrality_clean);
    sd_group1 = std(group1_centrality_clean);
    mean_group2 = mean(group2_centrality_clean);
    sd_group2 = std(group2_centrality_clean);
    
    fprintf('  Group 1: M = %.6f, SD = %.6f\n', mean_group1, sd_group1);
    fprintf('  Group 2: M = %.6f, SD = %.6f\n', mean_group2, sd_group2);
    
    % Perform two-sample t-test with unequal variance
    [h, p, ci, stats] = ttest2(group1_centrality_clean, group2_centrality_clean, ...
        'Vartype', 'unequal');
    
    % Compute Cohen's d with pooled variance
    n1 = numel(group1_centrality_clean);
    n2 = numel(group2_centrality_clean);
    pooled_sd = sqrt(((n1 - 1) * sd_group1^2 + (n2 - 1) * sd_group2^2) / (n1 + n2 - 2));
    cohens_d = (mean_group1 - mean_group2) / pooled_sd;
    
    % Get significance
    significance = fcn_stat_get_significance_asterisks(p * num_tests);
    
    fprintf('  t(%d) = %.4f, p = %.6f, d = %.4f %s\n', ...
        stats.df, stats.tstat, p, cohens_d, significance);
    
    % Fill results table
    results_table.cohort(row_idx) = cohort;
    results_table.session(row_idx) = session;
    results_table.analysis_type(row_idx) = "cohort_wide_t_test";
    results_table.comparison(row_idx) = "peak_dense_nodes_vs_other_pure_nodes";
    results_table.num_na_in_either_samples(row_idx) = num_na;
    results_table.mean_peak_dense_pure(row_idx) = mean_group1;
    results_table.sd_peak_dense_pure(row_idx) = sd_group1;
    results_table.mean_pure_non_peak_dense(row_idx) = mean_group2;
    results_table.sd_pure_non_peak_dense(row_idx) = sd_group2;
    results_table.t_statistic(row_idx) = stats.tstat;
    results_table.degree_of_freedom(row_idx) = stats.df;
    results_table.p_value(row_idx) = p;
    results_table.effect_size_cohens_d_or_coeff_estimate(row_idx) = cohens_d;
    results_table.standard_error(row_idx) = NaN;  % Not applicable for t-test
    results_table.significance_bonferroni(row_idx) = significance;
    
    row_idx = row_idx + 1;
    
    %% Analysis 2: ANCOVA with LME
    fprintf('\n--------------------------------------------------\n');
    fprintf('Analysis 2: ANCOVA (LME) with head motion covariate\n');
    fprintf('--------------------------------------------------\n');
    
    % Filter to pure nodes only
    pure_nodes_idx = data.is_pure_node;
    pure_data = data(pure_nodes_idx, :);
    
    fprintf('  Using %d pure nodes from %d subjects\n', ...
        height(pure_data), numel(unique(pure_data.subject)));
    
    % Remove rows with missing values in any required variable
    valid_idx = ~isnan(pure_data.mapper_stat_within_task_centrallity) & ...
                ~isnan(pure_data.is_peak_dense_pure_node) & ...
                ~isnan(pure_data.mean_head_motion);
    
    lme_data = pure_data(valid_idx, :);
    num_na_lme = sum(~valid_idx);
    
    fprintf('  Valid observations: %d\n', height(lme_data));
    fprintf('  Missing values: %d\n', num_na_lme);
    
    if height(lme_data) < 10
        warning('Insufficient data for LME analysis');
        
        % Fill with NaN
        results_table.cohort(row_idx) = cohort;
        results_table.session(row_idx) = session;
        results_table.analysis_type(row_idx) = "ANCOVA_LME";
        results_table.comparison(row_idx) = "coefficient_of_peak_dense_pure_nodes";
        results_table.num_na_in_either_samples(row_idx) = num_na_lme;
        results_table.mean_peak_dense_pure(row_idx) = NaN;
        results_table.sd_peak_dense_pure(row_idx) = NaN;
        results_table.mean_pure_non_peak_dense(row_idx) = NaN;
        results_table.sd_pure_non_peak_dense(row_idx) = NaN;
        results_table.t_statistic(row_idx) = NaN;
        results_table.degree_of_freedom(row_idx) = NaN;
        results_table.p_value(row_idx) = NaN;
        results_table.effect_size_cohens_d_or_coeff_estimate(row_idx) = NaN;
        results_table.standard_error(row_idx) = NaN;
        results_table.significance_bonferroni(row_idx) = missing;
        
        row_idx = row_idx + 1;
        continue;
    end
    
    % Fit LME model
    % mapper_stat_within_task_centrallity ~ 1 + is_peak_dense_pure_node + mean_head_motion + (1 | subject)
    lme_formula = 'normalized_centrality ~ 1 + is_peak_dense_pure_node + mean_head_motion + (1 | subject)';
    
fprintf('  Fitting model: %s\n', lme_formula);
    
    try
        lme_model = fitlme(lme_data, lme_formula);
        
        % Extract coefficient for is_peak_dense_pure_node
        coef_table = lme_model.Coefficients;
        predictor_row = strcmp(coef_table.Name, 'is_peak_dense_pure_node');
        
        if ~any(predictor_row)
            error('Coefficient for is_peak_dense_pure_node not found in model');
        end
        
        coefficient = coef_table.Estimate(predictor_row);
        standard_error = coef_table.SE(predictor_row);
        t_statistic = coef_table.tStat(predictor_row);
        df = coef_table.DF(predictor_row);
        p_value = coef_table.pValue(predictor_row);
        
        % Get significance
        significance = fcn_stat_get_significance_asterisks(p_value * num_tests);
        
        fprintf('  Coefficient: %.6f\n', coefficient);
        fprintf('  SE: %.6f\n', standard_error);
        fprintf('  t(%d) = %.4f, p = %.6f %s\n', df, t_statistic, p_value, significance);
        
        % Fill results table
        results_table.cohort(row_idx) = cohort;
        results_table.session(row_idx) = session;
        results_table.analysis_type(row_idx) = "ANCOVA_LME";
        results_table.comparison(row_idx) = "coefficient_of_peak_dense_pure_nodes";
        results_table.num_na_in_either_samples(row_idx) = num_na_lme;
        results_table.mean_peak_dense_pure(row_idx) = NaN;  % Not applicable for LME
        results_table.sd_peak_dense_pure(row_idx) = NaN;
        results_table.mean_pure_non_peak_dense(row_idx) = NaN;
        results_table.sd_pure_non_peak_dense(row_idx) = NaN;
        results_table.t_statistic(row_idx) = t_statistic;
        results_table.degree_of_freedom(row_idx) = df;
        results_table.p_value(row_idx) = p_value;
        results_table.effect_size_cohens_d_or_coeff_estimate(row_idx) = coefficient;
        results_table.standard_error(row_idx) = standard_error;
        results_table.significance_bonferroni(row_idx) = significance;
        
    catch ME
        warning('LME fitting failed: %s', ME.message);
        
        % Fill with NaN
        results_table.cohort(row_idx) = cohort;
        results_table.session(row_idx) = session;
        results_table.analysis_type(row_idx) = "ANCOVA_LME";
        results_table.comparison(row_idx) = "coefficient_of_peak_dense_pure_nodes";
        results_table.num_na_in_either_samples(row_idx) = num_na_lme;
        results_table.mean_peak_dense_pure(row_idx) = NaN;
        results_table.sd_peak_dense_pure(row_idx) = NaN;
        results_table.mean_pure_non_peak_dense(row_idx) = NaN;
        results_table.sd_pure_non_peak_dense(row_idx) = NaN;
        results_table.t_statistic(row_idx) = NaN;
        results_table.degree_of_freedom(row_idx) = NaN;
        results_table.p_value(row_idx) = NaN;
        results_table.effect_size_cohens_d_or_coeff_estimate(row_idx) = NaN;
        results_table.standard_error(row_idx) = NaN;
        results_table.significance_bonferroni(row_idx) = missing;
    end
    
    row_idx = row_idx + 1;
end

%% Save results
fprintf('\n========================================\n');
fprintf('Saving results\n');
fprintf('========================================\n');
fprintf('Output file: %s\n', output_filepath);

writetable(results_table, output_filepath);

fprintf('Total rows: %d\n', height(results_table));
fprintf('\nAnalysis complete!\n');