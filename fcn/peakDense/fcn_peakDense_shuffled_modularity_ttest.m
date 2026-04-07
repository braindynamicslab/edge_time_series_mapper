function fcn_peakDense_shuffled_modularity_ttest(cohorts, session, peak_density_threshold, ...
    simplex_data_struct, num_tests, output_filepath, matched_random_flag)
% fcn_peakDense_perform_ttest - Perform t-tests on peak dense modularity data
%
% Inputs:
%   cohorts - Array of cohort names (e.g., ["one", "two"])
%   session - Session name (e.g., "LR")
%   peak_density_threshold - Numeric threshold value (e.g., 0.9)
%   simplex_data_struct - Struct with fields named as <simplex>_<cohort> containing tables
%                         e.g., simplex_data_struct.node_one, simplex_data_struct.edge_two
%   num_tests - Total number of tests for Bonferroni correction
%   num_external_hypotheses - Number of external hypotheses (for calculating rows)
%   output_filepath - Full path for output CSV file
%   matched_random_flag - If true, use matched_random baseline; if false, use "all" baseline
%
% Outputs:
%   Saves results table to output_filepath

%% Setup
simplices = ["node", "edge", "triangle"];
num_simplices = numel(simplices);
num_cohorts = numel(cohorts);
threshold_str = sprintf('%d', round(peak_density_threshold*100));

fprintf('Processing threshold: %.2f (%s)\n', peak_density_threshold, threshold_str);
if matched_random_flag
    fprintf('Baseline: matched_random\n');
else
    fprintf('Baseline: all\n');
end
fprintf('--------------------------------------------------\n');

%% Determine baseline strings based on matched_random_flag
if matched_random_flag
    test_vars = [
        sprintf("peak_dense_minus_none_%s", threshold_str);
        sprintf("peak_dense_minus_matched_random_%s", threshold_str);
        sprintf("none_minus_matched_random_%s", threshold_str)
    ];
    
    test_types = [
        "peak_dense_minus_none";
        "peak_dense_minus_matched_random";
        "none_minus_matched_random"
    ];
    
    var_name = sprintf('peak_dense_minus_matched_random_%s', threshold_str);
else
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
    
    var_name = sprintf('peak_dense_minus_none_%s', threshold_str);
end

%% Validate that all required data exists
for cohort = cohorts
    for simplex = simplices
        field_name = sprintf('%s_%s', simplex, cohort);
        if ~isfield(simplex_data_struct, field_name)
            error('Missing field in simplex_data_struct: %s', field_name);
        end
        if isempty(simplex_data_struct.(field_name))
            error('Empty data for field: %s', field_name);
        end
    end
end

%% Preallocate results table
% (num_simplices * 3 + 3) tests per cohort * num_cohorts = rows
num_rows_per_cohort = num_simplices * 3 + 3;
num_rows = num_rows_per_cohort * num_cohorts;

results_table = table('Size', [num_rows, 10], ...
    'VariableTypes', {'string', 'string', 'string', 'string', ...
                      'double', 'double', 'double', 'double', 'double', 'string'}, ...
    'VariableNames', {'cohort', 'session', 'test_type', 'simplex', ...
                      'num_valid', 't_statistic', 'degree_of_freedom', ...
                      'p_value', 'cohens_d', 'significance_bonferroni'});

%% Process each cohort
row_idx = 1;

