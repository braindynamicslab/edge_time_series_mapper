% polish_centrality_table.m
% Convert stat_centrality.csv to polished publication format tables

%% Setup
clear; close all; clc;

% Detect repository root
repo_root = fcn_utils_detect_repo_root();

% Load configuration
config = fcn_utils_get_config();

% Define file paths
base_dir = fullfile(repo_root, "data_pipeline", "stat_centrality");
input_file = fullfile(base_dir, "stat_centrality.csv");
output_file_ttest = fullfile(base_dir, "stat_centrality_ttest_polished.csv");
output_file_ancova = fullfile(base_dir, "stat_centrality_ancova_lme_polished.csv");

%% Read data
fprintf('Reading input file...\n');
data = readtable(input_file, "TextType", "string", ...
                 "VariableNamingRule", "preserve");

fprintf('  Rows: %d\n', height(data));
fprintf('  Columns: %d\n\n', width(data));

%% Validate input columns
fprintf('Validating input columns...\n');

expected_cols = ["cohort", "session", "analysis_type", "comparison", ...
                 "num_na_in_either_samples", "mean_peak_dense_pure", ...
                 "sd_peak_dense_pure", "mean_pure_non_peak_dense", ...
                 "sd_pure_non_peak_dense", "t_statistic", "degree_of_freedom", ...
                 "p_value", "effect_size_cohens_d_or_coeff_estimate", ...
                 "standard_error", "significance_bonferroni"];

actual_cols = string(data.Properties.VariableNames);

% Check if all expected columns are present
missing_cols = setdiff(expected_cols, actual_cols);
if ~isempty(missing_cols)
    error('Missing columns: %s', strjoin(missing_cols, ', '));
end

% Check for unexpected columns
extra_cols = setdiff(actual_cols, expected_cols);
if ~isempty(extra_cols)
    warning('Unexpected columns found: %s', strjoin(extra_cols, ', '));
end

fprintf('  All expected columns present.\n\n');

%% Split data by analysis type
fprintf('Splitting data by analysis type...\n');

data_ttest = data(strcmp(data.analysis_type, "cohort_wide_t_test"), :);
data_ancova = data(strcmp(data.analysis_type, "ANCOVA_LME"), :);

fprintf('  T-test rows: %d\n', height(data_ttest));
fprintf('  ANCOVA-LME rows: %d\n\n', height(data_ancova));

%% Process t-test table
fprintf('========================================\n');
fprintf('Processing t-test table\n');
fprintf('========================================\n\n');

process_ttest_table(data_ttest, output_file_ttest, config);

%% Process ANCOVA-LME table
fprintf('\n========================================\n');
fprintf('Processing ANCOVA-LME table\n');
fprintf('========================================\n\n');

process_ancova_lme_table(data_ancova, output_file_ancova, config);

fprintf('\n========================================\n');
fprintf('All processing complete!\n');
fprintf('========================================\n');

%% Function: Process t-test table
function process_ttest_table(data, output_file, config)
    fprintf('Formatting t-test table...\n');
    
    % Remove irrelevant columns
    fprintf('  Removing columns: num_na_in_either_samples, analysis_type, standard_error...\n');
    data = removevars(data, ["num_na_in_either_samples", "comparison", "analysis_type", "standard_error"]);
    
    % Format cohort column
    fprintf('  Formatting cohort column...\n');
    data.cohort = format_cohort_values(data.cohort, config);
    
    % Format numerical columns (3 significant figures, including DF for unequal-variance t-test)
    fprintf('  Formatting numerical columns to 3 significant figures...\n');
    
    numerical_cols = ["mean_peak_dense_pure", "sd_peak_dense_pure", ...
                      "mean_pure_non_peak_dense", "sd_pure_non_peak_dense", ...
                      "t_statistic", "degree_of_freedom", "p_value", ...
                      "effect_size_cohens_d_or_coeff_estimate"];
    
    for col_idx = 1:numel(numerical_cols)
        col_name = numerical_cols(col_idx);
        data.(col_name) = format_to_3_sig_figs(data.(col_name));
    end
    
    % Rename columns
    fprintf('  Renaming columns...\n');
    
    new_column_names = ["Co-hort", "Ses-sion", ...
                        "Mean (peak-dense pure nodes)", "SD (peak-dense pure nodes)", ...
                        "Mean (other pure nodes)", "SD (other pure nodes)", ...
                        "t-stat", "DF", "p-value", "Cohen's d", ...
                        "Sig (Bonfe-rroni corr)"];
    
    data.Properties.VariableNames = new_column_names;
    
    % Save polished table
    fprintf('  Saving polished table...\n');
    writetable(data, output_file);
    
    fprintf('Done!\n');
    fprintf('Output file: %s\n', output_file);
