% expt_stat_shuffled_modularity.m
% Statistical analysis of shuffled modularity data
%
% This script:
%   1. Creates delta columns for modularity comparisons
%   2. Performs one-sample and paired t-tests comparing different conditions
%   3. Applies Bonferroni correction for multiple comparisons
%   4. Saves results for different baseline comparisons

%% Setup
clear; close all; clc;

% Get repository root
repo_root = fcn_utils_detect_repo_root();

% SECTION I: Configuration
cohorts = ["one", "two"];
simplices = ["node", "edge", "triangle"];
session = "LR";
peak_threshold = 0.95;
purity_threshold = 0.75;
peak_density_thresholds = [0.9, 0.8, 0.95];
candidate_peak_density_threshold = 0.9;  % Used for Sections IV and V
num_external_hypotheses = 1;  % For Bonferroni correction

% Control flag for delta table creation
% create_delta_table_flag = true;
create_delta_table_flag = false;

% Define paths
data_dir = fullfile(repo_root, "data_pipeline", "shuffled_modularity");
output_dir = fullfile(repo_root, "data_pipeline", "stat_shuffled_modularity");

% Create output directory if needed
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    fprintf('Created output directory: %s\n', output_dir);
end

%% SECTION II: Create or load delta tables

fprintf('SECTION II: Creating/loading delta tables\n');
fprintf('==========================================\n\n');

if create_delta_table_flag
    for cohort = cohorts
        for simplex = simplices
            % Construct filenames
            base_filename = sprintf('shuffled_modularity_mean_%s_%s_%s_peak_%d_purity_%d.csv', ...
                simplex, cohort, session, round(peak_threshold*100), round(purity_threshold*100));
            delta_filename = sprintf('shuffled_modularity_mean_with_delta_%s_%s_%s_peak_%d_purity_%d.csv', ...
                simplex, cohort, session, round(peak_threshold*100), round(purity_threshold*100));
            
            input_filepath = fullfile(data_dir, base_filename);
            output_filepath = fullfile(data_dir, delta_filename);
            
            fprintf('Creating delta table for %s, %s, %s...\n', simplex, cohort, session);
            
            % Check if input file exists
            if ~exist(input_filepath, 'file')
                warning('Input file not found: %s', input_filepath);
                continue;
            end
            
            % Read original data
            data = readtable(input_filepath, "FileType", "text", ...
                "TextType", "string", ...
                "VariableNamingRule", "preserve");
            
            fprintf('  Loaded %d subjects\n', height(data));
            
            % Create 13 new delta columns
            % 1. none_minus_all
            data.none_minus_all = data.none - data.all;
            
            % For each threshold: 4 columns × 3 thresholds = 12 columns
            for threshold = peak_density_thresholds
                threshold_str = sprintf('%d', round(threshold*100));
                peak_col = sprintf('peak_dense_%s', threshold_str);
                matched_col = sprintf('matched_random_%s', threshold_str);
                
                % 2-4. peak_dense_minus_none
                data.(sprintf('peak_dense_minus_none_%s', threshold_str)) = ...
                    data.(peak_col) - data.none;
                
                % 5-7. peak_dense_minus_all
                data.(sprintf('peak_dense_minus_all_%s', threshold_str)) = ...
                    data.(peak_col) - data.all;
                
                % 8-10. peak_dense_minus_matched_random
                data.(sprintf('peak_dense_minus_matched_random_%s', threshold_str)) = ...
                    data.(peak_col) - data.(matched_col);
                
                % 11-13. none_minus_matched_random
                data.(sprintf('none_minus_matched_random_%s', threshold_str)) = ...
                    data.none - data.(matched_col);
            end
            
            % Save with delta columns
            writetable(data, output_filepath);
            fprintf('  Saved delta table: %s\n', delta_filename);
            fprintf('  Total columns: %d (original) + 13 (new) = %d\n\n', ...
                width(data) - 13, width(data));
        end
    end
else
    fprintf('Skipping delta table creation (will load in Section III)\n\n');
end

fprintf('SECTION II complete\n\n');

%% Compute number of tests for Bonferroni correction
fprintf('Computing number of tests for Bonferroni correction...\n');

num_simplices = numel(simplices);
num_cohorts = numel(cohorts);

% Per cohort: (num_simplices * 3 within-simplex tests + 3 between-simplex tests)
% Times num_cohorts, plus num_external_hypotheses
num_tests = (num_simplices * 3 + 3 + num_external_hypotheses) * num_cohorts;

