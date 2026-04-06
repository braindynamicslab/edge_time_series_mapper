function fcn_io_generate_mean_head_motion_csv()
    % Generate mean head motion CSV files for all subjects in cohort
    %
    % Loops through subject lists for each session (LR/RL), computes mean
    % framewise displacement for each subject, and saves results to CSV files.
    %
    % Inputs: None (uses fcn_utils_get_config for paths)
    %
    % Outputs: CSV files saved to <repo_root>/data_pipeline_gitignore/mean_head_motion/
    %          mean_head_motion_cohort_<cohort>_session_<session>.csv
    %          Columns: Subject, mean_head_motion
    %
    % Example:
    %   fcn_io_generate_mean_head_motion_csv();
    %
    % See also: fcn_io_get_mean_head_motion, fcn_utils_get_config
    
    %% Get configuration
    config = fcn_utils_get_config();
    
    %% Define output filenames upfront
    cohort = "all";
    sessions = ["LR", "RL"];
    
    %% Create output directory
    output_dir = fullfile(config.repo_root, "data_pipeline_gitignore", "mean_head_motion");
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    %% Process each session
    for session_idx = 1:length(sessions)
        session = sessions(session_idx);
        
        fprintf('\n========================================\n');
        fprintf('Processing Session: %s\n', session);
        fprintf('========================================\n\n');
        
        % Load subject list
        cohort_file = fullfile(config.repo_root, "data_pipeline", "data_cohort", ...
            sprintf("cohort_%s_session_%s.csv", cohort, session));
        
        if ~isfile(cohort_file)
            warning('Cohort file not found: %s', cohort_file);
            continue;
        end
        
        subject_table = readtable(cohort_file, "TextType", "string", ...
                                  "VariableNamingRule", "preserve");
        subjects = subject_table.Subject;
        num_subjects = length(subjects);
        
        fprintf('Found %d subjects in cohort file\n', num_subjects);
        fprintf('Processing...\n\n');
        
        % Initialize results
        mean_head_motion_values = nan(num_subjects, 1);
        
        % Process each subject
        for subj_idx = 1:num_subjects
            subject = subjects(subj_idx);
            
            try
                mean_head_motion = fcn_io_get_mean_head_motion(subject, session, ...
                    'verbose_flag', 0);
                mean_head_motion_values(subj_idx) = mean_head_motion;
                
                fprintf('  Subject %d (%d/%d): Mean FD = %.4f mm\n', ...
                    subject, subj_idx, num_subjects, mean_head_motion);
            catch ME
                warning('Error processing subject %d: %s', subject, ME.message);
                mean_head_motion_values(subj_idx) = nan;
            end
        end
        
        % Create results table
        results_table = table(subjects, mean_head_motion_values, ...
            'VariableNames', {'Subject', 'mean_head_motion'});
        
        % Save to CSV
        output_file = fullfile(output_dir, ...
            sprintf("mean_head_motion_cohort_%s_session_%s.csv", cohort, session));
        writetable(results_table, output_file);
        
        fprintf('\n✓ Saved results to: %s\n', output_file);
        fprintf('  Valid subjects: %d/%d\n', sum(~isnan(mean_head_motion_values)), num_subjects);
        fprintf('  Mean FD (valid subjects): %.4f mm\n\n', ...
            mean(mean_head_motion_values, 'omitnan'));
    end
    
    fprintf('========================================\n');
    fprintf('All sessions processed!\n');
    fprintf('========================================\n\n');
end