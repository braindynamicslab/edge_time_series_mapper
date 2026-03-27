function fcn_edgeMapper_compute_and_analyze_simplex_mapper(subject, parcellation, session, simplex, ...
        task_configuration, output_dir, varargin)
    % Compute and analyze higher-order interaction Mapper
    %
    % Complete pipeline: Load/preprocess fMRI data --> Generate features --> 
    % Reduce dimensions --> Run Mapper --> Compute modularity metrics --> Save results
    %
    % All outputs saved to MAT file and mapper graph PDF. Optional CSV export
    % controlled by copy_data_flag.
    %
    % Inputs:
    %   subject - Subject ID number (e.g., 100206)
    %   parcellation - Parcellation name (e.g., "schaefer100x7")
    %   session - Session identifier: "LR" or "RL"
    %   simplex - Feature type: "node", "edge", or "triangle"
    %   task_configuration - Which tasks to include:
    %                        "rest_5min_and_tasks" - First 5min REST + all tasks
    %                        "rest_all_and_tasks" - Full REST + all tasks
    %                        "tasks_only" - Tasks only (no REST)
    %   output_dir - Directory to save results
    %
    % Optional Parameters (name-value pairs):
    %   'copy_data_flag' - Export summary CSV: 1=yes, 0=no (default: 0)
    %   'summary_csv_path' - Path for summary CSV (required if copy_data_flag=1)
    %   'output_filename_prefix' - Prefix for output files (default: "simplexMapper")
    %                              files named:
    %                              <prefix>_<simplex>_<subject>_<session>_<parcellation>_<file-specific
    %                              info, e.g. data, plot, filter, ...>
    % 
    %   'rest_session' - REST session identifier (default: "<session>_run-1")
    %
    %   'zscore_scope' - Normalization scope (default: "each_task")
    %   'feature_removal_criterion' - Feature removal logic (default: "rest_and_all_tasks")
    %   'dim_reduction_type' - Dimensionality reduction (default: "none")
    %   'target_num_features' - Number of PCA components (default: inf)
    %   'target_explained_variance' - Variance to retain (default: 1)
    %   'sign_by_coherence_flag' - Coherence signing: 1=yes, 0=no (default: 0)
    %   'activity_mask_flag' - Mask low activity: 1=yes, 0=no (default: 0)
    %
    %   'mapper_auto_tune_flag' - Auto-tune Mapper parameters: 1=yes, 0=no (default: 0)
    %   'mapper_params' - Struct with Mapper parameters (default: auto-generated)
    %   'metric_type' - Distance metric override (default: "" = use mapper_params)
    %   'metric_transform' - Metric transformation: "quadratic_naive", "linear_hat", "none" (default: "none")
    %
    %   'verbose_flag' - Print progress: 1=yes, 0=no (default: 1)
    %   'debug_flag' - Save debug visualizations: 1=yes, 0=no (default: 0)
    %
    % Outputs (no return values):
    %   Files created:
    %     - <prefix>_<simplex>_<subject>_<session>_<parcellation>_data.mat
    %     - <prefix>_<simplex>_<subject>_<session>_<parcellation>_mapper.pdf
    %     - <summary_csv_path> (if copy_data_flag=1)
    %
    % Example (No CSV):
    %   fcn_edgeMapper_compute_and_analyze_hoi_mapper(100206, "schaefer100x7", ...
    %       "LR", "edge", "rest_5min_and_tasks", "/path/to/output");
    %
    % Example (With CSV export):
    %   fcn_edgeMapper_compute_and_analyze_hoi_mapper(100206, "schaefer100x7", ...
    %       "LR", "edge", "rest_5min_and_tasks", "/path/to/output", ...
    %       'copy_data_flag', 1, ...
    %       'summary_csv_path', '/tmp/temp_12345_1.csv', ...
    %       'dim_reduction_type', 'pca_fixed_components', ...
    %       'target_num_features', 80);
    %
    % See also: fcn_edgeMapper_get_processed_simplex_time_series_data
    
    %% Parse and validate inputs
    
    p = inputParser;
    addRequired(p, 'subject', @isnumeric);
    addRequired(p, 'parcellation', @(x) isStringScalar(x) || ischar(x));
    addRequired(p, 'session', @(x) isStringScalar(x) || ischar(x));
    addRequired(p, 'simplex', @(x) isStringScalar(x) || ischar(x));
    addRequired(p, 'task_configuration', @(x) isStringScalar(x) || ischar(x));
    addRequired(p, 'output_dir', @(x) isStringScalar(x) || ischar(x));
    
    % Output control
    addParameter(p, 'copy_data_flag', 0, @isnumeric);
    addParameter(p, 'summary_csv_path', '', @(x) isStringScalar(x) || ischar(x));
    addParameter(p, 'output_filename_prefix', 'simplexMapper', @(x) isStringScalar(x) || ischar(x));
    
    % Data parameters
    addParameter(p, 'rest_session', '', @(x) isStringScalar(x) || ischar(x));
    
    % Preprocessing parameters
    addParameter(p, 'zscore_scope', 'each_task', @(x) isStringScalar(x) || ischar(x));
    addParameter(p, 'feature_removal_criterion', 'rest_and_all_tasks', @(x) isStringScalar(x) || ischar(x));
    addParameter(p, 'sign_by_coherence_flag', 0, @isnumeric);
    addParameter(p, 'activity_mask_flag', 0, @isnumeric);
    
    % Dimensionality reduction
    addParameter(p, 'dim_reduction_type', 'none', @(x) isStringScalar(x) || ischar(x));
    addParameter(p, 'target_num_features', inf, @isnumeric);
    addParameter(p, 'target_explained_variance', 1, @isnumeric);
    
    % Mapper parameters
    addParameter(p, 'mapper_auto_tune_flag', 0, @isnumeric);
    addParameter(p, 'mapper_params', struct(), @isstruct);
    addParameter(p, 'metric_type', '', @(x) isStringScalar(x) || ischar(x));
    addParameter(p, 'metric_transform', 'none', @(x) isStringScalar(x) || ischar(x));
    
    % Output parameters
    addParameter(p, 'verbose_flag', 1, @isnumeric);
    addParameter(p, 'debug_flag', 0, @isnumeric);
    
    parse(p, subject, parcellation, session, simplex, task_configuration, output_dir, varargin{:});
    
    % Extract parameters
    parcellation = string(p.Results.parcellation);
    session = string(p.Results.session);
    simplex = string(p.Results.simplex);
    task_configuration = string(p.Results.task_configuration);
    output_dir = string(p.Results.output_dir);
    copy_data_flag = p.Results.copy_data_flag;
    summary_csv_path = string(p.Results.summary_csv_path);
    output_filename_prefix = string(p.Results.output_filename_prefix);
    rest_session = string(p.Results.rest_session);
    zscore_scope = string(p.Results.zscore_scope);
    feature_removal_criterion = string(p.Results.feature_removal_criterion);
    sign_by_coherence_flag = p.Results.sign_by_coherence_flag;
    activity_mask_flag = p.Results.activity_mask_flag;
    dim_reduction_type = string(p.Results.dim_reduction_type);
    target_num_features = p.Results.target_num_features;
    target_explained_variance = p.Results.target_explained_variance;
    mapper_auto_tune_flag = p.Results.mapper_auto_tune_flag;
    mapper_params = p.Results.mapper_params;
    metric_type = string(p.Results.metric_type);
    metric_transform = string(p.Results.metric_transform);
    verbose_flag = p.Results.verbose_flag;
    debug_flag = p.Results.debug_flag;
    
    % Set defaults
    if strlength(rest_session) == 0
        rest_session = strcat(session, "_run-1");
    end
    
    % Create output directory if needed
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    % Validate copy_data_flag
    if copy_data_flag
        assert(strlength(summary_csv_path) > 0, ...
            'copy_data_flag=1 requires summary_csv_path parameter');
    end
    
    % Set up Mapper parameters
    if isempty(fieldnames(mapper_params))
        mapper_params = fcn_edgeMapper_get_default_mapper_parameters(mapper_auto_tune_flag);
    end
    
    % Override metric type if provided
    if strlength(metric_type) > 0
        mapper_params.metric_type = metric_type;
    end
    
    % Build output filenames with format: <simplex>_<subject>_<session>_<parcellation>
    output_filename_base = sprintf("%s_%s_%d_%s_%s", output_filename_prefix, simplex, subject, session, parcellation);
    output_data_filename = fullfile(output_dir, strcat(output_filename_base, "_data"));
    output_mapper_filename = fullfile(output_dir, output_filename_base);
    
    %% Print configuration
    
    if verbose_flag
        fprintf('\n========================================\n');
        fprintf('Higher-Order Interaction Mapper Analysis\n');
        fprintf('========================================\n\n');
        fprintf('Subject: %d\n', subject);
        fprintf('Parcellation: %s\n', parcellation);
        fprintf('Session: %s\n', session);
        fprintf('Simplex: %s\n', simplex);
        fprintf('Task configuration: %s\n', task_configuration);
        fprintf('Copy data to CSV: %d\n', copy_data_flag);
        fprintf('\nPreprocessing:\n');
        fprintf('  Z-score scope: %s\n', zscore_scope);
        fprintf('  Feature removal: %s\n', feature_removal_criterion);
        fprintf('  Sign by coherence: %d\n', sign_by_coherence_flag);
        fprintf('  Activity mask: %d\n', activity_mask_flag);
        fprintf('\nDimensionality Reduction:\n');
        fprintf('  Type: %s\n', dim_reduction_type);
        if strcmp(dim_reduction_type, "pca_fixed_components")
            fprintf('  Target features: %d\n', target_num_features);
        elseif strcmp(dim_reduction_type, "pca_variance_threshold")
            fprintf('  Target variance: %.1f%%\n', target_explained_variance * 100);
        end
        fprintf('\nMapper:\n');
        fprintf('  Auto-tune: %d\n', mapper_auto_tune_flag);
        fprintf('  Metric: %s\n', mapper_params.metric_type);
        fprintf('  Metric transform: %s\n', metric_transform);

        fprintf('\n');
    end
    
    %% Define tasks and get time windows
    
    tasks_string = ["EMOTION", "GAMBLING", "LANGUAGE", "MOTOR", "RELATIONAL", "SOCIAL", "WM"];
    if ismember(task_configuration, ["rest_5min_and_tasks", "rest_all_and_tasks"])
        tasks_string = ["REST", tasks_string];
    end
    
    [starting_times, ending_times, unit_time, seconds_per_TR] = ...
        fcn_edgeMapper_get_time_windows(tasks_string, task_configuration);
    
    %% Get processed data
    
    if verbose_flag
        fprintf('Loading and preprocessing data...\n');
    end
    
    [reduced_data, feature_indices, feature_tasks_instantwise, feature_removal_mask, missing_data_flag, pca_results] = ...
        fcn_edgeMapper_get_processed_simplex_time_series_data(subject, parcellation, session, simplex, tasks_string, ...
            'rest_session', rest_session, ...
            'zscore_scope', zscore_scope, ...
            'starting_times', starting_times, ...
            'ending_times', ending_times, ...
            'unit_time', unit_time, ...
            'seconds_per_TR', seconds_per_TR, ...
            'feature_removal_criterion', feature_removal_criterion, ...
            'dim_reduction_type', dim_reduction_type, ...
            'target_num_features', target_num_features, ...
            'target_explained_variance', target_explained_variance, ...
            'sign_by_coherence_flag', sign_by_coherence_flag, ...
            'activity_mask_flag', activity_mask_flag, ...
            'verbose_flag', 0, ...
            'debug_flag', debug_flag);
    
    % Check for missing data
    if missing_data_flag
        warning('Missing data for subject %d - aborting', subject);
        return;
    end
    
    % Extract PCA results
    pca_num_features = pca_results.num_features;
    pca_explained_variance = pca_results.explained_variance;
    pca_reduction_type = string(pca_results.reduction_type);
    
    if verbose_flag
        fprintf('Data loaded: [%d timepoints x %d features]\n', ...
                size(reduced_data, 1), size(reduced_data, 2));
        if ~strcmp(dim_reduction_type, "none")
            fprintf('  Reduced to %d features (%.1f%% variance)\n', ...
                    pca_num_features, pca_explained_variance * 100);
        end
        fprintf('\n');
    end
    
    %% Compute amplitude metrics
    
    % Framewise amplitude (L2 norm per timepoint)
    amplitude_framewise = vecnorm(reduced_data, 2, 2);
    
    %% Compute Mapper
    
    if verbose_flag
        fprintf('Computing Mapper graph...\n');
    end
    
    % Apply metric transform if specified
    if ~strcmp(metric_transform, "none")
        dist_mat = pdist(reduced_data, mapper_params.metric_type);
        
        if strcmp(metric_transform, "quadratic_naive")
            dist_mat = 1 - (1 - dist_mat).^2;
        elseif strcmp(metric_transform, "linear_hat")
            dist_mat = 1 - abs(1 - dist_mat);
        else
            error('Unknown metric_transform: "%s"\nMust be one of: quadratic_naive, linear_hat, none', ...
                  metric_transform);
        end
        
        % Find Mapper parameters
        if mapper_auto_tune_flag
            if verbose_flag
                fprintf('  Auto-tuning Mapper parameters...\n');
            end
            [mapper_param_nums_k, mapper_param_res_vals, mapper_param_gain_vals, mapper_param_nums_bin_cluster] = ...
                hoiAux_findMapperParameters(reduced_data, mapper_params.metric_type, ...
                    mapper_params.ndim, mapper_params.mass_biggest_component, ...
                    'distMat', dist_mat);
        else
            mapper_param_nums_k = mapper_params.num_k;
            mapper_param_res_vals = mapper_params.res_val;
