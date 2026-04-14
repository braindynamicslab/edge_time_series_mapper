% polish_modularity_comparison_table.m
% Convert stat_modularity_comparison CSV files to polished publication format

%% Setup
clear; close all; clc;

% Detect repository root
repo_root = fcn_utils_detect_repo_root();

% Load configuration
config = fcn_utils_get_config();

% Define base directory
base_dir = fullfile(repo_root, "data_pipeline", "stat_modularity_comparison");

%% Process paired t-test table
fprintf('========================================\n');
fprintf('Processing paired t-test table\n');
fprintf('========================================\n\n');

input_file_1 = fullfile(base_dir, "stat_modularity_comparison_paired_ttest.csv");
output_file_1 = fullfile(base_dir, "stat_modularity_comparison_paired_ttest_polished.csv");

process_paired_ttest_table(input_file_1, output_file_1, config);

%% Process covariate adjustment table
fprintf('\n========================================\n');
fprintf('Processing covariate adjustment table\n');
fprintf('========================================\n\n');

input_file_2 = fullfile(base_dir, "stat_modularity_comparison_covariate_adjustment.csv");
output_file_2 = fullfile(base_dir, "stat_modularity_comparison_covariate_adjustment_polished.csv");

process_covariate_adjustment_table(input_file_2, output_file_2, config);

fprintf('\n========================================\n');
fprintf('All processing complete!\n');
fprintf('========================================\n');

%% Function: Process paired t-test table
function process_paired_ttest_table(input_file, output_file, config)
    % Read data
    fprintf('Reading input file...\n');
    data = readtable(input_file, "TextType", "string", ...
                     "VariableNamingRule", "preserve");
    
    fprintf('  Rows: %d\n', height(data));
    fprintf('  Columns: %d\n\n', width(data));
    
    % Validate input columns
    fprintf('Validating input columns...\n');
    
    expected_cols = ["condition", "cohort", "session", "parcellation", ...
                     "simplex_1", "simplex_2", "num_na_simplex_1", "num_na_simplex_2", ...
                     "t_statistic", "degree_of_freedom", "p_value", "cohens_d", ...
                     "significance_bonferroni"];
    
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
    
    % Remove unwanted columns
    fprintf('Removing columns: num_na_simplex_1, num_na_simplex_2...\n');
    data = removevars(data, ["num_na_simplex_1", "num_na_simplex_2"]);
    
    % Format condition column
    fprintf('Formatting condition column...\n');
    data.condition = format_condition_values(data.condition);
    
    % Format cohort column
    fprintf('Formatting cohort column...\n');
    data.cohort = format_cohort_values(data.cohort, config);
    
    % Format numerical columns (3 significant figures)
    fprintf('Formatting numerical columns to 3 significant figures...\n');
    
    numerical_cols = ["t_statistic", "degree_of_freedom", "p_value", "cohens_d"];
    
    for col_idx = 1:numel(numerical_cols)
        col_name = numerical_cols(col_idx);
        data.(col_name) = format_to_3_sig_figs(data.(col_name));
    end
    
    % Rename columns
    fprintf('Renaming columns...\n');
    
    new_column_names = ["Condition", "Co-hort", "Ses-sion", "Parcellation", ...
                        "Sim-plex 1", "Sim-plex 2", "t-stat", "DF", "p-value", ...
                        "Cohen's d", "Sig (Bonfe-rroni corr)"];
    
    data.Properties.VariableNames = new_column_names;
    
    % Save polished table
    fprintf('Saving polished table...\n');
    writetable(data, output_file);
    
    fprintf('Done!\n');
    fprintf('Output file: %s\n', output_file);
end

%% Function: Process covariate adjustment table
function process_covariate_adjustment_table(input_file, output_file, config)
    % Read data
    fprintf('Reading input file...\n');
    data = readtable(input_file, "TextType", "string", ...
                     "VariableNamingRule", "preserve");
    
    fprintf('  Rows: %d\n', height(data));
    fprintf('  Columns: %d\n\n', width(data));
    
    % Validate input columns
    fprintf('Validating input columns...\n');
    
    expected_cols = ["condition", "cohort", "session", "parcellation", ...
                     "simplices", "coefficient", "standard_error", ...
                     "t_statistic", "degree_of_freedom", "p_value", ...
                     "significance_bonferroni"];
    
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
    
    % Format condition column
    fprintf('Formatting condition column...\n');
    data.condition = format_condition_values(data.condition);
    
    % Format cohort column
    fprintf('Formatting cohort column...\n');
    data.cohort = format_cohort_values(data.cohort, config);
    
    % Format simplices column (replace underscores with hyphens)
    fprintf('Formatting simplices column...\n');
    data.simplices = strrep(data.simplices, "_", "-");
    
    % Format numerical columns (3 significant figures)
    fprintf('Formatting numerical columns to 3 significant figures...\n');
    
    numerical_cols = ["coefficient", "standard_error", "t_statistic", "p_value"];
    
    for col_idx = 1:numel(numerical_cols)
        col_name = numerical_cols(col_idx);
        data.(col_name) = format_to_3_sig_figs(data.(col_name));
    end
    
    % Rename columns
    fprintf('Renaming columns...\n');
    
    new_column_names = ["Condition", "Co-hort", "Ses-sion", "Parcellation", ...
                        "Simplices", "Coef", "SE", "t-stat", "DF", "p-value", ...
                        "Sig (Bonfe-rroni corr)"];
    
    data.Properties.VariableNames = new_column_names;
    
    % Save polished table
    fprintf('Saving polished table...\n');
    writetable(data, output_file);
    
    fprintf('Done!\n');
    fprintf('Output file: %s\n', output_file);
end

%% Helper function: Format condition values
function formatted_conditions = format_condition_values(conditions)
    % Format condition values according to mapping rules
    %
    % Inputs:
    %   conditions - String array of condition values
    %
    % Outputs:
    %   formatted_conditions - String array with formatted values
    
    formatted_conditions = strings(size(conditions));
    
    for row_idx = 1:numel(conditions)
        condition = conditions(row_idx);
        
        % Apply condition mappings
        if strcmp(condition, "pca_variance_threshold_90")
            formatted_conditions(row_idx) = "PCA (90% variance)";
        elseif strcmp(condition, "pca_fixed_components_30")
            formatted_conditions(row_idx) = "PCA (30 comp)";
        elseif strcmp(condition, "pca_fixed_components_35")
            formatted_conditions(row_idx) = "PCA (35 comp)";
        elseif strcmp(condition, "pca_fixed_components_40")
            formatted_conditions(row_idx) = "PCA (40 comp)";
        elseif strcmp(condition, "raw_features")
            formatted_conditions(row_idx) = "Raw Features";
        elseif strcmp(condition, "coherence")
            formatted_conditions(row_idx) = "Coherence";
        else
            % Keep as is if not in mapping
            warning('Unknown condition: %s', condition);
            formatted_conditions(row_idx) = condition;
        end
    end
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
            formatted_cohorts(idx) = config.var_dict.cohort_all_short;
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