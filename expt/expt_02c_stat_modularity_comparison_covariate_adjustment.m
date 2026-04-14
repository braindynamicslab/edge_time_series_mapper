% expt_04c_stat_modularity_comparison_covariate_adjustment.m
% Fit linear mixed-effects models with covariate adjustment for modularity comparison
%
% This script:
%   1. Reads configuration for analysis conditions
%   2. Reshapes data from wide to long format
%   3. Fits mixed-effects model: modularity ~ simplex_type + num_nodes + num_edges + (1|subject)
%   4. Tests: edge vs node, triangle vs node, edge vs triangle
%   5. Applies Bonferroni correction for multiple comparisons

%% Setup
clear; close all; clc;

% Get repository root
repo_root = fcn_utils_detect_repo_root();

% Define paths
config_file = fullfile(repo_root, "data_raw", "data_stat_config", ...
                       "config_modularity_comparison_covariate_adjustment.csv");
output_dir = fullfile(repo_root, "data_pipeline", "stat_modularity_comparison");
output_file = fullfile(output_dir, "stat_modularity_comparison_covariate_adjustment.csv");

% Create output directory
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    fprintf('Created output directory: %s\n', output_dir);
end

%% Load configuration
fprintf('Loading configuration...\n');
config = readtable(config_file, "FileType", "text", ...
                   "TextType", "string", ...
                   "VariableNamingRule", "preserve");

num_conditions = height(config);
fprintf('Found %d conditions to analyze\n\n', num_conditions);

%% Compute number of tests for Bonferroni correction
fprintf('Computing number of tests for Bonferroni correction...\n');

num_schaefer100x7 = sum(strcmp(config.parcellation, "schaefer100x7"));
num_tests = 3 * num_schaefer100x7;

fprintf('  schaefer100x7 conditions: %d (3 tests each = %d total)\n', ...
        num_schaefer100x7, num_tests);
fprintf('Total number of tests: %d\n', num_tests);
fprintf('Bonferroni-corrected alpha: %.6f\n\n', 0.05 / num_tests);

%% Preallocate results table
results_table = table('Size', [num_tests, 11], ...
    'VariableTypes', {'string', 'string', 'string', 'string', 'string', ...
                      'double', 'double', 'double', 'double', 'double', 'string'}, ...
    'VariableNames', {'condition', 'cohort', 'session', 'parcellation', 'simplices', ...
                      'coefficient', 'standard_error', 't_statistic', 'degree_of_freedom', ...
                      'p_value', 'significance_bonferroni'});

%% Process each condition
row_idx = 1;

for config_idx = 1:num_conditions
    condition = config.condition(config_idx);
    cohort = config.cohort(config_idx);
    session = config.session(config_idx);
    parcellation = config.parcellation(config_idx);
    
    fprintf('Processing: condition=%s, cohort=%s, session=%s, parcellation=%s\n', ...
            condition, cohort, session, parcellation);
    
    % Construct data filename
    data_filename = sprintf("simplex_mapper_%s_cohort_%s_%s_%s.csv", ...
                            condition, cohort, session, parcellation);
    data_filepath = fullfile(repo_root, "data_pipeline", "simplex_mappers", data_filename);
    
    % Define test labels
    test_labels = ["edge-node", "triangle-node", "edge-triangle"];
    num_tests_condition = numel(test_labels);
    
    % Fill identifying information for all tests from this condition
    results_table.condition(row_idx:row_idx+num_tests_condition-1) = condition;
    results_table.cohort(row_idx:row_idx+num_tests_condition-1) = cohort;
    results_table.session(row_idx:row_idx+num_tests_condition-1) = session;
    results_table.parcellation(row_idx:row_idx+num_tests_condition-1) = parcellation;
    results_table.simplices(row_idx:row_idx+num_tests_condition-1) = test_labels';
    
    % Check if file exists
    if ~exist(data_filepath, 'file')
        warning('File not found: %s\nSkipping...', data_filepath);
        row_idx = row_idx + num_tests_condition;
        fprintf('\n');
        continue;
    end
    
    % Read wide format data
    data_wide = readtable(data_filepath, "FileType", "text", ...
                          "TextType", "string", ...
                          "VariableNamingRule", "preserve");
    
    fprintf('  Loaded data: %d subjects\n', height(data_wide));
    
    %% Convert to long format (vectorized)
    fprintf('  Converting to long format...\n');
    
    simplexes = ["node", "edge", "triangle"];
    num_subjects = height(data_wide);
    num_simplexes = numel(simplexes);
    
    % Vectorized construction of long format table
    subject_long = repelem(data_wide.subject, num_simplexes);
    
    % Stack modularity, num_nodes, num_edges for all simplexes
    modularity_long = [data_wide.node_modularity; data_wide.edge_modularity; data_wide.triangle_modularity];
    num_nodes_long = [data_wide.node_num_nodes; data_wide.edge_num_nodes; data_wide.triangle_num_nodes];
    num_edges_long = [data_wide.node_num_edges; data_wide.edge_num_edges; data_wide.triangle_num_edges];
    
    % Create simplex labels (vectorized) - corrected
    simplex_long = repmat(simplexes, num_subjects, 1);
    simplex_long = simplex_long(:);  % Flatten to column vector
    
    % Create indicator variables
    is_edge_time_series = double(simplex_long == "edge");
    is_triangle_time_series = double(simplex_long == "triangle");
    
    % Assemble long format table
    data_long = table(subject_long, modularity_long, num_nodes_long, num_edges_long, ...
                      is_edge_time_series, is_triangle_time_series, ...
                      'VariableNames', {'subject', 'modularity', 'num_nodes', 'num_edges', ...
                                        'is_edge_time_series', 'is_triangle_time_series'});
    
    fprintf('  Long format: %d rows (%d subjects x %d simplexes)\n', ...
            height(data_long), num_subjects, num_simplexes);
    
    % Check for missing data
    num_missing = sum(any(ismissing(data_long), 2));
    fprintf('  Rows with any missing data: %d out of %d\n', num_missing, height(data_long));
    
    %% Fit mixed-effects model
    fprintf('  Fitting mixed-effects model...\n');
    
    formula = 'modularity ~ 1 + is_edge_time_series + is_triangle_time_series + num_nodes + num_edges + (1 | subject)';
    fprintf('  Formula: %s\n\n', formula);
    
    try
        mdl = fitlme(data_long, formula);
        fprintf('  Model fitted successfully\n\n');
    catch ME
        warning('Failed to fit model: %s', ME.message);
        row_idx = row_idx + num_tests_condition;
        fprintf('\n');
        continue;
    end
    
    %% Extract model coefficients
    [beta, ~, stats] = fixedEffects(mdl);
    coeff_names = mdl.CoefficientNames;
    covB = mdl.CoefficientCovariance;
    
    % Find coefficient indices
    edge_idx = find(strcmp(coeff_names, 'is_edge_time_series'));
    triangle_idx = find(strcmp(coeff_names, 'is_triangle_time_series'));
    
    %% Perform tests and fill results

    stat_cols = ["coefficient", "standard_error", "t_statistic", "degree_of_freedom", ...
                          "p_value", "significance_bonferroni"]
    
    % Test 1: Edge vs Node
    test_result = fcn_stats_coefficient_test(beta, stats, edge_idx, "edge-node", num_tests);
    results_table(row_idx, 6:11) = test_result;
    row_idx = row_idx + 1;
    
    % Test 2: Triangle vs Node
    test_result = fcn_stats_coefficient_test(beta, stats, triangle_idx, "triangle-node", num_tests);
    results_table(row_idx, 6:11) = test_result;
    row_idx = row_idx + 1;
    
    % Test 3: Edge vs Triangle (contrast)
    H = zeros(1, numel(beta));
    H(edge_idx) = 1;
    H(triangle_idx) = -1;
    
    test_result = fcn_stats_contrast_test(mdl, beta, covB, H, "edge-triangle", num_tests);
    results_table(row_idx, 6:11) = test_result;
    row_idx = row_idx + 1;
    
    fprintf('\n');
