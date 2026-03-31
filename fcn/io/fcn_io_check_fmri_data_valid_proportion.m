function fcn_io_check_fmri_data_valid_proportion()
    % Check proportion of valid (non-NA) entries in parcellated fMRI data files
    %
    % This function creates a table showing the proportion of valid numerical
    % entries (non-NA) for each task/session combination across all subjects.
    % It loads each data file and computes the fraction of non-NA entries.
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
    %   - Saves CSV table to data_pipeline/data_cohort/fmri_data_valid_proportion_by_subject.csv
    %   - Subjects as rows, task-session combinations as columns
    %   - Cell values:
    %     1.0 = all entries valid (no NA)
    %     0.0-1.0 = proportion of valid entries (partial NA contamination)
    %     0.0 = file missing, empty, or all entries are NA
    %
    % Flags files with partial NA contamination (0 < proportion < 1) during
    % the main loop. Displays heatmap visualization of the validity matrix.
    %
    % Example:
    %   fcn_io_check_fmri_data_valid_proportion();
    %
    % Scroll to the end of this function to see expected printout.
    
    %% Configuration
    
    % Get repository root from config
    config = fcn_utils_get_config();
    
    % Parameters
    PARCELLATION = "schaefer100x7";
    OUTPUT_DIR = fullfile(config.repo_root, "data_pipeline/data_cohort/");
    OUTPUT_FILENAME = "fmri_data_valid_proportion_by_subject.csv";
    
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
    
    %% Check data validity for all subjects
    
    valid_proportion = zeros(num_subjects, num_task_session_combos);
    partial_na_count = 0;
    
    fprintf('\n=== Files with partial NA contamination (0 < validity < 1) ===\n');
    
    parfor subject_idx = 1:num_subjects
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
                valid_proportion(subject_idx, combo_idx) = 0;
                continue;
            end
            
            % Build file path
            filepath = fcn_io_get_parcellated_fmri_path(HCP_FMRI_DIR, subject, ...
                                                        task, session, ...
                                                        PARCELLATION, batch);
            
            % Check if file exists and is non-empty
            if ~isfile(filepath)
                valid_proportion(subject_idx, combo_idx) = 0;
                continue;
            end
            
            file_info = dir(filepath);
            if file_info.bytes == 0
                % Empty file
                valid_proportion(subject_idx, combo_idx) = 0;
                continue;
            end
            
            % Load data and compute proportion of valid (non-NA) entries
            try
                data = readmatrix(filepath, 'FileType', 'text', 'TreatAsMissing', "NA");
                
                % Handle empty array from reading
                if isempty(data)
                    valid_proportion(subject_idx, combo_idx) = 0;
                    continue;
                end
                
                num_total = numel(data);
                num_valid = sum(~isnan(data), 'all');
                proportion = num_valid / num_total;
                valid_proportion(subject_idx, combo_idx) = proportion;
                
                % Flag files with partial NA contamination
                if proportion > 0 && proportion < 1
                    partial_na_count = partial_na_count + 1;
                    fprintf('Subject: %s, Task: %s, Session: %s, Valid: %.2f%%\n', ...
                            subject, task, session, proportion * 100);
                    fprintf('  File: %s\n', filepath);
                end
            catch
                % File exists but couldn't be read
                valid_proportion(subject_idx, combo_idx) = 0;
            end
        end
    end
    
    if partial_na_count == 0
        fprintf('No files with partial NA contamination found.\n');
    else
        fprintf('\nTotal files with partial NA contamination: %d\n', partial_na_count);
    end
    
    %% Create and save output table
    
    output_table = array2table([subjects, valid_proportion], ...
                              'VariableNames', ["Subject", task_session_combos']);
    
    output_path = fullfile(OUTPUT_DIR, OUTPUT_FILENAME);
    writetable(output_table, output_path);
    
    fprintf('\nSaved to: %s\n', output_path);
    
    %% Visualize validity matrix
    
%     figure('Position', [100, 100, 1400, 800]);
%     imagesc(valid_proportion);
%     colorbar;
%     colormap(jet);
%     caxis([0, 1]);
%     
%     xlabel('Task-Session Combination');
%     ylabel('Subject Index');
%     title('fMRI Data Validity Proportion (0 = missing/invalid, 1 = fully valid)');
%     
%     % Set x-axis labels
%     xticks(1:num_task_session_combos);
%     xticklabels(task_session_combos);
%     xtickangle(45);
%     
%     % Add grid for readability
%     grid on;
%     set(gca, 'GridColor', [0.5, 0.5, 0.5], 'GridAlpha', 0.3);
    
    % % Summary statistics (commented out as requested)
    % num_complete_scans = sum(valid_proportion == 1, 'all');
    % num_total_possible = num_subjects * num_task_session_combos;
    % mean_validity = mean(valid_proportion, 'all');
    % median_validity = median(valid_proportion, 'all');
    % 
    % fprintf('\nSummary Statistics:\n');
    % fprintf('Complete scans (100%% valid): %d / %d (%.1f%%)\n', ...
    %         num_complete_scans, num_total_possible, ...
    %         100 * num_complete_scans / num_total_possible);
    % fprintf('Mean validity: %.2f%%\n', mean_validity * 100);
    % fprintf('Median validity: %.2f%%\n', median_validity * 100);

% Loading batch table...
% Found 1095 unique subjects in batch table
% Checking 18 task-session combinations
% 
% 
% === Files with partial NA contamination (0 < validity < 1) ===
% Starting parallel pool (parpool) using the 'Processes' profile ...
% Connected to the parallel pool (number of workers: 4).
% Subject 50 / 1095
% Subject: 1.865450e+05, Task: MOTOR, Session: LR, Valid: 2.11%
% Subject 300 / 1095
% Subject 550 / 1095
% Subject 150 / 1095
%   File: /oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/xah/sub-186545_task-MOTOR_acq-LR/fcon/schaefer100x7/sub-186545_task-MOTOR_acq-LR_schaefer100x7_ts.1D
% Subject 400 / 1095
% Subject: 1.505240e+05, Task: MOTOR, Session: LR, Valid: 2.11%
%   File: /oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/xae/sub-150524_task-MOTOR_acq-LR/fcon/schaefer100x7/sub-150524_task-MOTOR_acq-LR_schaefer100x7_ts.1D
% Subject 250 / 1095
% Subject: 1.737380e+05, Task: EMOTION, Session: RL, Valid: 3.41%
% Subject 100 / 1095
% Subject 500 / 1095
%   File: /oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/xag/sub-173738_task-EMOTION_acq-RL/fcon/schaefer100x7/sub-173738_task-EMOTION_acq-RL_schaefer100x7_ts.1D
% Subject 350 / 1095
% Subject 200 / 1095
% Subject 700 / 1095
% Subject 450 / 1095
% Subject 750 / 1095
% Subject 800 / 1095
% Subject 650 / 1095
% Subject 600 / 1095
% Subject: 2.518330e+05, Task: GAMBLING, Session: RL, Valid: 2.37%
%   File: /oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/xak/sub-251833_task-GAMBLING_acq-RL/fcon/schaefer100x7/sub-251833_task-GAMBLING_acq-RL_schaefer100x7_ts.1D
% Subject: 2.499470e+05, Task: SOCIAL, Session: RL, Valid: 2.19%
% Subject 900 / 1095
%   File: /oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/xak/sub-249947_task-SOCIAL_acq-RL/fcon/schaefer100x7/sub-249947_task-SOCIAL_acq-RL_schaefer100x7_ts.1D
% Subject: 2.361300e+05, Task: EMOTION, Session: LR, Valid: 3.41%
% Subject: 5.416400e+05, Task: SOCIAL, Session: RL, Valid: 2.19%
%   File: /oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/xak/sub-236130_task-EMOTION_acq-LR/fcon/schaefer100x7/sub-236130_task-EMOTION_acq-LR_schaefer100x7_ts.1D
% Subject 850 / 1095
%   File: /oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/xao/sub-541640_task-SOCIAL_acq-RL/fcon/schaefer100x7/sub-541640_task-SOCIAL_acq-RL_schaefer100x7_ts.1D
% Subject 950 / 1095
% Subject 1000 / 1095
% Subject 1050 / 1095
% 
% Total files with partial NA contamination: 7
% 
% Saved to: /home/users/siuc/edge_time_series_mapper/data_pipeline/data_cohort/fmri_data_valid_proportion_by_subject.csv


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

function fcn_io_plot_fmri_na_pattern(filepath, subject, task, session)
    % Plot the spatial and temporal pattern of NA values in fMRI timeseries data
    %
    % INPUTS:
    %   filepath - string, full path to the fMRI timeseries file
    %   subject  - string, subject ID (for plot title)
    %   task     - string, task name (for plot title)
    %   session  - string, session identifier (for plot title)
    %
    % OUTPUT:
    %   Saves a figure showing:
    %     - Heatmap of the data matrix (NA shown as distinct color)
    %     - Row-wise and column-wise NA counts
    %
    % The plot is saved to the same directory as the input file with
    % suffix '_na_pattern.png'
    %
    % Example:
    %   fcn_io_plot_fmri_na_pattern('/path/to/data.1D', '236130', 'EMOTION', 'LR');
    
    % Load data
    data = readmatrix(filepath, 'FileType', 'text', 'TreatAsMissing', "NA");
    
    % Get dimensions
    [num_timepoints, num_parcels] = size(data);
    
    % Compute NA pattern
    is_na = isnan(data);
    na_per_timepoint = sum(is_na, 2);  % NAs across parcels for each timepoint
    na_per_parcel = sum(is_na, 1);     % NAs across timepoints for each parcel
    total_na = sum(is_na, 'all');
    total_elements = numel(data);
    na_percent = 100 * total_na / total_elements;
    
    % Create figure
    fig = figure('Position', [100, 100, 1200, 800]);
    
    % Main heatmap
    subplot(3, 3, [1, 2, 4, 5, 7, 8]);
    imagesc(data');
    colorbar;
    xlabel('Timepoint');
    ylabel('Parcel');
    title(sprintf('Subject %s: %s %s (%.2f%% NA)', subject, task, session, na_percent));
    
    % NA count per timepoint
    subplot(3, 3, [3, 6, 9]);
    barh(1:num_parcels, na_per_parcel);
    xlabel('NA count');
    ylabel('Parcel');
    title('NAs per parcel');
    ylim([0.5, num_parcels + 0.5]);
    set(gca, 'YDir', 'reverse');
    
    % NA count per parcel (top)
    subplot(3, 3, [1, 2]);
    bar(1:num_timepoints, na_per_timepoint);
    ylabel('NA count');
    title('NAs per timepoint');
    xlim([0.5, num_timepoints + 0.5]);
    
    % Save figure
    [filepath_dir, filepath_base, ~] = fileparts(filepath);
    output_path = fullfile(filepath_dir, sprintf('%s_na_pattern.png', filepath_base));
    saveas(fig, output_path);
    close(fig);
    
    fprintf('  Saved NA pattern plot: %s\n', output_path);
end