fprintf('  Simplices: %d\n', num_simplices);
fprintf('  Within-simplex tests per simplex: 3\n');
fprintf('  Between-simplex pairwise tests: 3\n');
fprintf('  Cohorts: %d\n', num_cohorts);
fprintf('  External hypotheses: %d\n', num_external_hypotheses);
fprintf('Total number of tests: (%d * 3 + 3 + %d) * %d = %d\n', ...
    num_simplices, num_external_hypotheses, num_cohorts, num_tests);
fprintf('Bonferroni-corrected alpha: %.6f\n\n', 0.05 / num_tests);

%% SECTION III: T-tests comparing against "all" and "none" baselines

fprintf('SECTION III: T-tests vs "all" and "none" baselines\n');
fprintf('==================================================\n\n');

for threshold = peak_density_thresholds
    threshold_str = sprintf('%d', round(threshold*100));
    
    % Load all simplex data for this threshold
    simplex_data_struct = struct();
    
    for cohort = cohorts
        for simplex = simplices
            delta_filename = sprintf('shuffled_modularity_mean_with_delta_%s_%s_%s_peak_%d_purity_%d.csv', ...
                simplex, cohort, session, round(peak_threshold*100), round(purity_threshold*100));
            delta_filepath = fullfile(data_dir, delta_filename);
            
            simplex_cohort = sprintf('%s_%s', simplex, cohort);
            
            if ~exist(delta_filepath, 'file')
                warning('Delta file not found: %s', delta_filepath);
                simplex_data_struct.(simplex_cohort) = [];
            else
                simplex_data_struct.(simplex_cohort) = readtable(delta_filepath, "FileType", "text", ...
                    "TextType", "string", ...
                    "VariableNamingRule", "preserve");
            end
        end
    end
    
    % Construct output filepath
    output_filename = sprintf('stat_shuffled_modularity_ttest_all_%s.csv', threshold_str);
    output_filepath = fullfile(output_dir, output_filename);
    
    % Call the function with matched_random_flag = false
    fcn_peakDense_shuffled_modularity_ttest(cohorts, session, threshold, ...
        simplex_data_struct, num_tests, output_filepath, false);
end

fprintf('SECTION III complete\n\n');

%% SECTION IV: T-tests comparing against "matched_random" baseline

fprintf('SECTION IV: T-tests vs "matched_random" baseline\n');
fprintf('=================================================\n\n');

% Only for candidate_peak_density_threshold
threshold = candidate_peak_density_threshold;
threshold_str = sprintf('%d', round(threshold*100));

% Load all simplex data
simplex_data_struct = struct();

for cohort = cohorts
    for simplex = simplices
        delta_filename = sprintf('shuffled_modularity_mean_with_delta_%s_%s_%s_peak_%d_purity_%d.csv', ...
            simplex, cohort, session, round(peak_threshold*100), round(purity_threshold*100));
        delta_filepath = fullfile(data_dir, delta_filename);
        
        simplex_cohort = sprintf('%s_%s', simplex, cohort);
        
        if ~exist(delta_filepath, 'file')
            warning('Delta file not found: %s', delta_filepath);
            simplex_data_struct.(simplex_cohort) = [];
        else
            simplex_data_struct.(simplex_cohort) = readtable(delta_filepath, "FileType", "text", ...
                "TextType", "string", ...
                "VariableNamingRule", "preserve");
        end
    end
end

% Construct output filepath
output_filename = sprintf('stat_shuffled_modularity_ttest_matched_random_%s.csv', threshold_str);
output_filepath = fullfile(output_dir, output_filename);

% Call the function with matched_random_flag = true
fcn_peakDense_shuffled_modularity_ttest(cohorts, session, threshold, ...
    simplex_data_struct, num_tests, output_filepath, true);

fprintf('SECTION IV complete\n\n');

%% SECTION V: ANCOVA with head motion covariate

fprintf('SECTION V: ANCOVA with head motion covariate\n');
fprintf('=============================================\n\n');

% Only for candidate_peak_density_threshold
threshold = candidate_peak_density_threshold;
threshold_str = sprintf('%d', round(threshold*100));

fprintf('Processing threshold: %.2f (%s)\n', threshold, threshold_str);
fprintf('--------------------------------------------------\n');

% Load head motion data
head_motion_filename = sprintf('mean_head_motion_cohort_all_session_%s.csv', session);
head_motion_filepath = fullfile(repo_root, "data_pipeline_gitignore", "mean_head_motion", head_motion_filename);

if ~exist(head_motion_filepath, 'file')
    error('Head motion file not found: %s', head_motion_filepath);
