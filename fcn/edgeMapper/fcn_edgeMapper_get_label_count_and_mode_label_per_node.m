function [label_count, mode_label_indices] = fcn_edgeMapper_get_label_count_and_mode_label_per_node(node_tp_mat, data_labels, label_list)
    % fcn_edgeMapper_get_label_count_and_mode_label_per_node Count labels per node and find mode label
    %
    % Inputs:
    %   node_tp_mat - [n_nodes x n_points] sparse logical matrix mapping nodes to points
    %   data_labels - [n_points x 1] string array of labels for each point
    %   label_list - [n_labels x 1] string array of unique labels
    %
    % Outputs:
    %   label_count - [n_nodes x n_labels] count of each label per node
    %   mode_label_indices - [n_nodes x 1] index into label_list of most common label per node
    
    [~, data_label_indices] = ismember(data_labels, label_list);
    if any(data_label_indices == 0)
        error("fcn_edgeMapper_get_label_count_and_mode_label_per_node:labelNotFound", ...
            "Some labels are not in label_list.");
    end
    
    data_label_binary = data_label_indices(:) == 1:length(label_list);
    label_count = node_tp_mat * data_label_binary;
    [~, mode_label_indices] = max(label_count, [], 2);
    
end