% expt_02f_modularity_comparison_head_motion_ancova.m
% Modularity comparison across simplex levels, adjusted for head motion.
%
% This modifies the paired t-test in expt_02b: instead of testing whether the
% per-subject modularity difference equals zero, it regresses that difference
% on (demeaned) mean head motion and reports the intercept -- i.e. the
% head-motion-adjusted difference. Following expt_03c, the model is
%
%   difference ~ 1 + mean_head_motion_demeaned          (fitlm, no random effect)
%
% where difference = simplex_1_modularity - simplex_2_modularity per subject.
% Because head motion is a single per-subject value, there is one row per
% subject and no (1 | subject) term. Head motion is demeaned by the cohort mean,
% so the intercept is the difference at the average head motion.
%
% This script:
%   1. Reads the same conditions as expt_02b (reported with display names)
%   2. Joins per-session mean head motion by subject and demeans it
%   3. For edge-node, edge-triangle, triangle-node (edge-node only on
%      schaefer200x7), fits the ANCOVA and reports the intercept
%   4. Applies Bonferroni correction; non-significant results are marked "n.s."

%% Setup
clear; close all; clc;

% Get repository root
repo_root = fcn_utils_detect_repo_root();

% Define paths (reuse the expt_02b condition list)
config_file = fullfile(repo_root, "data_raw", "data_stat_config", ...
                       "config_modularity_comparison_paired_ttest.csv");
output_dir = fullfile(repo_root, "data_pipeline", "stat_modularity_comparison");
output_file = fullfile(output_dir, "stat_modularity_comparison_ancova_head_motion.csv");

head_motion_dir = fullfile(repo_root, "data_pipeline_gitignore", "mean_head_motion");

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
num_schaefer100x7 = sum(strcmp(config.parcellation, "schaefer100x7"));
num_schaefer200x7 = sum(strcmp(config.parcellation, "schaefer200x7"));
num_tests = 3 * num_schaefer100x7 + num_schaefer200x7;

fprintf('Total number of tests: %d\n', num_tests);
fprintf('Bonferroni-corrected alpha: %.6f\n\n', 0.05 / num_tests);

%% Preallocate results table
% Internal (valid-identifier) names during assembly; the four stat columns are
% renamed to their display headers just before saving.
results_table = table('Size', [num_tests, 12], ...
    'VariableTypes', {'string', 'string', 'string', 'string', 'string', 'string', ...
                      'double', 'double', 'double', 'double', 'double', 'string'}, ...
    'VariableNames', {'condition', 'cohort', 'session', 'parcellation', ...
                      'simplex_1', 'simplex_2', ...
                      'coefficient', 'standard_error', 't_statistic', ...
                      'degree_of_freedom', 'p_value', 'significance_bonferroni'});

%% Process each condition
row_idx = 1;