mapper_param_gain_vals = mapper_params.gain_val;
            mapper_param_nums_bin_cluster = mapper_params.num_bin_cluster;
        end
        
        % Run Mapper with transformed metric
        [mapper_nodeTpMat, mapper_nodeBynode, mapper_tpMat, mapper_filter, ~] = hoiAux_runBDLMapper(...
            reduced_data, mapper_params.metric_type, mapper_param_res_vals, mapper_param_gain_vals, ...
            mapper_param_nums_k, mapper_param_nums_bin_cluster, mapper_params.ndim, 'distMat', dist_mat);
        
    else
        % No metric transform - standard Mapper
        
        % Find Mapper parameters
        if mapper_auto_tune_flag
            if verbose_flag
                fprintf('  Auto-tuning Mapper parameters...\n');
            end
            [mapper_param_nums_k, mapper_param_res_vals, mapper_param_gain_vals, mapper_param_nums_bin_cluster] = ...
                hoiAux_findMapperParameters(reduced_data, mapper_params.metric_type, ...
                    mapper_params.ndim, mapper_params.mass_biggest_component);
        else
            mapper_param_nums_k = mapper_params.num_k;
            mapper_param_res_vals = mapper_params.res_val;
            mapper_param_gain_vals = mapper_params.gain_val;
            mapper_param_nums_bin_cluster = mapper_params.num_bin_cluster;
        end
        
        % Run Mapper
        [mapper_nodeTpMat, mapper_nodeBynode, mapper_tpMat, mapper_filter, ~] = hoiAux_runBDLMapper(...
            reduced_data, mapper_params.metric_type, mapper_param_res_vals, mapper_param_gain_vals, ...
            mapper_param_nums_k, mapper_param_nums_bin_cluster, mapper_params.ndim);
    end
    
    % Compute graph statistics
    mapper_num_nodes = size(mapper_nodeBynode, 1);
    mapper_num_edges = sum(mapper_nodeBynode(:)) / 2;  % Undirected graph
    
    if verbose_flag
        fprintf('  Mapper graph: %d nodes, %d edges\n', mapper_num_nodes, mapper_num_edges);
    end
    
    %% Debug: Visualize filter function
    
    if debug_flag
        visualize_filter(mapper_filter, feature_tasks_instantwise, tasks_string, output_dir, output_filename_base);
    end
    
    %% Compute node-level statistics
    
    if verbose_flag
        fprintf('\nComputing node statistics...\n');
    end
    
    % Number of data points per node
    num_data_points_per_mapper_nodes = full(sum(mapper_nodeTpMat, 2));
    
    % Nodewise amplitude (average amplitude per node)
    amplitude_nodewise = (mapper_nodeTpMat * amplitude_framewise) ./ num_data_points_per_mapper_nodes;
    
    % Task counts and mode task per node
    [mapper_stat_task_count_per_node, mapper_stat_mode_task_indices] = ...
        fcn_edgeMapper_get_label_count_and_mode_label_per_node(mapper_nodeTpMat, feature_tasks_instantwise, tasks_string);
    
    % Node purity (proportion of mode task in node)
    mapper_stat_node_purity = max(mapper_stat_task_count_per_node, [], 2) ./ sum(mapper_stat_task_count_per_node, 2);
    
    %% Compute graph properties
    
    if verbose_flag
        fprintf('Computing graph properties...\n');
    end
    
    modularity = fcn_BCT_calMod(mapper_nodeBynode, mapper_stat_mode_task_indices);
    
    if verbose_flag
        fprintf('  Modularity: %.4f\n', modularity);
        fprintf('  Mean node purity: %.4f\n', mean(mapper_stat_node_purity));
    end
    
    %% CHECKPOINT 1: Save everything before plotting
    
    if verbose_flag
        fprintf('\nSaving results (before plotting)...\n');
    end
    
    save(output_data_filename, ...
        'feature_removal_mask', feature_removal_mask, ...
        'feature_indices', feature_indices, ...
        'feature_tasks_instantwise', feature_tasks_instantwise, ...
        'amplitude_framewise', amplitude_framewise, ...
        'num_data_points_per_mapper_nodes', num_data_points_per_mapper_nodes, ...
        'amplitude_nodewise', amplitude_nodewise, ...
        'mapper_stat_node_purity', mapper_stat_node_purity, ...
        'mapper_stat_task_count_per_node', mapper_stat_task_count_per_node, ...
        'mapper_stat_mode_task_indices', mapper_stat_mode_task_indices, ...
        'modularity', modularity, ...
        'mapper_num_nodes', mapper_num_nodes, ...
        'mapper_num_edges', mapper_num_edges, ...
        'mapper_nodeTpMat', mapper_nodeTpMat, ...
        'mapper_nodeBynode', mapper_nodeBynode, ...
        'mapper_tpMat', mapper_tpMat, ...
        'mapper_filter', mapper_filter, ...
        'mapper_param_nums_k', mapper_param_nums_k, ...
        'mapper_param_res_vals', mapper_param_res_vals, ...
        'mapper_param_gain_vals', mapper_param_gain_vals, ...
        'mapper_param_nums_bin_cluster', mapper_param_nums_bin_cluster, ...
        'pca_num_features', pca_num_features, ...
        'pca_explained_variance', pca_explained_variance, ...
        'pca_reduction_type', pca_reduction_type, ...
        '-v7.3');
    
    if verbose_flag
        fprintf('  Saved: %s.mat (without mapper_nodes_positions)\n', output_data_filename);
    end
    
    %% Draw and save Mapper graph
    
    if verbose_flag
        fprintf('  Drawing Mapper graph...\n');
    end
    
    cmap = fcn_utils_get_task_coloring(tasks_string);
    
    mapper_nodes_positions = hoiAux_drawd3graph(mapper_nodeBynode, mapper_stat_mode_task_indices, cmap, ...
        output_mapper_filename, mapper_stat_task_count_per_node);
    
    if verbose_flag
        fprintf('  Saved: %s_mapper.pdf\n', output_mapper_filename);
    end
    
    %% CHECKPOINT 2: Append mapper_nodes_positions
    
    save(output_data_filename, 'mapper_nodes_positions', '-append');
    
    if verbose_flag
        fprintf('  Updated: %s.mat (added mapper_nodes_positions)\n', output_data_filename);
    end
    
    %% Optionally save summary CSV
    
    if copy_data_flag
        if verbose_flag
            fprintf('  Creating summary CSV...\n');
        end
        
        summary_table = create_summary_table(subject, modularity, mapper_num_nodes, mapper_num_edges, ...
            mapper_param_nums_k, mapper_param_res_vals, mapper_param_gain_vals, mapper_param_nums_bin_cluster, ...
            session, parcellation, simplex, task_configuration, zscore_scope, ...
            feature_removal_criterion, dim_reduction_type, mapper_auto_tune_flag, ...
            mapper_params.metric_type);
        
        writetable(summary_table, summary_csv_path);
        
        if verbose_flag
            fprintf('  Saved: %s\n', summary_csv_path);
        end
    end
    
    if verbose_flag
        fprintf('\n========================================\n');
        fprintf('Analysis Complete\n');
        fprintf('========================================\n\n');
    end
    
