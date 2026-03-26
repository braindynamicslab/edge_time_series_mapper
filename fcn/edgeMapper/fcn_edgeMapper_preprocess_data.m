function [concatenated_data, tasks_instantwise, feature_removal_mask] = ...
    fcn_edgeMapper_preprocess_data(tasks_string, data_cell, varargin)
    % Preprocess fMRI timeseries data from multiple tasks
    %
    % Processes multi-task fMRI data through time windowing, feature removal,
    % and z-score normalization. Supports flexible feature removal criteria
    % and normalization scopes.
    %
    % Inputs:
    %   tasks_string - String array of task names (e.g., ["REST", "WM", "MOTOR"])
    %   data_cell - Column cell array of [timepoints x ROIs] matrices, one per task
    %
    % Optional Parameters (name-value pairs):
    %   'zscore_scope' - Normalization scope (default: "each_task")
    %                    "each_task" - Z-score within each task separately
    %                    "all_data" - Z-score after concatenating all tasks
    %                    "none" - No z-score normalization
    %
    %   'feature_removal_criterion' - Feature removal logic (default: "rest_and_all_tasks")
    %                    "rest_and_all_tasks" - Remove if all-zero in ALL tasks
    %                    "rest_or_all_tasks" - Remove if all-zero in REST OR all non-REST tasks
    %                    "rest_or_any_tasks" - Remove if all-zero in ANY task
    %
    %   'starting_times' - [num_tasks x 1] Start time for each task (default: 1)
    %   'ending_times' - [num_tasks x 1] End time for each task (default: full length)
    %   'unit_time' - Time unit: "TR" or "seconds" (default: "TR")
    %   'seconds_per_TR' - TR duration in seconds (default: 0.72, HCP value)
    %
    %   'feature_removal_method' - How to handle removed features (default: "direct_removal")
    %                    "direct_removal" - Remove columns entirely
    %                    "nan" - Replace with NaN
    %
    % Outputs:
    %   concatenated_data - [total_timepoints x features] Processed timeseries matrix
    %   tasks_instantwise - [total_timepoints x 1] String array of task labels per timepoint
    %   feature_removal_mask - [1 x num_ROIs] Logical array (true = feature removed)
    %
    % Example:
    %   tasks = ["REST", "WM", "MOTOR"];
    %   data = {randn(200, 100), randn(150, 100), randn(180, 100)};
    %   
    %   % Basic usage
    %   [processed, labels, mask] = fcn_edgeMapper_preprocess_data(tasks, data);
    %   
    %   % With time windowing (first 5 minutes of REST)
    %   [processed, labels, mask] = fcn_edgeMapper_preprocess_data(tasks, data, ...
    %       'starting_times', [0; 0; 0], ...
    %       'ending_times', [300; Inf; Inf], ...
    %       'unit_time', "seconds", ...
    %       'zscore_scope', "all_data");
    %
    % See also: fcn_edgeMapper_get_time_windows, fcn_edgeMapper_generate_features
    
    %% Parse and validate inputs
    
    num_tasks = numel(tasks_string);
    num_timepoints = cellfun(@(data) size(data, 1), data_cell);
    
    % Set up defaults
    starting_times_default = ones(num_tasks, 1);
    ending_times_default = num_timepoints;
    
    p = inputParser;
    addRequired(p, 'tasks_string', @(x) isstring(x));
    addRequired(p, 'data_cell', @iscell);
    addParameter(p, 'zscore_scope', "each_task", @(x) isStringScalar(x) || ischar(x));
    addParameter(p, 'feature_removal_criterion', "rest_and_all_tasks", @(x) isStringScalar(x) || ischar(x));
    addParameter(p, 'starting_times', starting_times_default, @isnumeric);
    addParameter(p, 'ending_times', ending_times_default, @isnumeric);
    addParameter(p, 'unit_time', "TR", @(x) isStringScalar(x) || ischar(x));
    addParameter(p, 'seconds_per_TR', 0.72, @(x) isnumeric(x) && x > 0);
    %  from https://www.humanconnectome.org/hcp-protocols-ya-3t-imaging
    addParameter(p, 'feature_removal_method', "direct_removal", @(x) isStringScalar(x) || ischar(x));
    parse(p, tasks_string, data_cell, varargin{:});
    
    % Extract parameters
    zscore_scope = string(p.Results.zscore_scope);
    feature_removal_criterion = string(p.Results.feature_removal_criterion);
    starting_times = p.Results.starting_times;
    ending_times = p.Results.ending_times;
    unit_time = string(p.Results.unit_time);
    seconds_per_TR = p.Results.seconds_per_TR;
    feature_removal_method = string(p.Results.feature_removal_method);
    
    % Convert to string array if needed
    tasks_string = string(tasks_string);
    
    % Validate inputs
    assert(iscell(data_cell) && size(data_cell, 2) == 1, ...
        'data_cell must be column cell array, got %s of size [%d x %d]', ...
        class(data_cell), size(data_cell, 1), size(data_cell, 2));
    
    assert(numel(tasks_string) == numel(data_cell), ...
        'Dimension mismatch: %d tasks but %d data arrays', ...
        numel(tasks_string), numel(data_cell));
    
    assert(numel(starting_times) == num_tasks, ...
        'Dimension mismatch: %d tasks but %d starting_times', ...
        num_tasks, numel(starting_times));
    
    assert(numel(ending_times) == num_tasks, ...
        'Dimension mismatch: %d tasks but %d ending_times', ...
        num_tasks, numel(ending_times));
    
    assert(all(ending_times >= starting_times), ...
        'Some ending_times are before starting_times');
    
    % Validate parameter values
    valid_zscore = ["each_task", "all_data", "none"];
    assert(ismember(zscore_scope, valid_zscore), ...
        'zscore_scope must be one of: %s\nGot: "%s"', ...
        strjoin(valid_zscore, ", "), zscore_scope);
    
    valid_removal_criterion = ["rest_and_all_tasks", "rest_or_all_tasks", "rest_or_any_tasks"];
    assert(ismember(feature_removal_criterion, valid_removal_criterion), ...
        'feature_removal_criterion must be one of: %s\nGot: "%s"', ...
        strjoin(valid_removal_criterion, ", "), feature_removal_criterion);
    
    valid_unit_time = ["TR", "second", "seconds", "s"];
    assert(ismember(unit_time, valid_unit_time), ...
        'unit_time must be one of: %s\nGot: "%s"', ...
        strjoin(valid_unit_time, ", "), unit_time);
    
    valid_removal_method = ["direct_removal", "nan"];
    assert(ismember(feature_removal_method, valid_removal_method), ...
        'feature_removal_method must be one of: %s\nGot: "%s"', ...
        strjoin(valid_removal_method, ", "), feature_removal_method);
    
    %% Convert time units if needed
    
    if ismember(unit_time, ["second", "seconds", "s"])
        % Convert seconds to TR indices
        starting_times = ceil(starting_times / seconds_per_TR);
        ending_times = ceil(ending_times / seconds_per_TR);
    end
    
    % Clamp to valid ranges
    starting_times = max(1, starting_times);
    ending_times = min(num_timepoints, ending_times);
    
    %% Compute feature removal mask
    
    % Identify features that are all-zero within each task
    % Result: [num_tasks x num_features] logical matrix
    is_feature_all_zero_within_task = cell2mat(cellfun(@(data) sum(abs(data)) == 0, ...
        data_cell, "UniformOutput", false));
    
    % Apply removal criterion
    if strcmp(feature_removal_criterion, "rest_and_all_tasks")
        % Remove feature only if all-zero in ALL tasks (including REST)
        feature_removal_mask = all(is_feature_all_zero_within_task, 1);
        
    elseif strcmp(feature_removal_criterion, "rest_or_all_tasks")
        % Remove if all-zero in REST OR all-zero across all non-REST tasks
        is_rest_task = strcmp(tasks_string, "REST");
        zero_in_rest = is_feature_all_zero_within_task(is_rest_task, :);
        zero_in_all_tasks = all(is_feature_all_zero_within_task(~is_rest_task, :), 1);
        feature_removal_mask = any([zero_in_rest; zero_in_all_tasks], 1);
        
    elseif strcmp(feature_removal_criterion, "rest_or_any_tasks")
        % Remove if all-zero in REST OR all-zero in ANY task
        feature_removal_mask = any(is_feature_all_zero_within_task, 1);
    end
    
    %% Extract time windows and apply feature removal
    
    processed_data_cell = cell(num_tasks, 1);
    
    for task_idx = 1:num_tasks
        % Extract time window
        time_range = starting_times(task_idx):ending_times(task_idx);
        windowed_data = data_cell{task_idx}(time_range, :);
        
        % Apply feature removal method
        if strcmp(feature_removal_method, "direct_removal")
            % Remove columns entirely
            processed_data_cell{task_idx} = windowed_data(:, ~feature_removal_mask);
            
        elseif strcmp(feature_removal_method, "nan")
            % Replace removed features with NaN
            windowed_data(:, feature_removal_mask) = NaN;
            processed_data_cell{task_idx} = windowed_data;
        end
    end
    
    %% Build task labels
    
    tasks_instantwise_cell = cell(num_tasks, 1);
    for task_idx = 1:num_tasks
        num_timepoints_task = size(processed_data_cell{task_idx}, 1);
        tasks_instantwise_cell{task_idx} = repmat(tasks_string(task_idx), num_timepoints_task, 1);
    end
    tasks_instantwise = vertcat(tasks_instantwise_cell{:});
    
    %% Z-score normalization
    
    if strcmp(zscore_scope, "each_task")
        % Z-score within each task separately
        processed_data_cell = cellfun(@(data) normalize(data), ...
            processed_data_cell, "UniformOutput", false);
        concatenated_data = vertcat(processed_data_cell{:});
        
    elseif strcmp(zscore_scope, "all_data")
        % Concatenate first, then z-score globally
        concatenated_data = normalize(vertcat(processed_data_cell{:}));
        
    elseif strcmp(zscore_scope, "none")
        % No normalization
        concatenated_data = vertcat(processed_data_cell{:});
    end
    
end