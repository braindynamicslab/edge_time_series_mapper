% Stand-alone script to test correlations with FC
% Tests whether each measure's correlation with FC is significantly different from 0

% USER OPTION: Set to true to reload data from scratch, false to use workspace variables
reload_data = true;
clc;

%% Configuration

config = fcn_utils_get_config();
tasks = ["REST", "EMOTION", "GAMBLING", "LANGUAGE", "MOTOR", "RELATIONAL", "SOCIAL", "WM"];
parcellation = "schaefer100x7";
simplex = "edge";
selected_rows = [1 3 2];
pretty_row_names = ["Traditional", "Peak-Frame", "Peak-Dense-Pure-Node"];

amplitude_threshold = 0.9;

input_data_directory = fullfile(config.scratch_dir, "data_pipeline/high_amplitude_functional_connectivity/");
output_data_directory = fullfile(config.repo_root, "data_pipeline/stat_high_amplitude_functional_connectivity");
if ~isfolder(output_data_directory)
    mkdir(output_data_directory);
end

%% Data loading section
if reload_data
    fprintf('\n=== RELOADING DATA FROM FILES ===\n');
    
    % Initialize storage for all cohorts and sessions
    all_data = struct();
    
    for cohort = ["one", "two"]
        for session = ["LR"]
            fprintf('\n=== Processing Cohort %s, Session %s ===\n', cohort, session);
            
            % Load subject list
            sublist_csv = sprintf("/home/users/siuc/brain_HOI/data_cohort/cohort_%s_xcpengine2025_session_%s.txt", cohort, session);
            subjects = readtable(sublist_csv).Subject;
            
            % Initialize data structure
            corrs_between_measures_across_tasks = cell(numel(tasks), 1);
            corrs_between_measures_across_tasks(:) = {NaN(numel(pretty_row_names), numel(pretty_row_names), numel(subjects))};
            
            % Load data for each subject
            for subject_id = 1:numel(subjects)
                subject = subjects(subject_id);
                fprintf('  Loading subject %d (%d/%d)\n', subject, subject_id, numel(subjects));
                
                input_data_filename = sprintf("high_amplitude_functional_connectivity_%d_%s_%s_%s_data.mat", ...
                    subject, session, simplex, parcellation);
                
                try
                    high_amplitude_functional_connectivity_data = matfile(fullfile(input_data_directory, input_data_filename));
                    subject_functional_connectivity_cell = high_amplitude_functional_connectivity_data.subject_functional_connectivity_cell;
                    
                    % Compute correlations for each task
                    for task_id = 1:numel(tasks)
                        task_corr_mat = corr(subject_functional_connectivity_cell{task_id}');
                        corrs_between_measures_across_tasks{task_id}(1:size(task_corr_mat, 1), 1:size(task_corr_mat, 2), subject_id) = task_corr_mat;
                    end
                catch
                    fprintf('    No data for subject %d\n', subject);
                    continue;
                end
            end
            
            % Store data in structure
            field_name = sprintf('cohort_%s_session_%s', cohort, session);
            all_data.(field_name) = corrs_between_measures_across_tasks;
        end
    end
    
    fprintf('\n=== DATA LOADING COMPLETE ===\n');
else
    fprintf('\n=== USING EXISTING WORKSPACE DATA ===\n');
    if ~exist('all_data', 'var')
        error('Variable "all_data" not found in workspace. Set reload_data = true to load data from files.');
    end
    fprintf('Found existing data structure in workspace.\n');
end

%% Analysis section - always runs
for cohort = ["one", "two"]
    for session = ["LR"]
        fprintf('\n=== Analyzing Cohort %s, Session %s ===\n', cohort, session);
        
        % Retrieve data from structure
        field_name = sprintf('cohort_%s_session_%s', cohort, session);
        corrs_between_measures_across_tasks = all_data.(field_name);
        
        % Perform t-tests for correlations with FC
        results_table = table();
        
        for task_id = 1:numel(tasks)
            for row = 2:numel(selected_rows)  % Skip row 1 (FC with itself)
                % Get individual subject correlations with FC (column 1)
                individual_correlations = squeeze(corrs_between_measures_across_tasks{task_id}(selected_rows(row), 1, :));
                
                % Remove NaN values
                individual_correlations = individual_correlations(~isnan(individual_correlations));
                
                % Calculate mean
                mean_r = mean(individual_correlations);
                
                % Perform one-sample t-test against 0
                [~, p_value, ci, stats] = ttest(individual_correlations, 0);
                t_stat = stats.tstat;
                n_subjects = numel(individual_correlations);
                
                % Extract confidence interval bounds
                conf_interval_lower = ci(1);
                conf_interval_upper = ci(2);
                
                % Add row to results table
                new_row = table({tasks{task_id}}, {pretty_row_names{selected_rows(row)}}, ...
                    n_subjects, mean_r, conf_interval_lower, conf_interval_upper, t_stat, p_value, ...
                    'VariableNames', {'Task', 'Measure', 'N', 'Mean_r', 'Conf_Interval_Lower', 'Conf_Interval_Upper', 'T_Stat', 'P_Value'});
                results_table = [results_table; new_row];
            end
        end
        
        % Display results with 3 significant figures
        fprintf('\n--- Results for Cohort %s, Session %s ---\n', cohort, session);
        display_table = results_table;
        display_table.Mean_r = round(display_table.Mean_r, 3, 'significant');
        display_table.Conf_Interval_Lower = round(display_table.Conf_Interval_Lower, 3, 'significant');
        display_table.Conf_Interval_Upper = round(display_table.Conf_Interval_Upper, 3, 'significant');
        display_table.T_Stat = round(display_table.T_Stat, 3, 'significant');
        display_table.P_Value = round(display_table.P_Value, 3, 'significant');
        disp(display_table);
        
        % Save to CSV with 3 significant figures
        output_table = results_table;
        output_table.Mean_r = round(output_table.Mean_r, 3, 'significant');
        output_table.Conf_Interval_Lower = round(output_table.Conf_Interval_Lower, 3, 'significant');
        output_table.Conf_Interval_Upper = round(output_table.Conf_Interval_Upper, 3, 'significant');
        output_table.T_Stat = round(output_table.T_Stat, 3, 'significant');
        output_table.P_Value = round(output_table.P_Value, 3, 'significant');

        output_table.Properties.VariableNames = {'Task', 'Measure', 'N', 'Mean Correlation', 'Confidence Interval (Lower Bound)', 'Confidence Interval (Upper Bound)', 't-stat', 'p-value'};
        
        output_filename = sprintf('correlation_with_FC_stats_%s_%s.csv', cohort, session);
        writetable(output_table, fullfile(output_data_directory, output_filename));
        fprintf('Results saved to: %s\n', fullfile(output_data_directory, output_filename));
    end
end