end


%% Local helper functions

function summary_table = create_summary_table(subject, modularity, mapper_num_nodes, mapper_num_edges, ...
    mapper_param_nums_k, mapper_param_res_vals, mapper_param_gain_vals, mapper_param_nums_bin_cluster, ...
    session, parcellation, simplex, task_configuration, zscore_scope, ...
    feature_removal_criterion, dim_reduction_type, mapper_auto_tune_flag, mapper_metric)
    % Create summary table with one row of results
    %
    % This function centralizes the CSV schema - easy to modify columns
    
    summary_table = table();
    
    % Subject and configuration
    summary_table.subject = subject;
    summary_table.session = string(session);
    summary_table.parcellation = string(parcellation);
    summary_table.simplex = string(simplex);
    summary_table.task_configuration = string(task_configuration);
    summary_table.zscore_scope = string(zscore_scope);
    summary_table.feature_removal_criterion = string(feature_removal_criterion);
    summary_table.dim_reduction_type = string(dim_reduction_type);
    
    % Mapper parameters
    summary_table.mapper_auto_tune = mapper_auto_tune_flag;
    summary_table.mapper_metric = string(mapper_metric);
    summary_table.mapper_param_nums_k = mapper_param_nums_k;
    summary_table.mapper_param_res_vals = mapper_param_res_vals;
    summary_table.mapper_param_gain_vals = mapper_param_gain_vals;
    summary_table.mapper_param_nums_bin_cluster = mapper_param_nums_bin_cluster;
    
    % Numeric outputs
    summary_table.modularity = modularity;
    summary_table.mapper_num_nodes = mapper_num_nodes;
    summary_table.mapper_num_edges = mapper_num_edges;
    
    % Timestamp
    summary_table.timestamp = string(datetime('now'));
