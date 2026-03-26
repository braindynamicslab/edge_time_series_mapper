function [starting_times, ending_times, unit_time, seconds_per_TR] = ...
    fcn_edgeMapper_get_time_windows(tasks_string, task_configuration)
    % Get time windows for task data extraction
    %
    % Returns time ranges to extract from each task based on configuration.
    % For most configurations, returns defaults (full task length).
    % For rest_5min_and_tasks, limits REST to first 5 minutes.
    %
    % Inputs:
    %   tasks_string - String array of task names (e.g., ["REST", "WM", "MOTOR"])
    %   task_configuration - Configuration string:
    %                        "rest_5min_and_tasks" - First 5 minutes of REST only
    %                        "rest_all_and_tasks" - Full REST data
    %                        "tasks_only" - Full task data (no REST)
    %
    % Outputs:
    %   starting_times - [num_tasks x 1] Start time for each task (0 = beginning)
    %   ending_times - [num_tasks x 1] End time for each task (Inf = full length)
    %   unit_time - Time unit: "seconds" (always returns seconds for HCP data)
    %   seconds_per_TR - TR duration in seconds (HCP: 0.72s)
    %
    % Example:
    %   tasks = ["REST", "WM", "MOTOR"];
    %   
    %   % Get 5-minute REST window
    %   [start, end_time, unit, tr] = fcn_edgeMapper_get_time_windows(tasks, "rest_5min_and_tasks");
    %   % Returns: start = [0; 0; 0], end_time = [300; Inf; Inf], unit = "seconds", tr = 0.72
    %   
    %   % Get full data
    %   [start, end_time, unit, tr] = fcn_edgeMapper_get_time_windows(tasks, "rest_all_and_tasks");
    %   % Returns: start = [0; 0; 0], end_time = [Inf; Inf; Inf], unit = "seconds", tr = 0.72
    %
    % See also: fcn_edgeMapper_preprocess_data, fcn_edgeMapper_get_processed_edge_time_series_data
    
    % HCP-specific parameters
    % Reference: https://www.humanconnectome.org/hcp-protocols-ya-3t-imaging
    SECONDS_PER_TR = 0.72;
    REST_DURATION_SECONDS = 5 * 60;  % 5 minutes = 300 seconds
    
    % Validate inputs
    assert(isstring(tasks_string), ...
        'tasks_string must be string array, got %s', class(tasks_string));
    assert(isStringScalar(task_configuration) || ischar(task_configuration), ...
        'task_configuration must be string scalar or char, got %s', class(task_configuration));
    
    % Convert to string
    tasks_string = string(tasks_string);
    task_configuration = string(task_configuration);
    
    num_tasks = numel(tasks_string);
    
    % Defaults: extract full length of all tasks
    starting_times = zeros(num_tasks, 1);
    ending_times = inf(num_tasks, 1);
    unit_time = "seconds";
    seconds_per_TR = SECONDS_PER_TR;
    
    % Apply configuration-specific windowing
    if strcmp(task_configuration, "rest_5min_and_tasks")
        % Limit REST to first 5 minutes
        is_rest = strcmp(tasks_string, "REST");
        ending_times(is_rest) = REST_DURATION_SECONDS;
        
    elseif strcmp(task_configuration, "rest_all_and_tasks")
        % Use full REST - no changes needed (already Inf)
        
    elseif strcmp(task_configuration, "tasks_only")
        % No REST tasks should be present, but use defaults anyway
        
    else
        error('Unknown task_configuration: "%s"\nMust be one of: rest_5min_and_tasks, rest_all_and_tasks, tasks_only', ...
              task_configuration);
    end
end