function [reduced_data, feature_indices, tasks_instantwise, feature_removal_mask, missing_data_flag, pca_results] = ...
    fcn_edgeMapper_get_processed_simplex_time_series_data(subject, parcellation, session, simplex, tasks_string, varargin)
    % Get processed edge/triangle timeseries data for one subject
    %
    % Full pipeline: Load fMRI data → Preprocess → Generate features → Reduce dimensions
    % Prepares data for Mapper analysis by transforming BOLD timeseries into
    % higher-order features (edges or triangles) with optional dimensionality reduction.
    %
    % Inputs:
    %   subject - Subject ID number (e.g., 100206)
    %   parcellation - Parcellation name (e.g., "schaefer100x7")
    %   session - Session identifier: "LR" or "RL"
    %   simplex - Feature type: "node", "edge", or "triangle"
    %   tasks_string - String array of task names (e.g., ["REST", "EMOTION", "WM", ...])
    %                  Order determines processing order
    %
    % Optional Parameters (name-value pairs):
    %   'rest_session' - REST session identifier (default: "<session>_run-1")
    %                    e.g., "LR_run-1", "RL_run-1"
    %
    %   'starting_times' - [num_tasks x 1] Start time for each task (default: ones)
    %   'ending_times' - [num_tasks x 1] End time for each task (default: Inf)
    %   'unit_time' - Time unit: "TR" or "seconds" (default: "TR")
    %   'seconds_per_TR' - TR duration in seconds (default: 0.72, HCP value)
    %
    %   'zscore_scope' - Normalization scope (default: "each_task")
    %                    "each_task" - Normalize within each task
    %                    "all_data" - Normalize globally
    %                    "none" - No normalization
    %
    %   'feature_removal_criterion' - Feature removal logic (default: "rest_and_all_tasks")
    %                    "rest_and_all_tasks" - Remove if all-zero in ALL tasks
    %                    "rest_or_all_tasks" - Remove if all-zero in REST OR all tasks
    %                    "rest_or_any_tasks" - Remove if all-zero in ANY task
    %
    %   'dim_reduction_type' - Dimensionality reduction (default: "none")
    %                    "pca_fixed_components" - PCA with fixed number of components
    %                    "pca_variance_threshold" - PCA retaining variance threshold
    %                    "none" - No reduction
    %
    %   'target_num_features' - Number of PCA components (default: 80)
    %                          Used when dim_reduction_type = "pca_fixed_components"
    %
    %   'target_explained_variance' - Variance to retain (default: 0.95)
    %                                Used when dim_reduction_type = "pca_variance_threshold"
    %
    %   'activity_mask_flag' - Mask low activity: 1=yes, 0=no (default: 0)
    %   'sign_by_coherence_flag' - Coherence signing: 1=yes, 0=no (default: 0)
    %
    %   'verbose_flag' - Print progress: 1=yes, 0=no (default: 1)
    %   'debug_flag' - Save debug visualizations: 1=yes, 0=no (default: 0)
    %   'debug_output_dir' - Debug output directory (default: <repo_root>/test/debug/...)
    %
    % Outputs:
    %   reduced_data - [timepoints x features] Processed feature matrix
    %                  Empty [] if missing_data_flag = true
    %   feature_indices - [num_features x simplex_order] Node indices per feature
    %                     Empty [] if missing_data_flag = true
    %   tasks_instantwise - [timepoints x 1] Task label per timepoint
    %                       Empty [] if missing_data_flag = true
    %   feature_removal_mask - [1 x num_ROIs] Logical mask (true = feature removed)
    %                          Empty [] if missing_data_flag = true
    %   missing_data_flag - Logical. If true, data could not be loaded
    %   pca_results - Struct with PCA information:
    %                 .num_features - Number of features after reduction
    %                 .explained_variance - Proportion of variance retained
    %                 .reduction_type - Which reduction was applied
    %                 Empty struct if missing_data_flag = true
    %
    % Example:
    %   % Define tasks
    %   tasks = ["REST", "EMOTION", "GAMBLING", "LANGUAGE", "MOTOR", "RELATIONAL", "SOCIAL", "WM"];
    %   
    %   % Get time windows (first 5 min of REST)
    %   [start_times, end_times, unit, tr] = ...
    %       fcn_edgeMapper_get_time_windows(tasks, "rest_5min_and_tasks");
    %   
    %   % Process data
    %   [data, idx, labels, mask, missing, pca] = ...
    %       fcn_edgeMapper_get_processed_simplex_time_series_data(100206, "schaefer100x7", ...
    %           "LR", "edge", tasks, ...
    %           'starting_times', start_times, ...
    %           'ending_times', end_times, ...
    %           'unit_time', unit, ...
    %           'seconds_per_TR', tr, ...
    %           'dim_reduction_type', "pca_fixed_components", ...
    %           'target_num_features', 80);
    %
    % See also: fcn_edgeMapper_preprocess_data, fcn_edgeMapper_generate_features,
    %           fcn_edgeMapper_get_time_windows, fcn_io_load_fmri_data_for_subject
    
    %% Parse and validate inputs
    
    p = inputParser;
    addRequired(p, 'subject', @isnumeric);
    addRequired(p, 'parcellation', @(x) isStringScalar(x) || ischar(x));
    addRequired(p, 'session', @(x) isStringScalar(x) || ischar(x));
    addRequired(p, 'simplex', @(x) isStringScalar(x) || ischar(x));
    addRequired(p, 'tasks_string', @(x) isstring(x) || ischar(x));
    
    % Time windowing parameters
    num_tasks_default = numel(tasks_string);  % Compute before parse
    addParameter(p, 'starting_times', ones(num_tasks_default, 1), @isnumeric);
    addParameter(p, 'ending_times', inf(num_tasks_default, 1), @isnumeric);
    addParameter(p, 'unit_time', "TR", @(x) isStringScalar(x) || ischar(x));
    addParameter(p, 'seconds_per_TR', 0.72, @isnumeric);
    
    % Data parameters
    addParameter(p, 'rest_session', "", @(x) isStringScalar(x) || ischar(x));
    
    % Preprocessing parameters
    addParameter(p, 'zscore_scope', "each_task", @(x) isStringScalar(x) || ischar(x));
    addParameter(p, 'feature_removal_criterion', "rest_and_all_tasks", @(x) isStringScalar(x) || ischar(x));
    addParameter(p, 'sign_by_coherence_flag', 0, @isnumeric);
    addParameter(p, 'activity_mask_flag', 0, @isnumeric);
    
    % Dimensionality reduction
    addParameter(p, 'dim_reduction_type', "none", @(x) isStringScalar(x) || ischar(x));
    addParameter(p, 'target_num_features', 80, @isnumeric);
    addParameter(p, 'target_explained_variance', 0.95, @isnumeric);
    
    % Output control
    addParameter(p, 'verbose_flag', 1, @isnumeric);
    addParameter(p, 'debug_flag', 0, @isnumeric);
    addParameter(p, 'debug_output_dir', "", @(x) isStringScalar(x) || ischar(x));
    
    parse(p, subject, parcellation, session, simplex, tasks_string, varargin{:});
    
    % Extract parameters
    parcellation = string(p.Results.parcellation);
    session = string(p.Results.session);
    simplex = string(p.Results.simplex);
    tasks_string = string(p.Results.tasks_string);  % Ensure string type
    starting_times = p.Results.starting_times;
    ending_times = p.Results.ending_times;
    unit_time = string(p.Results.unit_time);
    seconds_per_TR = p.Results.seconds_per_TR;
    rest_session = string(p.Results.rest_session);
    zscore_scope = string(p.Results.zscore_scope);
    feature_removal_criterion = string(p.Results.feature_removal_criterion);
    sign_by_coherence_flag = p.Results.sign_by_coherence_flag;
    activity_mask_flag = p.Results.activity_mask_flag;
    dim_reduction_type = string(p.Results.dim_reduction_type);
    target_num_features = p.Results.target_num_features;
    target_explained_variance = p.Results.target_explained_variance;
    verbose_flag = p.Results.verbose_flag;
    debug_flag = p.Results.debug_flag;
    debug_output_dir = string(p.Results.debug_output_dir);
    
    % Set default rest_session if not provided
    if strlength(rest_session) == 0
        rest_session = strcat(session, "_run-1");
    end
    
    % Set default debug output directory if needed
    if debug_flag && strlength(debug_output_dir) == 0
        config = fcn_utils_get_config();
        debug_output_dir = fullfile(config.repo_root, "test", "debug", ...
                                    "test_fcn_edgeMapper_get_processed_simplex_time_series_data");
        if ~exist(debug_output_dir, 'dir')
            mkdir(debug_output_dir);
        end
    end
    
    % Validate dimension reduction type
    valid_dim_reduction = ["pca_fixed_components", "pca_variance_threshold", "none"];
    assert(ismember(dim_reduction_type, valid_dim_reduction), ...
        'dim_reduction_type must be one of: %s\nGot: "%s"', ...
        strjoin(valid_dim_reduction, ", "), dim_reduction_type);
    
    % Validate time parameters match number of tasks
    num_tasks = numel(tasks_string);
    assert(numel(starting_times) == num_tasks, ...
        'Dimension mismatch: %d tasks but %d starting_times', ...
        num_tasks, numel(starting_times));
    assert(numel(ending_times) == num_tasks, ...
        'Dimension mismatch: %d tasks but %d ending_times', ...
        num_tasks, numel(ending_times));
    
    %% Print configuration if verbose
    