for cohort = cohorts
    fprintf('\nCohort: %s\n', cohort);
    
    % Within-simplex one-sample t-tests
    for simplex = simplices
        % Get data for this simplex and cohort
        simplex_cohort = sprintf('%s_%s', simplex, cohort);
        data = simplex_data_struct.(simplex_cohort);
        
        fprintf('  Simplex: %s\n', simplex);
        
        % Loop through the three tests
        for test_idx = 1:3
            test_var_name = test_vars(test_idx);
            test_type = test_types(test_idx);
            
            test_data = data.(test_var_name);
            valid_idx = ~ismissing(test_data);
            test_data_clean = test_data(valid_idx);
            num_valid = sum(valid_idx);
            
            results_table.cohort(row_idx) = cohort;
            results_table.session(row_idx) = session;
            results_table.test_type(row_idx) = test_type;
            results_table.simplex(row_idx) = simplex;
            results_table.num_valid(row_idx) = num_valid;
            
            if num_valid < 2
                warning('Insufficient data for %s, %s', simplex, test_var_name);
                results_table.t_statistic(row_idx) = NaN;
                results_table.degree_of_freedom(row_idx) = NaN;
                results_table.p_value(row_idx) = NaN;
                results_table.cohens_d(row_idx) = NaN;
                results_table.significance_bonferroni(row_idx) = missing;
            else
                [~, p_value, ~, stats] = ttest(test_data_clean);
                cohens_d = mean(test_data_clean) / std(test_data_clean);
                significance = fcn_stat_get_significance_asterisks(p_value * num_tests);
                
                results_table.t_statistic(row_idx) = stats.tstat;
                results_table.degree_of_freedom(row_idx) = stats.df;
                results_table.p_value(row_idx) = p_value;
                results_table.cohens_d(row_idx) = cohens_d;
                results_table.significance_bonferroni(row_idx) = significance;
                
                fprintf('    %s: t(%d) = %.4f, p = %.6f, d = %.4f %s\n', ...
                    test_type, stats.df, stats.tstat, p_value, cohens_d, significance);
            end
            row_idx = row_idx + 1;
        end
    end
    
    % Between-simplex paired t-tests
    comparisons = [
        "edge", "node";
        "edge", "triangle";
        "triangle", "node"
    ];
    
    fprintf('  Between-simplex comparisons:\n');
    
    for comp_idx = 1:size(comparisons, 1)
        simplex_1 = comparisons(comp_idx, 1);
        simplex_2 = comparisons(comp_idx, 2);
        
        % Get field names
        simplex_cohort_1 = sprintf('%s_%s', simplex_1, cohort);
        simplex_cohort_2 = sprintf('%s_%s', simplex_2, cohort);
        

        
        % Get data for both simplices
        data_1 = simplex_data_struct.(simplex_cohort_1).(var_name);
        data_2 = simplex_data_struct.(simplex_cohort_2).(var_name);
        
        % Remove pairs with missing data
        valid_idx = ~ismissing(data_1) & ~ismissing(data_2);
        data_1_clean = data_1(valid_idx);
        data_2_clean = data_2(valid_idx);
        num_valid = sum(valid_idx);
        
        results_table.cohort(row_idx) = cohort;
        results_table.session(row_idx) = session;
        results_table.test_type(row_idx) = sprintf("paired_%s_vs_%s", simplex_1, simplex_2);
        results_table.simplex(row_idx) = sprintf("%s-%s", simplex_1, simplex_2);
        results_table.num_valid(row_idx) = num_valid;
        
        if num_valid < 2
            warning('Insufficient valid pairs for %s vs %s', simplex_1, simplex_2);
            results_table.t_statistic(row_idx) = NaN;
            results_table.degree_of_freedom(row_idx) = NaN;
            results_table.p_value(row_idx) = NaN;
            results_table.cohens_d(row_idx) = NaN;
            results_table.significance_bonferroni(row_idx) = missing;
        else
            % Paired t-test
            [~, p_value, ~, stats] = ttest(data_1_clean, data_2_clean);
            
            % Cohen's d for paired samples
            differences = data_1_clean - data_2_clean;
            cohens_d = mean(differences) / std(differences);
            significance = fcn_stat_get_significance_asterisks(p_value * num_tests);
            
            results_table.t_statistic(row_idx) = stats.tstat;
            results_table.degree_of_freedom(row_idx) = stats.df;
            results_table.p_value(row_idx) = p_value;
            results_table.cohens_d(row_idx) = cohens_d;
            results_table.significance_bonferroni(row_idx) = significance;
            
            fprintf('    %s vs %s: t(%d) = %.4f, p = %.6f, d = %.4f %s\n', ...
                simplex_1, simplex_2, stats.df, stats.tstat, p_value, cohens_d, significance);
        end
        row_idx = row_idx + 1;
    end
end

%% Save results
fprintf('\nSaving results to: %s\n', output_filepath);
writetable(results_table, output_filepath);
fprintf('Total rows: %d\n\n', height(results_table));

end