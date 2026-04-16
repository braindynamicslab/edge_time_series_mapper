config = fcn_utils_get_config();

session = "LR";
parcellation = "schaefer100x7";
simplex = "node";

cohort = "one";

% subject = 100206;
% selected_nodes = 1:812; % for edge

% subject = 125525;
% selected_nodes_old = (1:575 ~= 103); for edge

% subject = 102614;
% selected_nodes_old = 1:175; % for node

subject = 103212;
selected_nodes_old = 1:138; % for node


data_old = load(sprintf("/scratch/users/siuc/HOI_data_output/xcpenging_2025_noFeatureMassaging_%s_%s/brain_state_mapper_noFeatureMassaging_%d_%s_%s_%s_xcpengine_2025_data.mat", session, parcellation, subject, session, simplex, parcellation));
data_new = load(fullfile(config.scratch_dir, sprintf("simplex_mapper_raw_features_cohort_%s_%s_%s_%s/simplexMapper_%s_%d_%s_%s_data.mat", cohort, session, simplex, parcellation, simplex, subject, session, parcellation)));

fprintf("old num nodes: %d\n", size(data_old.nodeBynode, 1));
fprintf("new num nodes: %d\n", size(data_new.mapper_nodeBynode, 1));

fcn_test_compare_vectors(data_new.amplitude_nodewise, data_old.amplitude(selected_nodes_old));
%max_error = max(abs(data_new.amplitude_nodewise - data_old.amplitude(selected_nodes_old)));
%fprintf('Maximum Absolute Error in nodewise_amplitude: %.6e\n', max_error);

fcn_test_compare_vectors(data_new.amplitude_peak_density_peak_threshold_95, data_old.high_amplitude(selected_nodes_old));
max_error = max(abs(data_new.amplitude_peak_density_peak_threshold_95 - data_old.high_amplitude(selected_nodes_old)));
fprintf('Maximum Absolute Error in amplitude_peak_density_peak_threshold_95: %.6e\n', max_error);

high_amplitude_pure_nodes_old_251203 = compute_peak_dense_pure_nodes(...
    "expt_251203_highlighted_high_amplitude_nodes", ...
    'taskCountPerNode', data_old.taskCountPerNode, ...
    'purity_threshold', 0.75, ...
    'amplitude', data_old.amplitude, ...
    'high_amplitude_threshold', 0.9);
peak_dense_pure_nodes_old_251218 = compute_peak_dense_pure_nodes(...
    "expt_251218_shuffle_task_labels_high_amplitude", ...
    'taskCountPerNode', data_old.taskCountPerNode, ...
    'purity_threshold', 0.75, ...
    'amplitude', data_old.high_amplitude, ...
    'high_amplitude_threshold', 0.9);
peak_dense_pure_nodes_new = compute_peak_dense_pure_nodes(...
    "expt_03a_shuffle_task_labels", ...
    'nodeTpMat', data_new.mapper_nodeTpMat, ...
    'amplitude_framewise', data_new.amplitude_framewise, ...
    'peak_threshold', 0.95, ...
    'node_purity', data_new.mapper_stat_node_purity, ...
    'purity_threshold', 0.75, ...
    'peak_density_threshold', 0.9);

fcn_test_compare_vectors(peak_dense_pure_nodes_old_251218(selected_nodes_old), peak_dense_pure_nodes_new);

function peak_dense_pure_nodes = compute_peak_dense_pure_nodes(expt, varargin)

p = inputParser;
addRequired(p, 'expt');
addParameter(p, 'taskCountPerNode', [], @isnumeric);
addParameter(p, 'purity_threshold', 0.8, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
addParameter(p, 'amplitude', [], @isnumeric);
addParameter(p, 'high_amplitude_threshold', 0.75, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
addParameter(p, 'nodeTpMat', [], @isnumeric);
addParameter(p, 'node_purity', [], @isnumeric);
addParameter(p, 'amplitude_framewise', [], @isnumeric);
addParameter(p, 'peak_threshold', 0.95, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
addParameter(p, 'peak_density_threshold', 0.9, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);

parse(p, expt, varargin{:});


taskCountPerNode = p.Results.taskCountPerNode;
purity_threshold = p.Results.purity_threshold;
amplitude = p.Results.amplitude;
high_amplitude_threshold = p.Results.high_amplitude_threshold;
nodeTpMat = p.Results.nodeTpMat;
node_purity = p.Results.node_purity;
amplitude_framewise = p.Results.amplitude_framewise;
peak_threshold = p.Results.peak_threshold;
peak_density_threshold = p.Results.peak_density_threshold;

if strcmp(expt, "expt_251203_highlighted_high_amplitude_nodes")
    % task_proportions, purity_threshold, amplitude,
    % high_amplitude_threshold are from varargin
    task_proportions = taskCountPerNode./sum(taskCountPerNode, 2);
    pure_nodes = find(max(task_proportions, [], 2) > purity_threshold);
    high_amplitude_pure_nodes = amplitude(pure_nodes) > quantile(amplitude(pure_nodes), high_amplitude_threshold);
    highlighted_nodes = zeros(numel(amplitude), 1);
    highlighted_nodes(pure_nodes(high_amplitude_pure_nodes)) = 1;
    highlighted_nodes = (highlighted_nodes == 1);
    peak_dense_pure_nodes = highlighted_nodes;
end

if strcmp(expt, "expt_251218_shuffle_task_labels_high_amplitude")
    %     amplitude and output location depends on inputs in the slurm script
    %     mean_amplitude and fieldnames are the inputs

    %     if strcmp(amplitude_type, "mean_amplitude")
    %         amplitude = loaded_data.amplitude;
    %     elseif strcmp(amplitude_type, "peak_dense")
    %         amplitude = loaded_data.high_amplitude;
    %     elseif strcmp(amplitude_type, "quantile")
    %         amplitude = loaded_data.amplitude_quantile;
    %     end
    %
    %     the shuffled mods are eventually saved in data.(fieldname)

    task_proportions = taskCountPerNode./sum(taskCountPerNode, 2);
    pure_nodes = find(max(task_proportions, [], 2) > purity_threshold);
    high_amplitude_pure_nodes = amplitude(pure_nodes) > quantile(amplitude(pure_nodes), high_amplitude_threshold);
    high_amplitude_nodes = zeros(numel(amplitude), 1);
    high_amplitude_nodes(pure_nodes(high_amplitude_pure_nodes)) = 1;
    peak_dense_pure_nodes = high_amplitude_nodes;
end

if strcmp(expt, "expt_03a_shuffle_task_labels")
    peak_density = fcn_edgeMapper_compute_peak_density(nodeTpMat, amplitude_framewise, peak_threshold);
    is_pure_node = node_purity >= purity_threshold;
    is_peak_dense_pure_node = and(is_pure_node, ...
    peak_density > quantile(peak_density(is_pure_node), peak_density_threshold));
    peak_dense_pure_nodes = is_peak_dense_pure_node;
end
end