end


function visualize_filter(filter, task_labels, tasks_string, output_dir, filename_base)
    % Visualize filter function colored by task
    %
    % Inputs:
    %   filter - [num_timepoints x ndim] Filter function values
    %   task_labels - [num_timepoints x 1] Task label per timepoint
    %   tasks_string - String array of unique task names
    %   output_dir - Directory to save figure
    %   filename_base - Base filename (without extension)
    
    num_tasks = numel(tasks_string);
    
    % Create figure
    figure('Visible', 'off');
    hold on;
    
    % Get task colors
    cmap = fcn_utils_get_task_coloring(tasks_string);
    
    % Plot each task separately
    for task_idx = 1:num_tasks
        task = tasks_string(task_idx);
        color = cmap(task_idx, :);
        
        is_task = strcmp(task_labels, task);
        scatter(filter(is_task, 1), filter(is_task, 2), 20, color, 'filled');
    end
    
    % Labels and legend
    xlabel('Filter Dimension 1');
    ylabel('Filter Dimension 2');
    title(sprintf('Filter Function - %s', strrep(filename_base, '_', ' ')));
    legend(tasks_string, 'Location', 'best');
    
    % Save as PDF
    output_path = fullfile(output_dir, strcat(filename_base, "_filter"));
    print(gcf, strcat(output_path, ".pdf"), '-dpdf', '-vector');
    
    close(gcf);
end