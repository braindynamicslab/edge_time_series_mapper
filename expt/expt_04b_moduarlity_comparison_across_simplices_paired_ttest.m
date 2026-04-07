% expt_stat_modularity_comparison_paired_ttest.m
% Perform paired t-tests comparing modularity across simplex levels
%
% This script:
%   1. Reads configuration for analysis conditions
%   2. Performs pairwise paired t-tests (edge vs node, edge vs triangle, triangle vs node)
%   3. Applies Bonferroni correction for multiple comparisons
%   4. Saves results with test statistics and significance markers

%% Setup
clear; close all; clc;

% Get repository root
repo_root = fcn_utils_detect_repo_root();

% Define paths
config_file = fullfile(repo_root, "data_raw", "data_stat_config", ...
                       "config_modularity_comparison_paired_ttest.csv");
output_dir = fullfile(repo_root, "data_pipeline", "stat_modularity_comparison");
output_file = fullfile(output_dir, "stat_modularity_comparison_paired_ttest.csv");

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
num_schaefer200x7 = sum(strcmp(config.parcellation, "schaefer200x7"));
num_tests = 3 * num_schaefer100x7 + num_schaefer200x7;

fprintf('  schaefer100x7 conditions: %d (3 tests each = %d total)\n', ...
        num_schaefer100x7, 3 * num_schaefer100x7);
fprintf('  schaefer200x7 conditions: %d (1 test each = %d total)\n', ...
        num_schaefer200x7, num_schaefer200x7);
fprintf('Total number of tests: %d\n', num_tests);
fprintf('Bonferroni-corrected alpha: %.6f\n\n', 0.05 / num_tests);

