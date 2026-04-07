%% Check shuffled modularity: compare old vs new data

cohorts = ["one", "two"];
sessions = ["LR"];
simplex = "edge";
thresholds = [90, 95];

for cohort = cohorts
    for session = sessions
        fprintf('\n=== Cohort: %s, Session: %s ===\n', cohort, session);
        
        % Get subject list
        cohort_file = sprintf('/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/data_cohort/cohort_%s_session_%s.csv', cohort, session);
        subjects_table = readtable(cohort_file, 'VariableNamingRule', 'preserve');
        
        % Load old data
        old_file = sprintf('/Users/siuc/Documents/GitHub/brain_HOI/data_output_lightweight/shuffling_high_amplitude/shuffling_high_amplitude_all_simplices_noFeatureMassaging_%s_%s_schaefer100x7_80_90_95.txt', cohort, session);
        old_data = readtable(old_file, 'VariableNamingRule', 'preserve');
        
        % Load new data
        new_file = sprintf('/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/shuffled_modularity/shuffled_modularity_mean_%s_%s_peak_75_purity_95.csv', cohort, session);
        new_data = readtable(new_file, 'VariableNamingRule', 'preserve');
        
        % Extract relevant columns from old data
        old_cols = {'Subject', sprintf('%s_none', simplex), sprintf('%s_all', simplex)};
        for threshold = thresholds
            old_cols{end+1} = sprintf('%s_high_amp_%d', simplex, threshold);
            old_cols{end+1} = sprintf('%s_matched_num_nodes_%d', simplex, threshold);
        end
        old_data_subset = old_data(:, old_cols);
        
        % Extract relevant columns from new data
        new_cols = {'Subject', 'none', 'all'};
        for threshold = thresholds
            new_cols{end+1} = sprintf('peak_dense_%d', threshold);
            new_cols{end+1} = sprintf('matched_random_%d', threshold);
        end
        new_data_subset = new_data(:, new_cols);
        
        % Join tables
        merged_table = outerjoin(subjects_table(:, "Subject"), old_data_subset, ...
            'Keys', 'Subject', 'Type', 'left', 'MergeKeys', true);
        merged_table = outerjoin(merged_table, new_data_subset, ...
            'Keys', 'Subject', 'Type', 'left', 'MergeKeys', true);
        
        % Check for missing data in new columns
        fprintf('\nMissing data check:\n');
        for col_idx = (width(subjects_table) + width(old_data_subset)):width(merged_table)
            col_name = merged_table.Properties.VariableNames{col_idx};
            missing_subjects = merged_table.Subject(isnan(merged_table{:, col_idx}));
            if ~isempty(missing_subjects)
                fprintf('  Column "%s" missing for subjects: %s\n', col_name, mat2str(missing_subjects'));
            end
        end
        
        % Compute correlations between corresponding columns
        fprintf('\nCorrelations:\n');
        
        % none vs none
        old_none_col = sprintf('%s_none', simplex);
        corr_none = corr(merged_table.(old_none_col), merged_table.none, 'rows', 'complete');
        fprintf('  %s vs none: r = %.4f\n', old_none_col, corr_none);
        
        % all vs all
        old_all_col = sprintf('%s_all', simplex);
        corr_all = corr(merged_table.(old_all_col), merged_table.all, 'rows', 'complete');
        fprintf('  %s vs all: r = %.4f\n', old_all_col, corr_all);
        
        % high_amp vs peak_dense and matched_num_nodes vs matched_random
        for threshold = thresholds
            old_high_amp_col = sprintf('%s_high_amp_%d', simplex, threshold);
            new_peak_dense_col = sprintf('peak_dense_%d', threshold);
            corr_high_amp = corr(merged_table.(old_high_amp_col), merged_table.(new_peak_dense_col), 'rows', 'complete');
            fprintf('  %s vs %s: r = %.4f\n', old_high_amp_col, new_peak_dense_col, corr_high_amp);
            
            old_matched_col = sprintf('%s_matched_num_nodes_%d', simplex, threshold);
            new_matched_col = sprintf('matched_random_%d', threshold);
            corr_matched = corr(merged_table.(old_matched_col), merged_table.(new_matched_col), 'rows', 'complete');
            fprintf('  %s vs %s: r = %.4f\n', old_matched_col, new_matched_col, corr_matched);
        end
    end
end