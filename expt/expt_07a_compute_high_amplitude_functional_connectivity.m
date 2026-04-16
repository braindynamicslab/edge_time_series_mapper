config = fcn_utils_get_config();

output_directory = fullfile(config.scratch_dir, "data_pipeline", "high_amplitude_functional_connectivity");
if ~isfolder(output_directory)
    mkdir(output_directory);
end

parcellation = "schaefer100x7";
simplex = "edge";

peak_threshold = 0.95;
peak_density_threshold = 0.90;
purity_threshold = 0.75;

tasks = ["REST", ...
    "EMOTION", ...
    "GAMBLING", ...
    "LANGUAGE", ...
    "MOTOR", ...
    "RELATIONAL", ...
    "SOCIAL", ...
    "WM"];
% Get time windows (first 5 min of REST)
[start_times, end_times, unit, tr] = ...
  fcn_edgeMapper_get_time_windows(tasks, "rest_5min_and_tasks");

for cohort = ["two"]%["one", "two"]
    cohort_storage = cohort;
    if strcmp(cohort, "two")
        cohort_storage = "all_but_one";
    end
    for session = ["LR"] %["LR", "RL"]
%         if strcmp(cohort, "one") && strcmp(session, "LR")
%             fprintf("done\n")
%             break;
%         end

        sublist_csv = fullfile(config.repo_root, "data_pipeline", "data_cohort", sprintf("cohort_%s_session_%s.csv", cohort, session));
        subjects = readtable(sublist_csv).Subject;
        
        for subject_idx = 1:numel(subjects) %subjects = [143325]; % cohort 1 RL subject_id = 158, no pure node for gambling task
            subject = subjects(subject_idx);
            fprintf("%d (%d  out of %d)\n", subject, subject_idx, numel(subjects))
            input_filename = sprintf(...
                "simplex_mapper_raw_features_cohort_%s_%s_%s_%s/simplexMapper_%s_%d_%s_%s_data.mat", ...
                cohort_storage, session, simplex, parcellation, simplex, subject, session, parcellation);
            mapper_data = matfile(fullfile(config.scratch_dir, input_filename));
            
            nodeTpMat = mapper_data.mapper_nodeTpMat;
            task_count_per_node = mapper_data.mapper_stat_task_count_per_node;
            mode_task_indices = mapper_data.mapper_stat_mode_task_indices;

            peak_density = mapper_data.amplitude_peak_density_peak_threshold_95;
%             is_pure_node = mapper_data.mapper_stat_node_purity > purity_threshold;
%             peak_density_quantile = quantile(peak_density(is_pure_node), peak_density_threshold);
%             highlighted_nodes = and(...
%                 is_pure_node, ...
%                 peak_density > peak_density_quantile);

            [reduced_data, feature_indices, tasks_instantwise, feature_removal_mask, missing_data_flag, ~] = ...
                fcn_edgeMapper_get_processed_simplex_time_series_data(...
                subject, parcellation, session, simplex, tasks, ...
                'starting_times', start_times, ...
                'ending_times', end_times, ...
                'unit_time', unit, ...
                'seconds_per_TR', tr);

            subject_functional_connectivity_cell = cell(numel(tasks), 1);

            for task_id = 1:numel(tasks)
                task = tasks(task_id);
                within_task_timeframes = strcmp(tasks_instantwise, task);
                within_task_cofluc = reduced_data(within_task_timeframes, :);
                within_task_amplitudes = vecnorm(within_task_cofluc, 2, 2);

                traditional_functional_connectivity = mean(within_task_cofluc);

                within_task_high_amplitude_frames = within_task_amplitudes >= quantile(within_task_amplitudes, peak_threshold);
                peak_functional_connectivity = mean(within_task_cofluc(within_task_high_amplitude_frames, :), 1);

                node_level_flag = 0;
                amplitude_measure = peak_density;
                [peak_dense_pure_node_functional_connectivity, ~] = edgeAct_get_within_task_high_amplitude_nodes(reduced_data, nodeTpMat, amplitude_measure, mode_task_indices, within_task_timeframes, task_id, peak_density_threshold, node_level_flag, "purity_threshold", purity_threshold, "taskCountPerNode", task_count_per_node);
                

                subject_functional_connectivity_cell{task_id} = [...
                    traditional_functional_connectivity; ...
                    peak_functional_connectivity; ...
                    peak_dense_pure_node_functional_connectivity
                    ];
            end

            row_names = [...
                "traditional_functional_connectivity"; ...
                "peak_functional_connectivity"; ...
                "peak_dense_pure_node_functional_connectivity"; ...
                ];
            col_names = feature_indices;

            output_data_filename = sprintf("high_amplitude_functional_connectivity_%d_%s_%s_%s_data.mat", subject, session, simplex, parcellation);
            %save(fullfile(output_directory, output_data_filename), "subject_functional_connectivity_cell", "tasks", "row_names", "col_names");
        end

    end
end
function [high_amplitude_node_functional_connectivity, varargout] = edgeAct_get_within_task_high_amplitude_nodes(reduced_data, nodeTpMat, amplitude_measure, modeTaskIndices, within_task_timeframes, task_id, high_amplitude_node_threshold, node_level_flag, varargin)

p = inputParser;
% Add optional parameters
addParameter(p, 'purity_threshold', 0, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
addParameter(p, 'taskCountPerNode', [], @(x) isnumeric(x) || isempty(x));

% Parse inputs
parse(p, varargin{:});

% Extract parsed values
purity_threshold = p.Results.purity_threshold;
taskCountPerNode = p.Results.taskCountPerNode;

if purity_threshold == 0
    within_task_nodes = find(modeTaskIndices == task_id);
else
    maxProportion = max(taskCountPerNode, [], 2)./sum(taskCountPerNode, 2);
    within_task_nodes = find(and(modeTaskIndices == task_id, maxProportion > purity_threshold));
end
within_task_amplitude = amplitude_measure(within_task_nodes);
within_task_high_amplitude_nodes = within_task_amplitude >= quantile(within_task_amplitude, high_amplitude_node_threshold);
within_task_high_amplitude_nodes = within_task_nodes(within_task_high_amplitude_nodes);
if node_level_flag
    normalized_nodeTpMat = nodeTpMat./sum(nodeTpMat, 2);
    within_Task_high_amplitude_node_cofluc = normalized_nodeTpMat(within_task_high_amplitude_nodes, :) * reduced_data;
    high_amplitude_node_functional_connectivity = mean(within_Task_high_amplitude_node_cofluc, 1);
    if nargout > 1
        varargout{1} = [];
    end
else
    within_task_frames_in_high_amplitude_nodes = and(...
        max(nodeTpMat(within_task_high_amplitude_nodes, :))', ... % high amplitude
        within_task_timeframes); % within task
    high_amplitude_proportion = sum(within_task_frames_in_high_amplitude_nodes)/sum(within_task_timeframes);
    high_amplitude_node_functional_connectivity = mean(reduced_data(within_task_frames_in_high_amplitude_nodes, :), 1);
    if nargout > 1
        varargout{1} = high_amplitude_proportion;
    end
end
end