end

%% Function: Process ANCOVA-LME table
function process_ancova_lme_table(data, output_file, config)
    fprintf('Formatting ANCOVA-LME table...\n');
    
    % Remove irrelevant columns
    fprintf('  Removing columns: num_na_in_either_samples, analysis_type, mean_peak_dense_pure, sd_peak_dense_pure, mean_pure_non_peak_dense, sd_pure_non_peak_dense...\n');
    data = removevars(data, ["num_na_in_either_samples", "comparison", "analysis_type", ...
                             "mean_peak_dense_pure", "sd_peak_dense_pure", ...
                             "mean_pure_non_peak_dense", "sd_pure_non_peak_dense"]);
    
    % Format cohort column
    fprintf('  Formatting cohort column...\n');
    data.cohort = format_cohort_values(data.cohort, config);
    
    % Format numerical columns (3 significant figures)
    fprintf('  Formatting numerical columns to 3 significant figures...\n');
    
    numerical_cols = ["t_statistic", "p_value", ...
                      "effect_size_cohens_d_or_coeff_estimate", "standard_error"];
    
    for col_idx = 1:numel(numerical_cols)
        col_name = numerical_cols(col_idx);
        data.(col_name) = format_to_3_sig_figs(data.(col_name));
    end
    
    % Rename columns
    fprintf('  Renaming columns...\n');
    
    new_column_names = ["Cohort", "Session", ...
                        "t-stat", "DF", "p-value", "Coef", "SE", ...
                        "Sig (Bonferroni corr)"];
    
    data.Properties.VariableNames = new_column_names;

    data = data(:, ["Cohort", "Session", ...
                        "Coef", "SE", "t-stat", "DF", "p-value", ...
                        "Sig (Bonferroni corr)"]);
    
    % Save polished table
    fprintf('  Saving polished table...\n');
    writetable(data, output_file);
    
    fprintf('Done!\n');
    fprintf('Output file: %s\n', output_file);
end

%% Helper function: Format cohort values
function formatted_cohorts = format_cohort_values(cohorts, config)
    % Format cohort values using config.var_dict
    %
    % Inputs:
    %   cohorts - String array of cohort values
    %   config - Configuration struct with var_dict field
    %
    % Outputs:
    %   formatted_cohorts - String array with formatted values
    
    formatted_cohorts = strings(size(cohorts));
    
    for idx = 1:numel(cohorts)
        cohort = cohorts(idx);
        
        if strcmp(cohort, "one")
            formatted_cohorts(idx) = config.var_dict.cohort_one_short;
        elseif strcmp(cohort, "two")
            formatted_cohorts(idx) = config.var_dict.cohort_two_short;
        elseif strcmp(cohort, "all")
            formatted_cohorts(idx) = config.var_dict.cohort_all;
        else
            warning('Unknown cohort value: %s', cohort);
            formatted_cohorts(idx) = cohort;
        end
    end
end

%% Helper function: Format to 3 significant figures
function formatted = format_to_3_sig_figs(values)
    % Format numeric array to 3 significant figures as strings
    %
    % Inputs:
    %   values - Numeric array
    %
    % Outputs:
    %   formatted - String array with 3 sig figs
    
    formatted = strings(size(values));
    
    for idx = 1:numel(values)
        if isnan(values(idx))
            formatted(idx) = "NaN";
        else
            formatted(idx) = sprintf("%.3g", values(idx));
        end
    end
end