%     if verbose_flag
%         fprintf('\n=== Processing Subject %d ===\n', subject);
%         fprintf('Parcellation: %s\n', parcellation);
%         fprintf('Session: %s\n', session);
%         fprintf('Simplex: %s\n', simplex);
%         fprintf('\nConfiguration:\n');
%         fprintf('  Task configuration: %s\n', task_configuration);
%         fprintf('  Z-score scope: %s\n', zscore_scope);
%         fprintf('  Feature removal criterion: %s\n', feature_removal_criterion);
%         fprintf('  Sign by coherence: %d\n', sign_by_coherence_flag);
%         fprintf('  Activity mask: %d\n', activity_mask_flag);
%         fprintf('  Dimension reduction: %s\n', dim_reduction_type);
%         if strcmp(dim_reduction_type, "pca_fixed_components")
%             fprintf('  Target features: %d\n', target_num_features);
%         elseif strcmp(dim_reduction_type, "pca_variance_threshold")
%             fprintf('  Target variance: %.2f\n', target_explained_variance);
%         end
%         fprintf('\n');
%     end
    
    %% Define tasks based on configuration
    
    %tasks_string = ["EMOTION", "GAMBLING", "LANGUAGE", "MOTOR", "RELATIONAL", "SOCIAL", "WM"];
    
    %if ismember(task_configuration, ["rest_5min_and_tasks", "rest_all_and_tasks"])
    %    tasks_string = ["REST", tasks_string];
    %end
    
    %% Load fMRI data
    
    if verbose_flag
        fprintf('Loading fMRI data...\n');
    end
    
    config = fcn_utils_get_config();
    
    [data_cell, missing_data_flag] = fcn_io_load_fmri_data_for_subject(subject, ...
        tasks_string, session, rest_session, parcellation, config, ...
        'verbose_flag', verbose_flag);
    
    if missing_data_flag
        warning('Missing data for subject %d', subject);
        reduced_data = [];
        feature_indices = [];
        tasks_instantwise = [];
        feature_removal_mask = [];
        pca_results = struct();
        return;
    end
    
    %% Preprocess data
    
    if verbose_flag
        fprintf('Preprocessing data...\n');
    end
    
    [concatenated_data, tasks_instantwise, feature_removal_mask] = ...
        fcn_edgeMapper_preprocess_data(tasks_string, data_cell, ...
            'zscore_scope', zscore_scope, ...
            'feature_removal_criterion', feature_removal_criterion, ...
            'starting_times', starting_times, ...
            'ending_times', ending_times, ...
            'unit_time', unit_time, ...
            'seconds_per_TR', seconds_per_TR);

