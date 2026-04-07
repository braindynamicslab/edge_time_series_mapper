% # Comparison of Node Modularity: Old vs New Pipeline
%
% This script compares modularity values between two data processing pipelines for the Schaefer 100x7 parcellation.
%
% **Data sources:**
% - **New data**: `simplex_mapper_raw_features_cohort_one_LR_node_schaefer100x7/summary_raw.csv` (mapper_stat_modularity)
% - **Old data**: `expt_250829_noFeatureMassaging_cohort_one_LR_schaefer100x7.csv` (node_mod)
% - **Cohort**: `cohort_one_session_LR.csv`
%
% **Analysis:**
% 1. Merge cohort subjects with old and new modularity values
% 2. Identify missing data (NA) in new dataset
% 3. Compute maximum absolute and relative errors
% 4. Visualize correlation via scatter plot

% cohort one session LR triangle parcellation has low correlation with old
% data (0.96667, the others are above 0.997)
% cohort one session RL triangle parcellation schaefer100x7 has 1 NA
% in new data
%
%% Load data

cohort = "";
session = "LR";
% simplex = "node";
simplex = "edge";
parcellation = "schaefer100x7";

for cohort = ["one", "two"]
    for session = ["LR", "RL"]
        for simplex = ["node", "edge", "triangle"]

            if strcmp(cohort, "one")
                cohort_storage = "one";
            else
                cohort_storage = "all_but_one";
            end

            cohort_file = sprintf('/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/data_cohort/cohort_%s_session_%s.csv', cohort, session);
            old_file = sprintf('/Users/siuc/Documents/GitHub/brain_HOI/data_output_lightweight/expt_250829_noFeatureMassaging_cohort_%s_%s_%s.csv', cohort, session, parcellation);
            new_file = sprintf('/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/simplex_mapper_raw_features_cohort_%s_%s_%s_%s/summary_raw.csv', cohort_storage, session, simplex, parcellation);

            cohort_tbl = readtable(cohort_file, 'VariableNamingRule', 'preserve');
            old_tbl = readtable(old_file, 'VariableNamingRule', 'preserve');
            new_tbl = readtable(new_file, 'VariableNamingRule', 'preserve');

            %% Rename columns for consistent merging
            cohort_tbl.Properties.VariableNames{'Subject'} = 'subject';
            old_tbl.Properties.VariableNames{'Subject'} = 'subject';

            %% Select relevant columns
            old_column_name = sprintf('%s_mod', simplex);
            old_subset = old_tbl(:, {'subject', old_column_name});
            new_subset = new_tbl(:, {'subject', 'mapper_stat_modularity'});

            %% Join tables
            % First join cohort with old data
            merged_tbl = outerjoin(cohort_tbl, old_subset, 'Keys', 'subject', 'MergeKeys', true, 'Type', 'left');

            % Then join with new data
            merged_tbl = outerjoin(merged_tbl, new_subset, 'Keys', 'subject', 'MergeKeys', true, 'Type', 'left');

            %% Count NA in new data
            fprintf("cohort %s session %s simplex %s parcellation %s\n", cohort, session, simplex, parcellation);
            num_na_new = sum(isnan(merged_tbl.mapper_stat_modularity));
            fprintf('Number of NA in new data: %d\n', num_na_new);

            %% Compute errors for rows with both old and new data
            valid_idx = ~isnan(merged_tbl.(old_column_name)) & ~isnan(merged_tbl.mapper_stat_modularity);
            old_vals = merged_tbl.(old_column_name)(valid_idx);
            new_vals = merged_tbl.mapper_stat_modularity(valid_idx);

            abs_errors = abs(new_vals - old_vals);
            rel_errors = abs_errors ./ abs(old_vals);

            max_abs_error = max(abs_errors);
            max_rel_error = max(rel_errors);

            fprintf('Maximum absolute error: %.10f\n', max_abs_error);
            fprintf('Maximum relative error: %.10f (%.4f%%)\n', max_rel_error, max_rel_error * 100);
            fprintf('Cohort-wide correlation: %.10f\n', corr(old_vals, new_vals))

            %% Scatter plot
            figure;
            scatter(old_vals, new_vals, 50, 'filled', 'MarkerFaceAlpha', 0.6);
            hold on;
            % Add diagonal reference line
            min_val = min([old_vals; new_vals]);
            max_val = max([old_vals; new_vals]);
            plot([min_val, max_val], [min_val, max_val], 'r--', 'LineWidth', 1.5);
            hold off;

            xlabel('old mod');
            ylabel('new mod');
            title(sprintf('cohort: %s, session: %s, parcellation: %s, simplex: %s', cohort, session, parcellation, simplex));
            grid on;
            axis equal;

        end
    end
end