for config_idx = 1:num_conditions
    condition_code = config.condition(config_idx);
    condition_display = get_condition_display_name(condition_code);
    cohort = config.cohort(config_idx);
    session = config.session(config_idx);
    parcellation = config.parcellation(config_idx);

    fprintf('Processing: condition=%s, cohort=%s, session=%s, parcellation=%s\n', ...
            condition_code, cohort, session, parcellation);

    % Determine comparisons for this parcellation (matches expt_02b)
    if strcmp(parcellation, "schaefer100x7")
        comparisons = ["edge", "node"; "edge", "triangle"; "triangle", "node"];
    else  % schaefer200x7
        comparisons = ["edge", "node"];
    end
    num_comparisons = size(comparisons, 1);

    % Fill identifying information for all comparisons from this condition
    results_table.condition(row_idx:row_idx+num_comparisons-1) = condition_display;
    results_table.cohort(row_idx:row_idx+num_comparisons-1) = cohort;
    results_table.session(row_idx:row_idx+num_comparisons-1) = session;
    results_table.parcellation(row_idx:row_idx+num_comparisons-1) = parcellation;
    results_table.simplex_1(row_idx:row_idx+num_comparisons-1) = comparisons(:, 1);
    results_table.simplex_2(row_idx:row_idx+num_comparisons-1) = comparisons(:, 2);

    % Construct modularity data filename (uses the raw condition code)
    data_filename = sprintf("simplex_mapper_%s_cohort_%s_%s_%s.csv", ...
                            condition_code, cohort, session, parcellation);
    data_filepath = fullfile(repo_root, "data_pipeline", "simplex_mappers", data_filename);

    if ~exist(data_filepath, 'file')
        warning('Modularity file not found: %s\nSkipping...', data_filepath);
        block = row_idx:row_idx+num_comparisons-1;
        results_table.coefficient(block) = NaN;
        results_table.standard_error(block) = NaN;
        results_table.t_statistic(block) = NaN;
        results_table.degree_of_freedom(block) = NaN;
        results_table.p_value(block) = NaN;
        results_table.significance_bonferroni(block) = missing;
        row_idx = row_idx + num_comparisons;
        fprintf('\n');
        continue;
    end

    % Head motion is essential to this analysis, so a missing file is an error
    % (consistent with expt_03c / expt_04b).
    head_motion_filepath = fullfile(head_motion_dir, ...
        sprintf('mean_head_motion_cohort_all_session_%s.csv', session));
    if ~exist(head_motion_filepath, 'file')
        error('Head motion file not found: %s', head_motion_filepath);
    end

    % Read modularity (wide) and head motion, join by subject
    data_wide = readtable(data_filepath, "FileType", "text", ...
                          "TextType", "string", ...
                          "VariableNamingRule", "preserve");
    head_motion_data = readtable(head_motion_filepath, "FileType", "text", ...
                                 "TextType", "string", ...
                                 "VariableNamingRule", "preserve");

    merged_data = outerjoin(data_wide, head_motion_data, ...
        'Keys', 'subject', 'MergeKeys', true, 'Type', 'left');

    % Demean head motion by the cohort mean (as in expt_03c)
    cohort_mean_head_motion = mean(merged_data.mean_head_motion, 'omitnan');
    merged_data.mean_head_motion_demeaned = merged_data.mean_head_motion - cohort_mean_head_motion;

    fprintf('  Loaded %d subjects, cohort mean head motion = %.6f\n', ...
            height(merged_data), cohort_mean_head_motion);

    %% ANCOVA per comparison
    for comparison_idx = 1:num_comparisons
        simplex_1 = comparisons(comparison_idx, 1);
        simplex_2 = comparisons(comparison_idx, 2);

        modularity_1 = merged_data.(strcat(simplex_1, "_modularity"));
        modularity_2 = merged_data.(strcat(simplex_2, "_modularity"));
        difference = modularity_1 - modularity_2;
        head_motion_demeaned = merged_data.mean_head_motion_demeaned;

        % Keep subjects with both modularities and head motion
        valid_idx = ~ismissing(difference) & ~ismissing(head_motion_demeaned);
        difference_clean = difference(valid_idx);
        head_motion_clean = head_motion_demeaned(valid_idx);
        num_valid = sum(valid_idx);

        if num_valid < 3
            warning('Insufficient valid subjects for %s vs %s (%d)', simplex_1, simplex_2, num_valid);
            results_table.coefficient(row_idx) = NaN;
            results_table.standard_error(row_idx) = NaN;
            results_table.t_statistic(row_idx) = NaN;
            results_table.degree_of_freedom(row_idx) = NaN;
            results_table.p_value(row_idx) = NaN;
            results_table.significance_bonferroni(row_idx) = missing;
            row_idx = row_idx + 1;
            continue;
        end

        % Fit difference ~ 1 + demeaned head motion; report the intercept
        tbl = table(difference_clean, head_motion_clean, 'VariableNames', {'y', 'x'});
        mdl = fitlm(tbl, 'y ~ 1 + x');

        coef_table = mdl.Coefficients;
        intercept_row = strcmp(coef_table.Properties.RowNames, '(Intercept)');

        coefficient = coef_table.Estimate(intercept_row);
        standard_error = coef_table.SE(intercept_row);
        t_statistic = coef_table.tStat(intercept_row);
        p_value = coef_table.pValue(intercept_row);
        df = mdl.DFE;

        significance = fcn_stat_get_significance_asterisks(p_value * num_tests);
        if strcmp(significance, "0")
            significance = "n.s.";
        end

        fprintf('  %s vs %s: b0 = %.6f, SE = %.6f, t(%d) = %.4f, p = %.6f %s\n', ...
                simplex_1, simplex_2, coefficient, standard_error, df, t_statistic, p_value, significance);

        results_table.coefficient(row_idx) = coefficient;
        results_table.standard_error(row_idx) = standard_error;
        results_table.t_statistic(row_idx) = t_statistic;
        results_table.degree_of_freedom(row_idx) = df;
        results_table.p_value(row_idx) = p_value;
        results_table.significance_bonferroni(row_idx) = significance;

        row_idx = row_idx + 1;
    end

    fprintf('\n');
end

%% Round reported statistics to 3 significant figures (DF kept exact)
for col = {'coefficient', 'standard_error', 't_statistic', 'p_value'}
    results_table.(col{1}) = round(results_table.(col{1}), 3, 'significant');
end

%% Rename stat columns to display headers and save
results_table.Properties.VariableNames = {'condition', 'cohort', 'session', 'parcellation', ...
    'simplex_1', 'simplex_2', 'Coef', 'SE', 't-stat', 'DF', 'p_value', 'significance_bonferroni'};

fprintf('Saving results to: %s\n', output_file);
writetable(results_table, output_file);

fprintf('\nAnalysis complete!\n');
fprintf('Total rows in output: %d\n', height(results_table));

%% Helper: condition code -> display name
function name = get_condition_display_name(condition)
    if strcmp(condition, "raw_features")
        name = "Raw Features";
    elseif strcmp(condition, "coherence")
        name = "Coherence";
    elseif startsWith(condition, "pca_variance_threshold_")
        pct = extractAfter(condition, "pca_variance_threshold_");
        name = sprintf("PCA (%s%% variance)", pct);
    elseif startsWith(condition, "pca_fixed_components_")
        num_components = extractAfter(condition, "pca_fixed_components_");
        name = sprintf("PCA (%s comp)", num_components);
    else
        name = condition;
    end
end
