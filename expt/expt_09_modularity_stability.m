config = fcn_utils_get_config();

feature_processing = "raw_features";
parcellation = "schaefer100x7";

cohorts = ["one", "two"];
simplices = ["node", "edge", "triangle"];

% Define comparisons outside the loop
comparison_names = ["node vs edge", "node vs triangle", "edge vs triangle"];
comparisons = [1 2; 1 3; 2 3];

% Set significance level
alpha_significance = 0.05;
confidence_level = 1 - alpha_significance;

% Load modularity data ONCE (outside cohort loop) - contains ALL cohorts
input_directory = fullfile(config.repo_root, "data_pipeline", "simplex_mappers");
modularity_filename = sprintf("simplex_mapper_raw_features_cohort_all_session_both_%s.csv", parcellation);
modularity_filepath = fullfile(input_directory, modularity_filename);
all_modularity_data = readtable(modularity_filepath, 'PreserveVariableNames', true);

% Preallocate arrays to collect results across cohorts
n_cohorts = numel(cohorts);
n_simplices = numel(simplices);
n_comparisons = size(comparisons, 1);

% Preallocate correlation results (n_cohorts × n_simplices rows)
all_corr_results = table('Size', [n_cohorts * n_simplices, 6], ...
                        'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double'}, ...
                        'VariableNames', {'cohort', 'simplex', 'correlation', 'confidence_interval_lower', 'confidence_interval_upper', 'n'});
all_corr_results{:, :} = NaN;  % Initialize numeric columns with NaN

% Preallocate Steiger test results (n_cohorts × n_comparisons rows)
all_steiger_results = table('Size', [n_cohorts * n_comparisons, 8], ...
                           'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
                           'VariableNames', {'cohort', 'comparison', 'r1', 'r2', 'z_steiger', 'f', 'p_steiger', 'p_fisher'});
all_steiger_results{:, :} = NaN;  % Initialize numeric columns with NaN