end

head_motion_data = readtable(head_motion_filepath, "FileType", "text", ...
    "TextType", "string", ...
    "VariableNamingRule", "preserve");

fprintf('Loaded head motion data: %d subjects\n\n', height(head_motion_data));

% Preallocate results table
num_rows_per_cohort = num_simplices * 3 + 3;
num_rows = num_rows_per_cohort * num_cohorts;

results_table = table('Size', [num_rows, 11], ...
    'VariableTypes', {'string', 'string', 'string', 'string', ...
                      'double', 'double', 'double', 'double', 'double', 'double', 'string'}, ...
    'VariableNames', {'cohort', 'session', 'test_type', 'simplex', ...
                      'num_valid', 'coefficient', 'standard_error', 't_statistic', ...
                      'degree_of_freedom', 'p_value', 'significance_bonferroni'});

row_idx = 1;

%% Process each cohort
for cohort = cohorts
    fprintf('\nCohort: %s\n', cohort);
    
    % Load and merge all simplex data with head motion for this cohort
    simplex_data_with_head_motion = struct();
    
    for simplex = simplices
        delta_filename = sprintf('shuffled_modularity_mean_with_delta_%s_%s_%s_peak_%d_purity_%d.csv', ...
            simplex, cohort, session, round(peak_threshold*100), round(purity_threshold*100));
        delta_filepath = fullfile(data_dir, delta_filename);
        
        simplex_cohort = sprintf('%s_%s', simplex, cohort);
        
        if ~exist(delta_filepath, 'file')
            warning('Delta file not found: %s', delta_filepath);
            simplex_data_with_head_motion.(simplex_cohort) = [];
            continue;
        end
        
        % Load simplex data
        simplex_data = readtable(delta_filepath, "FileType", "text", ...
            "TextType", "string", ...
            "VariableNamingRule", "preserve");
        
        % Merge with head motion data
        merged_data = outerjoin(simplex_data, head_motion_data, ...
            'LeftKeys', 'Subject', 'RightKeys', 'subject', ...
            'MergeKeys', true, 'Type', 'left');
        
        % Add demeaned head motion column immediately
        cohort_mean_head_motion = mean(merged_data.mean_head_motion, 'omitnan');
        merged_data.mean_head_motion_demeaned = merged_data.mean_head_motion - cohort_mean_head_motion;
        merged_data.Properties.VariableNames = strrep(...
            merged_data.Properties.VariableNames, "Subject_subject", "Subject");
        
        % Store in struct
        simplex_data_with_head_motion.(simplex_cohort) = merged_data;
        
        fprintf('  Loaded %s: %d subjects, mean head motion = %.6f\n', ...
            simplex_cohort, height(merged_data), cohort_mean_head_motion);
    end
    
    % Within-simplex ANCOVA
    for simplex = simplices
        simplex_cohort = sprintf('%s_%s', simplex, cohort);
        
        if isempty(simplex_data_with_head_motion.(simplex_cohort))
            warning('Missing data for %s', simplex_cohort);
            % Fill with NaN for missing data (3 tests)
            results_table.cohort(row_idx:row_idx+2) = cohort;
            results_table.session(row_idx:row_idx+2) = session;
            results_table.simplex(row_idx:row_idx+2) = simplex;
            results_table.num_valid(row_idx:row_idx+2) = NaN;
            results_table.coefficient(row_idx:row_idx+2) = NaN;
            results_table.standard_error(row_idx:row_idx+2) = NaN;
            results_table.t_statistic(row_idx:row_idx+2) = NaN;
            results_table.degree_of_freedom(row_idx:row_idx+2) = NaN;
            results_table.p_value(row_idx:row_idx+2) = NaN;
            results_table.significance_bonferroni(row_idx:row_idx+2) = missing;
            row_idx = row_idx + 3;
            continue;
        end
        
        data = simplex_data_with_head_motion.(simplex_cohort);
        
        fprintf('  Simplex: %s\n', simplex);
        
        % Define the three tests
        test_vars = [
            sprintf("peak_dense_minus_none_%s", threshold_str);
            sprintf("peak_dense_minus_all_%s", threshold_str);
            "none_minus_all"
        ];
        
        test_types = [
            "peak_dense_minus_none";
            "peak_dense_minus_all";
            "none_minus_all"
        ];
        
        % Loop through the three tests
        for test_idx = 1:3
            test_var_name = test_vars(test_idx);
            test_type = test_types(test_idx);
            
            % Remove rows with missing data in either variable
            valid_idx = ~ismissing(data.(test_var_name)) & ...
                        ~ismissing(data.mean_head_motion_demeaned);
            
            test_data_clean = data.(test_var_name)(valid_idx);
            head_motion_clean = data.mean_head_motion_demeaned(valid_idx);
            num_valid = sum(valid_idx);
            
            results_table.cohort(row_idx) = cohort;
            results_table.session(row_idx) = session;
            results_table.test_type(row_idx) = test_type;
            results_table.simplex(row_idx) = simplex;
            results_table.num_valid(row_idx) = num_valid;
            
            if num_valid < 3
                warning('Insufficient data for %s, %s (need at least 3 for regression)', simplex, test_var_name);
                results_table.coefficient(row_idx) = NaN;
                results_table.standard_error(row_idx) = NaN;
                results_table.t_statistic(row_idx) = NaN;
                results_table.degree_of_freedom(row_idx) = NaN;
                results_table.p_value(row_idx) = NaN;
                results_table.significance_bonferroni(row_idx) = missing;
            else
                % Fit linear model: test_var ~ 1 + mean_head_motion_demeaned
                tbl = table(test_data_clean, head_motion_clean, ...
                    'VariableNames', {'y', 'x'});
                mdl = fitlm(tbl, 'y ~ 1 + x');
                
                % Extract intercept statistics
                coef_table = mdl.Coefficients;
                intercept_row = strcmp(coef_table.Properties.RowNames, '(Intercept)');
                
                coefficient = coef_table.Estimate(intercept_row);
                standard_error = coef_table.SE(intercept_row);
                t_statistic = coef_table.tStat(intercept_row);
                p_value = coef_table.pValue(intercept_row);
                df = mdl.DFE;
                
                significance = fcn_stat_get_significance_asterisks(p_value * num_tests);
                
                results_table.coefficient(row_idx) = coefficient;
                results_table.standard_error(row_idx) = standard_error;
                results_table.t_statistic(row_idx) = t_statistic;
                results_table.degree_of_freedom(row_idx) = df;
                results_table.p_value(row_idx) = p_value;
                results_table.significance_bonferroni(row_idx) = significance;
                
                fprintf('    %s: b0 = %.6f, SE = %.6f, t(%d) = %.4f, p = %.6f %s\n', ...
                    test_type, coefficient, standard_error, df, t_statistic, p_value, significance);
            end
            row_idx = row_idx + 1;
        end
    end
    
    % Between-simplex ANCOVA
    comparisons = [
        "edge", "node";
        "edge", "triangle";
        "triangle", "node"
    ];
    
    fprintf('  Between-simplex comparisons:\n');
    
    for comp_idx = 1:size(comparisons, 1)
        simplex_1 = comparisons(comp_idx, 1);
        simplex_2 = comparisons(comp_idx, 2);
        
        % Get simplex-cohort field names
        simplex_cohort_1 = sprintf('%s_%s', simplex_1, cohort);
        simplex_cohort_2 = sprintf('%s_%s', simplex_2, cohort);
        
        % Check if both data exist
        if isempty(simplex_data_with_head_motion.(simplex_cohort_1)) || ...
           isempty(simplex_data_with_head_motion.(simplex_cohort_2))
            warning('Missing data for comparison %s vs %s', simplex_1, simplex_2);
            
            results_table.cohort(row_idx) = cohort;
            results_table.session(row_idx) = session;
            results_table.test_type(row_idx) = sprintf("paired_%s_vs_%s", simplex_1, simplex_2);
            results_table.simplex(row_idx) = sprintf("%s-%s", simplex_1, simplex_2);
            results_table.num_valid(row_idx) = NaN;
            results_table.coefficient(row_idx) = NaN;
            results_table.standard_error(row_idx) = NaN;
            results_table.t_statistic(row_idx) = NaN;
            results_table.degree_of_freedom(row_idx) = NaN;
            results_table.p_value(row_idx) = NaN;
            results_table.significance_bonferroni(row_idx) = missing;
            row_idx = row_idx + 1;
            continue;
        end
        
        % Get the variable name
        var_name = sprintf('peak_dense_minus_none_%s', threshold_str);
        
        % Get data for both simplices
        data_1 = simplex_data_with_head_motion.(simplex_cohort_1);
        data_2 = simplex_data_with_head_motion.(simplex_cohort_2);
        
        % Select only needed columns and rename to avoid conflicts
        data_1_subset = data_1(:, {'Subject', var_name, 'mean_head_motion_demeaned'});
        data_1_subset.Properties.VariableNames{var_name} = sprintf('%s_simplex1', var_name);
        
        data_2_subset = data_2(:, {'Subject', var_name});
        data_2_subset.Properties.VariableNames{var_name} = sprintf('%s_simplex2', var_name);
        
        % Inner join to align by subject
        paired_data = outerjoin(data_1_subset, data_2_subset, ...
            'Keys', 'Subject', 'MergeKeys', true, 'Type', 'inner');
        
        if height(paired_data) == 0
            warning('No common subjects for %s vs %s', simplex_1, simplex_2);
            
            results_table.cohort(row_idx) = cohort;
            results_table.session(row_idx) = session;
            results_table.test_type(row_idx) = sprintf("paired_%s_vs_%s", simplex_1, simplex_2);
            results_table.simplex(row_idx) = sprintf("%s-%s", simplex_1, simplex_2);
            results_table.num_valid(row_idx) = NaN;
            results_table.coefficient(row_idx) = NaN;
            results_table.standard_error(row_idx) = NaN;
            results_table.t_statistic(row_idx) = NaN;
            results_table.degree_of_freedom(row_idx) = NaN;
            results_table.p_value(row_idx) = NaN;
            results_table.significance_bonferroni(row_idx) = missing;
            row_idx = row_idx + 1;
            continue;
        end
        
        % Compute difference variable
        var_name_1 = sprintf('%s_simplex1', var_name);
        var_name_2 = sprintf('%s_simplex2', var_name);
        difference = paired_data.(var_name_1) - paired_data.(var_name_2);
        head_motion_demeaned = paired_data.mean_head_motion_demeaned;
        
        % Remove rows with missing data
        valid_idx = ~ismissing(difference) & ~ismissing(head_motion_demeaned);
        difference_clean = difference(valid_idx);
        head_motion_clean = head_motion_demeaned(valid_idx);
        num_valid = sum(valid_idx);
        
        results_table.cohort(row_idx) = cohort;
        results_table.session(row_idx) = session;
        results_table.test_type(row_idx) = sprintf("paired_%s_vs_%s", simplex_1, simplex_2);
        results_table.simplex(row_idx) = sprintf("%s-%s", simplex_1, simplex_2);
        results_table.num_valid(row_idx) = num_valid;
        
        if num_valid < 3
            warning('Insufficient valid pairs for %s vs %s', simplex_1, simplex_2);
            results_table.coefficient(row_idx) = NaN;
            results_table.standard_error(row_idx) = NaN;
            results_table.t_statistic(row_idx) = NaN;
            results_table.degree_of_freedom(row_idx) = NaN;
            results_table.p_value(row_idx) = NaN;
            results_table.significance_bonferroni(row_idx) = missing;
        else
            % Fit linear model: difference ~ 1 + mean_head_motion_demeaned
            tbl = table(difference_clean, head_motion_clean, ...
                'VariableNames', {'y', 'x'});
            mdl = fitlm(tbl, 'y ~ 1 + x');
            
            % Extract intercept statistics
            coef_table = mdl.Coefficients;
            intercept_row = strcmp(coef_table.Properties.RowNames, '(Intercept)');
            
            coefficient = coef_table.Estimate(intercept_row);
            standard_error = coef_table.SE(intercept_row);
            t_statistic = coef_table.tStat(intercept_row);
            p_value = coef_table.pValue(intercept_row);
            df = mdl.DFE;
            
            significance = fcn_stat_get_significance_asterisks(p_value * num_tests);
            
            results_table.coefficient(row_idx) = coefficient;
            results_table.standard_error(row_idx) = standard_error;
            results_table.t_statistic(row_idx) = t_statistic;
            results_table.degree_of_freedom(row_idx) = df;
            results_table.p_value(row_idx) = p_value;
            results_table.significance_bonferroni(row_idx) = significance;
            
            fprintf('    %s vs %s: b0 = %.6f, SE = %.6f, t(%d) = %.4f, p = %.6f %s\n', ...
                simplex_1, simplex_2, coefficient, standard_error, df, t_statistic, p_value, significance);
        end
        row_idx = row_idx + 1;
    end
end

%% Save results
output_filename = sprintf('stat_shuffled_modularity_ancova_all_%s.csv', threshold_str);
output_filepath = fullfile(output_dir, output_filename);

fprintf('\nSaving results to: %s\n', output_filepath);
writetable(results_table, output_filepath);
fprintf('Total rows: %d\n\n', height(results_table));

fprintf('SECTION V complete\n\n');

fprintf('\nAnalysis complete!\n');