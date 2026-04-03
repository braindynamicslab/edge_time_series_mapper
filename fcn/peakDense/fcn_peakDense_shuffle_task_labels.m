function fcn_peakDense_shuffle_task_labels(simplex, subject, session, parcellation, peak_threshold, peak_density_threshold, purity_threshold, num_shuffling, seed, shuffled_modularity_full_filename, varargin)%, shuffled_modularity_mean_filename)

p = inputParser;
addParameter(p, 'shuffle_all_flag', 1, @(x) x == 1 || x == 0);  % Default: 1 (true)
parse(p, varargin{:});

% Extract parameter
shuffle_all_flag = p.Results.shuffle_all_flag;

config = fcn_utils_get_config();

is_cohort_one = fcn_utils_is_cohort_one(subject, session);
if is_cohort_one
    cohort_storage = "one";
else
    cohort_storage = "all_but_one";
end

data_directory = fullfile(config.scratch_dir, sprintf(...
    "simplex_mapper_raw_features_cohort_%s_%s_%s_%s", ...
    cohort_storage, session, simplex, parcellation));
filename = sprintf("simplexMapper_%s_%d_%s_%s_data.mat", ...
    simplex, subject, session, parcellation);
loaded_data = matfile(fullfile(data_directory, filename));

nodeBynode = loaded_data.mapper_nodeBynode;
nodeTpMat = loaded_data.mapper_nodeTpMat;
mode_task_indices = loaded_data.mapper_stat_mode_task_indices;
amplitude_framewise = loaded_data.amplitude_framewise;
node_purity = loaded_data.mapper_stat_node_purity;

peak_density = fcn_edgeMapper_compute_peak_density(nodeTpMat, amplitude_framewise, peak_threshold);
is_pure_node = node_purity >= purity_threshold;
is_peak_dense_pure_node = and(is_pure_node, ...
    peak_density > quantile(peak_density(is_pure_node), peak_density_threshold));

peak_dense_pure_labels = mode_task_indices(is_peak_dense_pure_node);

num_nodes = size(nodeBynode, 1);
num_pure_nodes = sum(is_pure_node);
num_peak_dense_pure_nodes = sum(is_peak_dense_pure_node);


% Validate that peak dense pure nodes exist
if num_peak_dense_pure_nodes == 0
    warning('fcn_peakDense_shuffle_task_labels:NoPeakDensePureNodes', ...
          'No peak dense pure nodes found for subject %d, session %s. Cannot perform shuffling.', ...
          subject, session);
end

rng(seed);
shuffled_mod = nan(num_shuffling, 2 + shuffle_all_flag);
for shuffling_idx = 1:num_shuffling

    if shuffle_all_flag
        shuffled_labels_all = mode_task_indices(randperm(num_nodes));
        shuffled_mod(shuffling_idx, 1) = fcn_BCT_calMod(nodeBynode, shuffled_labels_all);
    end
    
    if num_peak_dense_pure_nodes == 0
        continue;
    else
        shuffled_labels_peak_dense_pure_nodes = mode_task_indices;
        shuffled_labels_peak_dense_pure_nodes(is_peak_dense_pure_node) = peak_dense_pure_labels(randperm(num_peak_dense_pure_nodes));
        shuffled_mod(shuffling_idx, 1 + shuffle_all_flag) = fcn_BCT_calMod(nodeBynode, shuffled_labels_peak_dense_pure_nodes);
        
        shuffled_labels_matched_random_nodes = mode_task_indices;
        randomly_chosen_nodes = 1:num_nodes; % all nodes
        randomly_chosen_nodes = randomly_chosen_nodes(is_pure_node); % all pure nodes
        randomly_chosen_nodes = randomly_chosen_nodes(randperm(num_pure_nodes, num_peak_dense_pure_nodes)); % randomly chosen pure nodes
        shuffled_labels_matched_random_nodes(randomly_chosen_nodes) = ...
            shuffled_labels_matched_random_nodes(randomly_chosen_nodes(randperm(num_peak_dense_pure_nodes)));
    
        shuffled_mod(shuffling_idx, 2 + shuffle_all_flag) = fcn_BCT_calMod(nodeBynode, shuffled_labels_matched_random_nodes);
    end
end

% shuffled_mod_mean = mean(shuffled_mod, 'omitnan');

% Build suffix for full results filename
suffix = sprintf('%s_%d_%s_%s_peak_%d_density_%d_purity_%d_num_shuffling_%d_seed_%d', ...
    simplex, subject, session, parcellation, ...
    round(100*peak_threshold), round(100*peak_density_threshold), ...
    round(100*purity_threshold), num_shuffling, seed);

% Save full shuffled modularity results with suffix
if shuffle_all_flag
    variable_names = {'all', 'peak_dense_pure_nodes', 'matched_random_nodes'};
else
    variable_names = {'peak_dense_pure_nodes', 'matched_random_nodes'};
end
full_output_filename = strcat(shuffled_modularity_full_filename, "_", suffix, ".csv");
full_table = array2table(shuffled_mod, ...
    'VariableNames', variable_names);
writetable(full_table, full_output_filename);

% % Save mean shuffled modularity results without suffix
% mean_table = table(simplex, subject, session, parcellation, ...
%     peak_threshold, peak_density_threshold, purity_threshold, ...
%     num_shuffling, seed, ...
%     shuffled_mod_mean(1), shuffled_mod_mean(2), shuffled_mod_mean(3), ...
%     'VariableNames', {'simplex', 'subject', 'session', 'parcellation', ...
%                       'peak_threshold', 'peak_density_threshold', 'purity_threshold', ...
%                       'num_shuffling', 'seed', ...
%                       'all', 'peak_dense_pure_nodes', 'matched_random_nodes'});
% writetable(mean_table, shuffled_modularity_mean_filename, 'VariableNamingRule', 'preserve');


end