if nargout > 5
    varargout{1}.concatenated_data = concatenated_data;
end
    
    % Debug visualization: concatenated BOLD data
    if debug_flag
        visualize_timeseries(concatenated_data, tasks_instantwise, ...
            'BOLD_concatenated', subject, session, simplex, debug_output_dir);
    end
    
    %% Generate higher-order features
    
    if verbose_flag
        fprintf('Generating %s features...\n', simplex);
    end
    
    [data_higher_features, feature_indices] = ...
        fcn_edgeMapper_generate_features(concatenated_data, simplex, ...
            'zscore_flag', 1, ...  % z-score again to homogenize tasks
            'sign_by_coherence_flag', sign_by_coherence_flag, ...
            'activity_mask_flag', activity_mask_flag);
    
    num_higher_features = size(data_higher_features, 2);
    num_brain_regions = size(concatenated_data, 2);
    if verbose_flag
        fprintf('  Generated %d features from %d brain regions\n', ...
                num_higher_features, num_brain_regions);
    end
    
    %% Perform dimensionality reduction
    
    if verbose_flag && ~strcmp(dim_reduction_type, "none")
        fprintf('Performing dimensionality reduction...\n');
    end
    
    if strcmp(dim_reduction_type, "pca_fixed_components")
        % PCA with fixed number of components
        actual_num_features = min(target_num_features, num_higher_features);
        [~, reduced_data, ~, ~, pca_explained_variance, ~] = ...
            pca(data_higher_features, 'NumComponents', actual_num_features);

        if nargout > 5
            varargout{1}.pca_explained_variance = pca_explained_variance;
        end
        
        pca_results.num_features = actual_num_features;
        pca_results.explained_variance = sum(pca_explained_variance) / 100;
        pca_results.reduction_type = dim_reduction_type;
        
        if verbose_flag
            fprintf('  Reduced to %d components (%.3g%% variance)\n', ...
                    pca_results.num_features, pca_results.explained_variance * 100);
        end
        
    elseif strcmp(dim_reduction_type, "pca_variance_threshold")
        % PCA with variance threshold
        [~, score_all, ~, ~, pca_explained_variance, ~] = pca(data_higher_features);
        if nargout > 5
            if numel(pca_explained_variance) < num_higher_features
                pca_explained_variance = [pca_explained_variance; zeros(num_higher_features - numel(pca_explained_variance), 1)];
            end
            varargout{1}.pca_explained_variance = pca_explained_variance;
        end
        % Find number of components needed to reach threshold
        cumulative_variance = cumsum(pca_explained_variance);
        pca_results.num_features = find(cumulative_variance > target_explained_variance * 100, 1);
        
        if isempty(pca_results.num_features)
            pca_results.num_features = num_higher_features;
        end
        
        reduced_data = score_all(:, 1:pca_results.num_features);
        pca_results.explained_variance = cumulative_variance(pca_results.num_features) / 100;
        pca_results.reduction_type = dim_reduction_type;
        
        if verbose_flag
            fprintf('  Reduced to %d components (%.3g%% variance, target: %.3g%%)\n', ...
                    pca_results.num_features, pca_results.explained_variance * 100, ...
                    target_explained_variance * 100);
        end
        
    elseif strcmp(dim_reduction_type, "none")
        % No reduction
        reduced_data = data_higher_features;
        pca_results.num_features = num_higher_features;
        pca_results.explained_variance = 1.0;
        pca_results.reduction_type = dim_reduction_type;
        
        if verbose_flag
            fprintf('  No reduction: %d features retained\n', pca_results.num_features);
        end
    end
    
    % Debug visualization: reduced data
    if debug_flag
        visualize_timeseries(reduced_data, tasks_instantwise, ...
            'mapper_input', subject, session, simplex, debug_output_dir);
    end
    
    %% Postprocess: Remove all-zero timepoints
    
    % Identify timepoints where all features are zero
    zero_timepoints = all(reduced_data == 0, 2);
    num_zero_timepoints = sum(zero_timepoints);
    
    if num_zero_timepoints > 0
        if verbose_flag
            fprintf('Removing %d all-zero timepoints\n', num_zero_timepoints);
        end
        
        reduced_data = reduced_data(~zero_timepoints, :);
        tasks_instantwise = tasks_instantwise(~zero_timepoints);
    end
    
    %% Summary
    
    if verbose_flag
        fprintf('\n=== Processing Complete ===\n');
        fprintf('Final data shape: [%d timepoints x %d features]\n', ...
                size(reduced_data, 1), size(reduced_data, 2));
        fprintf('Tasks included: %s\n', strjoin(unique(tasks_instantwise), ", "));
        fprintf('\n');
    end
    
