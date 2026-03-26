function fcn_io_check_fmri_data_availability()
    % Check which parcellated fMRI data files exist for HCP subjects
    %
    % This function creates a table showing which task/session combinations
    % have available preprocessed fMRI data for all subjects in the batch table.
    % It checks both file existence and non-zero file size to catch failed
    % preprocessing runs that may have created empty output files.
    %
    % No inputs required - all paths and parameters are configured internally.
    %
    % Data structure:
    %   - fMRI data preprocessed by xcpengine, stored on Oak
    %   - Each scan has format: sub-<subject>_task-<task>_acq-<session>
    %   - Sessions: LR, RL (for most tasks)
    %   - REST has additional run identifier: LR_run-1, LR_run-2, RL_run-1, RL_run-2
    %   - Preprocessing was done in batches (xaa, xab, xac, etc.)
    %   - Batch assignment tracked in subject_batch.csv
    %
    % Tasks (8 total):
    %   - REST (resting state)
    %   - EMOTION, GAMBLING, LANGUAGE, MOTOR, RELATIONAL, SOCIAL, WM (7 tasks)
    %
    % Complete data for one session:
    %   - All 7 tasks + REST run-1 in same session (LR or RL)
    %   - Note: We only use run-1 for REST in subsequent analyses,
    %     but this function checks all runs for completeness documentation
    %
    % Output:
    %   - Saves CSV table to data_pipeline/data_cohort/fmri_data_availability.csv
    %   - Subjects as rows, task-session combinations as columns
    %   - Cell values:
    %     1 = file exists and non-empty
    %     0 = file missing, empty, or batch info not found
    %
    % Example:
    %   fcn_io_check_fmri_data_availability();
    
    %% Configuration
    
    % Get repository root from config
    config = fcn_utils_get_config();
    
    % Parameters
    PARCELLATION = "schaefer100x7";
    OUTPUT_DIR = fullfile(config.repo_root, "data_pipeline/data_cohort/");
    OUTPUT_FILENAME = "fmri_data_availability_by_subject.csv";
    
    % Paths
    BATCH_TABLE_PATH = config.batch_table_path;
    HCP_FMRI_DIR = config.hcp_fmri_dir;
    
    % Create output directory if needed
    if ~exist(OUTPUT_DIR, 'dir')
        mkdir(OUTPUT_DIR);
        fprintf('Created output directory: %s\n', OUTPUT_DIR);
    end
    
    % Task and session definitions
    TASKS = ["REST", "EMOTION", "GAMBLING", "LANGUAGE", "MOTOR", "RELATIONAL", "SOCIAL", "WM"];
    REST_SESSIONS = ["LR_run-1", "LR_run-2", "RL_run-1", "RL_run-2"];
    TASK_SESSIONS = ["LR", "RL"];
    
    %% Load batch table and extract unique subjects
    
    fprintf('Loading batch table...\n');
    batch_table = readtable(BATCH_TABLE_PATH, ...
                            "TextType", "string", ...
                            "VariableNamingRule", "preserve");
    
    subjects = unique(batch_table.subject);
    num_subjects = numel(subjects);
    
    fprintf('Found %d unique subjects in batch table\n', num_subjects);
    
    %% Build task-session combinations
    
    % Format: "TASK,SESSION" (e.g., "WM,LR", "REST,LR_run-1")
    task_session_combos = build_task_session_combinations(TASKS, TASK_SESSIONS, REST_SESSIONS);
    num_task_session_combos = numel(task_session_combos);
    
    fprintf('Checking %d task-session combinations\n\n', num_task_session_combos);
    
    %% Check file existence for all subjects
    
    data_exists = false(num_subjects, num_task_session_combos);
    
    for subject_idx = 1:num_subjects
        if mod(subject_idx, 50) == 0
            fprintf('Subject %d / %d\n', subject_idx, num_subjects);
        end
        
        subject = subjects(subject_idx);
        
        for combo_idx = 1:num_task_session_combos
            task_session = task_session_combos(combo_idx);
            
            % Parse task and session
            parts = split(task_session, ",");
            task = parts(1);
            session = parts(2);
            
            % Look up batch (returns "" if not found)
            batch = fcn_io_lookup_batch_table(batch_table, subject, task, session);
            if strlength(batch) == 0
                % Batch not found - file doesn't exist
                continue;
            end
            
            % Build file path
            filepath = fcn_io_get_parcellated_fmri_path(HCP_FMRI_DIR, subject, ...
                                                        task, session, ...
                                                        PARCELLATION, batch);
            
            % Check if file exists and is non-empty (empty files = failed preprocessing)
            data_exists(subject_idx, combo_idx) = isfile(filepath) && (dir(filepath).bytes > 0);
        end
    end
    
    %% Create and save output table
    
    output_table = array2table([subjects, data_exists], ...
                              'VariableNames', ["Subject", task_session_combos']);
    
    output_path = fullfile(OUTPUT_DIR, OUTPUT_FILENAME);
    writetable(output_table, output_path);
    
    % Summary statistics
    num_complete_scans = sum(data_exists, 'all');
    num_total_possible = num_subjects * num_task_session_combos;
    completion_rate = 100 * num_complete_scans / num_total_possible;
    
    fprintf('\nResults: %d / %d scans available (%.1f%%)\n', ...
            num_complete_scans, num_total_possible, completion_rate);
    fprintf('Saved to: %s\n', output_path);
end

%% Helper functions

function combos = build_task_session_combinations(tasks, task_sessions, rest_sessions)
    % Build all task-session combination strings
    
    % Separate REST from other tasks
    rest_idx = strcmp(tasks, "REST");
    other_tasks = tasks(~rest_idx);
    
    % Build combinations for non-REST tasks
    num_other_tasks = numel(other_tasks);
    num_task_sessions = numel(task_sessions);
    
    [task_grid, session_grid] = ndgrid(1:num_other_tasks, 1:num_task_sessions);
    other_combos = strcat(other_tasks(task_grid(:)), ",", task_sessions(session_grid(:)));
    
    % Build combinations for REST
    rest_combos = strcat("REST,", rest_sessions(:));
    
    % Ensure both are column vectors before concatenating
    other_combos = other_combos(:);
    rest_combos = rest_combos(:);
    
    % Combine all
    combos = [other_combos; rest_combos];
end