end

%% Save results
fprintf('Saving results to: %s\n', output_file);
writetable(results_table, output_file);

fprintf('\nAnalysis complete!\n');
fprintf('Total rows in output: %d\n', height(results_table));

%% Helper

function test_result = fcn_stats_coefficient_test(beta, stats, coeff_idx, test_label, num_tests_total)
    % Perform coefficient test and return results as table row
    %
    % Inputs:
    %   beta - Fixed effects estimates
    %   stats - Stats structure from fixedEffects
    %   coeff_idx - Index of coefficient to test
    %   test_label - Label for this test (e.g., "edge-node")
    %   num_tests_total - Total number of tests for Bonferroni correction
    %
    % Outputs:
    %   test_result - Single-row table with columns: coeff, standard_error, 
    %                 t_statistic, degree_of_freedom, p_value, significance_bonferroni
    
    % Extract statistics
    coeff = beta(coeff_idx);
    se = stats.SE(coeff_idx);
    t_stat = stats.tStat(coeff_idx);
    
    df = stats.DF(coeff_idx);
    p_value = stats.pValue(coeff_idx);
    p_bonferroni = p_value * num_tests_total;
    
    % Print results
    fprintf('  Test: %s\n', test_label);
    fprintf('    b = %.6f, SE = %.6f, t(%.1f) = %.4f, p = %.6f, p_bonf = %.6f\n', ...
            coeff, se, df, t_stat, p_value, p_bonferroni);
    
    % Create result table
    test_result = table(coeff, se, t_stat, df, p_value, fcn_stat_get_significance_asterisks(p_bonferroni), ...
        'VariableNames', {'coefficient', 'standard_error', 't_statistic', 'degree_of_freedom', ...
                          'p_value', 'significance_bonferroni'});
end

function test_result = fcn_stats_contrast_test(mdl, beta, covB, H, test_label, num_tests_total)
    % Perform contrast test and return results as table row
    %
    % Inputs:
    %   mdl - Fitted linear mixed-effects model
    %   beta - Fixed effects estimates
    %   covB - Covariance matrix of fixed effects
    %   H - Contrast matrix (row vector)
    %   test_label - Label for this test (e.g., "edge-triangle")
    %   num_tests_total - Total number of tests for Bonferroni correction
    %
    % Outputs:
    %   test_result - Single-row table with columns: coeff, standard_error, 
    %                 t_statistic, degree_of_freedom, p_value, significance_bonferroni
    
    % Compute contrast statistics
    coeff = H * beta;
    se = sqrt(H * covB * H');
    t_stat = coeff / se;
    
    % Get p-value and DF from coefTest
    [p_value, ~, ~, df] = coefTest(mdl, H);
    p_bonferroni = p_value * num_tests_total;
    
    % Print results
    fprintf('  Test: %s\n', test_label);
    fprintf('    b = %.6f, SE = %.6f, t(%.1f) = %.4f, p = %.6f, p_bonf = %.6f\n', ...
            coeff, se, df, t_stat, p_value, p_bonferroni);
    
    % Create result table
    test_result = table(coeff, se, t_stat, df, p_value, fcn_stat_get_significance_asterisks(p_bonferroni), ...
        'VariableNames', {'coefficient', 'standard_error', 't_statistic', 'degree_of_freedom', ...
                          'p_value', 'significance_bonferroni'});
end