end


%% Local helper function

function visualize_timeseries(data, task_labels, plot_name, subject, session, simplex, output_dir)
    % Create visualization of timeseries data with task boundaries
    %
    % Inputs:
    %   data - [timepoints x features] data matrix
    %   task_labels - [timepoints x 1] task label per timepoint
    %   suffix - Descriptive suffix for filename
    %   subject - Subject ID number
    %   session - Session identifier
    %   simplex - Simplex type
    %   output_dir - Directory to save figure
    
    % Create figure
    figure('Visible', 'off');
    imagesc(data);
    colormap(gray);
    colorbar;
    
    % Add task boundary lines
    task_boundaries = find(~strcmp(task_labels(1:end-1), task_labels(2:end)));
    for boundary_idx = 1:numel(task_boundaries)
        yline(task_boundaries(boundary_idx), 'LineWidth', 2.5, 'Color', 'r');
    end
    
    % Labels
    xlabel("Features");
    ylabel("Timepoints");
    title(sprintf("%s: Subject %d - %s - %s", strrep(plot_name, '_', ' '), subject, session, simplex));
    
    % Generate filename with parameters
    filename = sprintf('%s_%d_%s_%s', plot_name, subject, session, simplex);
    
    % Save
    savefig(fullfile(output_dir, strcat(filename, ".fig")));
    saveas(gcf, fullfile(output_dir, strcat(filename, ".png")));
    
    close(gcf);
end