%% Preallocate results table
results_table = table('Size', [num_tests, 13], ...
    'VariableTypes', {'string', 'string', 'string', 'string', 'string', 'string', ...
                      'double', 'double', ...
                      'double', 'double', 'double', 'double', 'string'}, ...
    'VariableNames', {'condition', 'cohort', 'session', 'parcellation', ...
                      'simplex_1', 'simplex_2', ...
                      'num_na_simplex_1', 'num_na_simplex_2', ...
                      't_statistic', 'degree_of_freedom', ...
                      'p_value', 'cohens_d', 'significance_bonferroni'});

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
    
    % Determine which simplexes to analyze
    if strcmp(parcellation, "schaefer100x7")
        simplexes = ["node", "edge", "triangle"];
        comparisons = [
            "edge", "node";
            "edge", "triangle";
            "triangle", "node"
        ];
    else  % schaefer200x7
        simplexes = ["node", "edge"];
        comparisons = [
            "edge", "node"
        ];
    end
    
    % Check if file exists
    file_exists = exist(data_filepath, 'file');
    
    if ~file_exists
        warning('File not found: %s', data_filepath);
        
        % Add rows with NA for all comparisons
        for comp_idx = 1:size(comparisons, 1)
            simplex_1 = comparisons(comp_idx, 1);
            simplex_2 = comparisons(comp_idx, 2);
            
            results_table.condition(row_idx) = condition;
            results_table.cohort(row_idx) = cohort;
            results_table.session(row_idx) = session;
            results_table.parcellation(row_idx) = parcellation;
            results_table.simplex_1(row_idx) = simplex_1;
            results_table.simplex_2(row_idx) = simplex_2;
            results_table.num_na_simplex_1(row_idx) = NaN;
            results_table.num_na_simplex_2(row_idx) = NaN;
            results_table.t_statistic(row_idx) = NaN;
            results_table.degree_of_freedom(row_idx) = NaN;
            results_table.p_value(row_idx) = NaN;
            results_table.cohens_d(row_idx) = NaN;
            results_table.significance_bonferroni(row_idx) = missing;
            
            row_idx = row_idx + 1;
        end
        
        fprintf('\n');
        continue;
    end
    
    % Read data
    data = readtable(data_filepath, "FileType", "text", ...
                     "TextType", "string", ...
                     "VariableNamingRule", "preserve");
    
    % Extract modularity columns and check for NAs
    fprintf('  Extracting modularity columns:\n');
    modularity_data = struct();
    num_na_by_simplex = struct();
    
    for simplex = simplexes
        col_name = strcat(simplex, "_modularity");
        
        if ~ismember(col_name, data.Properties.VariableNames)
            error('Column not found: %s', col_name);
        end
        
        modularity_data.(simplex) = data.(col_name);
        num_na_by_simplex.(simplex) = sum(ismissing(modularity_data.(simplex)));
        fprintf('    %s: %d NAs out of %d observations\n', ...
                col_name, num_na_by_simplex.(simplex), height(data));
    end
    fprintf('\n');
    
    % Perform pairwise comparisons
    for comp_idx = 1:size(comparisons, 1)
        simplex_1 = comparisons(comp_idx, 1);
        simplex_2 = comparisons(comp_idx, 2);
        
        fprintf('  Comparing %s vs %s:\n', simplex_1, simplex_2);
        
        % Get data for both simplexes
        data_1 = modularity_data.(simplex_1);
        data_2 = modularity_data.(simplex_2);
        
        % Get NA counts for each simplex
        num_na_1 = num_na_by_simplex.(simplex_1);
        num_na_2 = num_na_by_simplex.(simplex_2);
        
        % Remove pairs with missing data
        valid_idx = ~ismissing(data_1) & ~ismissing(data_2);
        data_1_clean = data_1(valid_idx);
        data_2_clean = data_2(valid_idx);
        
        num_valid = sum(valid_idx);
        fprintf('    Valid pairs (no NAs): %d\n', num_valid);
        
        % Fill in identifying information and NA counts
        results_table.condition(row_idx) = condition;
        results_table.cohort(row_idx) = cohort;
        results_table.session(row_idx) = session;
        results_table.parcellation(row_idx) = parcellation;
        results_table.simplex_1(row_idx) = simplex_1;
        results_table.simplex_2(row_idx) = simplex_2;
        results_table.num_na_simplex_1(row_idx) = num_na_1;
        results_table.num_na_simplex_2(row_idx) = num_na_2;
        
        if num_valid < 2
            warning('Insufficient valid pairs for comparison (%d pairs)', num_valid);
            
            % Fill with NA
            results_table.t_statistic(row_idx) = NaN;
            results_table.degree_of_freedom(row_idx) = NaN;
            results_table.p_value(row_idx) = NaN;
            results_table.cohens_d(row_idx) = NaN;
            results_table.significance_bonferroni(row_idx) = missing;
        else
            % Compute differences
            differences = data_1_clean - data_2_clean;
            
            % Paired t-test
            [~, p_value, ~, stats] = ttest(data_1_clean, data_2_clean);
            t_statistic = stats.tstat;
            df = stats.df;
            
            % Cohen's d for paired samples
            mean_diff = mean(differences);
            std_diff = std(differences);
            cohens_d = mean_diff / std_diff;
            significance = fcn_stat_get_significance_asterisks(p_value * num_tests);
            
            fprintf('    t(%d) = %.4f, p = %.6f, d = %.4f, sig = %s\n', ...
                    df, t_statistic, p_value, cohens_d, significance);
            
            % Fill in statistics
            results_table.t_statistic(row_idx) = t_statistic;
            results_table.degree_of_freedom(row_idx) = df;
            results_table.p_value(row_idx) = p_value;
            results_table.cohens_d(row_idx) = cohens_d;
            results_table.significance_bonferroni(row_idx) = significance;
        end
        
        row_idx = row_idx + 1;
    end
    
    fprintf('\n');
end

%% Save results
fprintf('Saving results to: %s\n', output_file);
writetable(results_table, output_file);

fprintf('\nAnalysis complete!\n');
fprintf('Total rows in output: %d\n', height(results_table));