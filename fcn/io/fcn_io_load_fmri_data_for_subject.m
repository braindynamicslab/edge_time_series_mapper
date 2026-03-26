function [data_cell, missing_data_flag] = fcn_io_load_fmri_data_for_subject(subject, tasks, session, ...
                                                                        rest_session, parcellation, config, varargin)
    % Load fMRI timeseries data for all specified tasks
    %
    % Loads parcellated fMRI data from xcpengine output without any
    % preprocessing or truncation. Returns raw data for all tasks.
    %
    % Inputs:
    %   subject - Subject ID number
    %   tasks - String array of task names (e.g., ["REST", "WM", "MOTOR"])
    %   session - Session identifier for task data ("LR" or "RL")
    %   rest_session - Session identifier for REST data (e.g., "LR_run-1")
    %   parcellation - Parcellation name (e.g., "schaefer100x7")
    %   config - Configuration struct with fields:
    %            .hcp_fmri_dir - Base directory for fMRI data
    %            .batch_table_path - Path to batch assignment CSV
    %
    % Optional Parameters (name-value pairs):
    %   'verbose_flag' - Print progress messages: 1=yes, 0=no (default: 1)
    %
    % Outputs:
    %   data_cell - Cell array where each element is a [timepoints x ROIs]
    %               matrix of timeseries data for one task
    %   missing_data_flag - 1 if any data files are missing, 0 otherwise
    %
    % Example:
    %   config = fcn_utils_get_config();
    %   tasks = ["REST", "WM", "MOTOR"];
    %   [data_cell, missing] = fcn_io_load_data_for_subject(subject, tasks, "LR", ...
    %                                                        "LR_run-1", "schaefer100x7", config);
    %   if missing
    %       return;  % Skip this subject
    %   end
    %
    %   % Silent mode
    %   [data_cell, missing] = fcn_io_load_data_for_subject(subject, tasks, "LR", ...
    %                                                        "LR_run-1", "schaefer100x7", config, ...
    %                                                        'verbose_flag', 0);
    %
    % See also: fcn_io_get_parcellated_fmri_path, fcn_io_lookup_batch_table
    
    %% Parse inputs
    
    p = inputParser;
    addRequired(p, 'subject', @isnumeric);
    addRequired(p, 'tasks', @isstring);
    addRequired(p, 'session', @isStringScalar);
    addRequired(p, 'rest_session', @isStringScalar);
    addRequired(p, 'parcellation', @isStringScalar);
    addRequired(p, 'config', @isstruct);
    addParameter(p, 'verbose_flag', 1, @isnumeric);
    parse(p, subject, tasks, session, rest_session, parcellation, config, varargin{:});
    
    verbose_flag = p.Results.verbose_flag;
    
    %% Load data
    
    num_tasks = numel(tasks);
    data_cell = cell(num_tasks, 1);
    missing_data_flag = 0;
    
    % Load batch table
    batch_table = readtable(config.batch_table_path, ...
                           "TextType", "string", ...
                           "VariableNamingRule", "preserve");
    
    % Load data for each task
    for task_idx = 1:num_tasks
        task = tasks(task_idx);
        
        % Determine session (REST uses different session identifier)
        if strcmp(task, "REST")
            task_session = rest_session;
        else
            task_session = session;
        end
        
        if verbose_flag
            fprintf('  Loading %s (%s)... ', task, task_session);
        end
        
        % Look up batch identifier
        batch = fcn_io_lookup_batch_table(batch_table, subject, task, task_session);
        if strlength(batch) == 0
            warning('Batch not found for subject %d, task %s, session %s', ...
                    subject, task, task_session);
            missing_data_flag = 1;
            continue;
        end
        
        % Construct filepath
        filepath = fcn_io_get_parcellated_fmri_path(config.hcp_fmri_dir, ...
                                                    subject, task, task_session, ...
                                                    parcellation, batch);
        
        % Check if file exists
        if ~isfile(filepath)
            warning('File not found: %s', filepath);
            missing_data_flag = 1;
            continue;
        end
        
        % Load data
        data_cell{task_idx} = load(filepath);
        
        if verbose_flag
            fprintf('Done (%d timepoints x %d ROIs)\n', ...
                    size(data_cell{task_idx}, 1), size(data_cell{task_idx}, 2));
        end
    end
    
    if missing_data_flag
        warning('Missing data for subject %d', subject);
    end
end