% Loop through cohorts
for cohort_idx = 1:n_cohorts
    cohort = cohorts(cohort_idx);
    fprintf('\n=== Processing Cohort: %s ===\n', cohort);
    
    % Load cohort-specific subject list
    cohort_filename = fullfile(config.repo_root, "data_pipeline", "data_cohort", ...
                              sprintf("cohort_%s_session_both.csv", cohort));
    cohort_subjects = readtable(cohort_filename, 'PreserveVariableNames', true);
    
    % Filter modularity data to only this cohort's subjects using outer join
    mod_comparison_table = outerjoin(cohort_subjects, all_modularity_data, ...
                                     'LeftKeys', 'Subject', ...
                                     'RightKeys', 'subject', ...
                                     'Type', 'left');
    
    % Remove rows where modularity data is missing (subjects not in modularity file)
    mod_comparison_table = mod_comparison_table(~isnan(mod_comparison_table.LR_node_modularity), :);
    
    fprintf('Found %d subjects with complete data in cohort %s\n', height(mod_comparison_table), cohort);
    
    % Compute correlations for each simplex type
    corrs = zeros(size(simplices));
    dfs = zeros(size(simplices));
    confidence_interval_lower = zeros(size(simplices));
    confidence_interval_upper = zeros(size(simplices));
    
    fprintf('\n=== TEST-RETEST CORRELATIONS ===\n\n');
    
    for simplex_idx = 1:n_simplices
        simplex = simplices(simplex_idx);
        
        % Column naming convention
        LR_col_name = sprintf("LR_%s_modularity", simplex);
        RL_col_name = sprintf("RL_%s_modularity", simplex);
        
        % Compute correlation
        correlation_between_scans = corr(mod_comparison_table{:, [LR_col_name, RL_col_name]}, "rows", "pairwise");
        correlation_between_scans = correlation_between_scans(1, 2);
        corrs(simplex_idx) = correlation_between_scans;
        
        % Compute degrees of freedom
        valid_pairs = ~isnan(mod_comparison_table.(LR_col_name)) & ~isnan(mod_comparison_table.(RL_col_name));
        n_valid = sum(valid_pairs);
        dfs(simplex_idx) = n_valid;
        
        % Compute confidence interval
        [confidence_interval_low, confidence_interval_high] = fcn_stat_correlation_confidence_interval(correlation_between_scans, n_valid, confidence_level);
        confidence_interval_lower(simplex_idx) = confidence_interval_low;
        confidence_interval_upper(simplex_idx) = confidence_interval_high;
        
        % Print correlation with confidence interval
        fprintf('%s modularity:\n', simplex);
        fprintf('  r = %.3g [%.0f%% CI: %.3g, %.3g]\n', ...
                correlation_between_scans, confidence_level*100, confidence_interval_low, confidence_interval_high);
        fprintf('  n = %d\n\n', n_valid);
        
        % Store in preallocated table
        row_idx = (cohort_idx - 1) * n_simplices + simplex_idx;
        all_corr_results.cohort(row_idx) = string(cohort);
        all_corr_results.simplex(row_idx) = string(simplex);
        all_corr_results.correlation(row_idx) = correlation_between_scans;
        all_corr_results.confidence_interval_lower(row_idx) = confidence_interval_low;
        all_corr_results.confidence_interval_upper(row_idx) = confidence_interval_high;
        all_corr_results.n(row_idx) = n_valid;
    end
    
    % Compute full correlation matrix for Steiger's test
    all_data = [mod_comparison_table.LR_node_modularity, mod_comparison_table.RL_node_modularity, ...
                mod_comparison_table.LR_edge_modularity, mod_comparison_table.RL_edge_modularity, ...
                mod_comparison_table.LR_triangle_modularity, mod_comparison_table.RL_triangle_modularity];
    
    full_corr_matrix = corr(all_data, 'rows', 'pairwise');
    
    % Display correlation matrix
    fprintf('\n=== FULL CORRELATION MATRIX ===\n');
    fprintf('         node_LR  node_RL  edge_LR  edge_RL  tri_LR   tri_RL\n');
    var_names = {'node_LR', 'node_RL', 'edge_LR', 'edge_RL', 'tri_LR', 'tri_RL'};
    for i = 1:6
        fprintf('%-8s ', var_names{i});
        for j = 1:6
            fprintf('%7.3f  ', full_corr_matrix(i, j));
        end
        fprintf('\n');
    end
    
    fprintf('\n=== CORRELATION COMPARISON TESTS ===\n\n');
    
    for comp_row_idx = 1:n_comparisons
        simplex_idx_1 = comparisons(comp_row_idx, 1);
        simplex_idx_2 = comparisons(comp_row_idx, 2);
        
        % Get indices in full correlation matrix
        j = 2*simplex_idx_1 - 1;
        k = 2*simplex_idx_1;
        h = 2*simplex_idx_2 - 1;
        m = 2*simplex_idx_2;
        
        % Extract correlations needed for Steiger's test
        r_jk = full_corr_matrix(j, k);
        r_hm = full_corr_matrix(h, m);
        r_jh = full_corr_matrix(j, h);
        r_jm = full_corr_matrix(j, m);
        r_kh = full_corr_matrix(k, h);
        r_km = full_corr_matrix(k, m);
        
        % Determine effective sample size
        n_eff = min(dfs(simplex_idx_1), dfs(simplex_idx_2));
        
        % Steiger's test
        [z_steiger, p_steiger, f] = fcn_stat_steiger_test(r_jk, r_hm, r_jh, r_jm, r_kh, r_km, n_eff);
        
        % Fisher's test (for comparison)
        z1 = 0.500 * log((1 + corrs(simplex_idx_1)) / (1 - corrs(simplex_idx_1)));
        z2 = 0.500 * log((1 + corrs(simplex_idx_2)) / (1 - corrs(simplex_idx_2)));
        SE_fisher = sqrt(1/(dfs(simplex_idx_1) - 3) + 1/(dfs(simplex_idx_2) - 3));
        z_fisher = (z1 - z2) / SE_fisher;
        p_fisher = 2 * normcdf(-abs(z_fisher));
        
        % Display results
        fprintf('Comparison: %s\n', comparison_names(comp_row_idx));
        fprintf('  %s: r = %.3g [%.3g, %.3g], n = %d\n', ...
                simplices(simplex_idx_1), corrs(simplex_idx_1), ...
                confidence_interval_lower(simplex_idx_1), confidence_interval_upper(simplex_idx_1), dfs(simplex_idx_1));
        fprintf('  %s: r = %.3g [%.3g, %.3g], n = %d\n', ...
                simplices(simplex_idx_2), corrs(simplex_idx_2), ...
                confidence_interval_lower(simplex_idx_2), confidence_interval_upper(simplex_idx_2), dfs(simplex_idx_2));
        fprintf('  n_eff = %d\n', n_eff);
        fprintf('  Dependence parameter f = %.3g\n', f);
        fprintf('  Steiger Z = %.3g, p = %.3g (CORRECT)\n', z_steiger, p_steiger);
        fprintf('  Fisher  Z = %.3g, p = %.3g (INCORRECT)\n', z_fisher, p_fisher);
        fprintf('  Difference in p-values: %.3g\n\n', abs(p_steiger - p_fisher));
        
        % Store in preallocated table
        row_idx = (cohort_idx - 1) * n_comparisons + comp_row_idx;
        all_steiger_results.cohort(row_idx) = string(cohort);
        all_steiger_results.comparison(row_idx) = string(comparison_names(comp_row_idx));
        all_steiger_results.r1(row_idx) = corrs(simplex_idx_1);
        all_steiger_results.r2(row_idx) = corrs(simplex_idx_2);
        all_steiger_results.z_steiger(row_idx) = z_steiger;
        all_steiger_results.f(row_idx) = f;
        all_steiger_results.p_steiger(row_idx) = p_steiger;
        all_steiger_results.p_fisher(row_idx) = p_fisher;
    end
    
    fprintf('\n=== CORRELATION SUMMARY ===\n');
    cohort_corr_rows = (cohort_idx - 1) * n_simplices + (1:n_simplices);
    disp(all_corr_results(cohort_corr_rows, :));
    
    fprintf('\n=== COMPARISON SUMMARY ===\n');
    cohort_steiger_rows = (cohort_idx - 1) * n_comparisons + (1:n_comparisons);
    disp(all_steiger_results(cohort_steiger_rows, :));
end

% Save combined results for all cohorts
output_directory = fullfile(config.repo_root, "data_pipeline", "stat_modularity_stability");
if ~exist(output_directory, 'dir')
    mkdir(output_directory);
end

% Save correlation table (all cohorts)
corr_csv_filename = fullfile(output_directory, ...
    sprintf("stat_modularity_stability_correlation_%s_%s.csv", feature_processing, parcellation));
writetable(all_corr_results, corr_csv_filename);
fprintf('\nSaved correlation summary (all cohorts) to: %s\n', corr_csv_filename);

% Save Steiger test results table (all cohorts)
steiger_csv_filename = fullfile(output_directory, ...
    sprintf("stat_modularity_stability_steiger_%s_%s.csv", feature_processing, parcellation));
writetable(all_steiger_results, steiger_csv_filename);
fprintf('Saved Steiger test results (all cohorts) to: %s\n', steiger_csv_filename);