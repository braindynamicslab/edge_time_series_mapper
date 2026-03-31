subject = 100206;
session = "LR";
parcellation = "schaefer100x7";

preprocessing_method = 'xcpengine_2025';


input_data_path = "/oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/";
rest_path = "/oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/";
rest_session = strcat(session, '_run-1');

new_input_data_path = "/oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/";
new_rest_path = new_input_data_path;

batch_flag = 1;
batch_table = readtable("/home/users/siuc/HCP_preprocessing_xcpengine_250827/data/subject_batch.csv");

debug_flag = 0;

% for simplex = ["node", "edge", "triangle"]
%     [reduced_data, feature_indices, tasks_instantwise, feature_removal_mask, missing_data_flag, pca_results, debug_data] = ...
%         fcn_edgeMapper_get_processed_simplex_time_series_data(subject, parcellation, session, simplex);
% 
% 
%     [reduced_data_old, idx, tasks_instantwise_old, removed_feature_indices, debug_data_old] = edgeAct_get_reduced_data(subject, parcellation, session, simplex, "preprocessing_method", preprocessing_method);
% 
%     % 1. reduced_data vs reduced_data_old
%     fprintf('Comparing reduced_data:\n');
%     if isequal(size(reduced_data), size(reduced_data_old))
%         max_diff = max(abs(reduced_data - reduced_data_old), [], 'all');
%         fprintf('  Size match: %s\n', mat2str(size(reduced_data)));
%         fprintf('  Max absolute difference: %.15e\n', max_diff);
%     else
%         fprintf('  SIZE MISMATCH! New: %s, Old: %s\n\n', ...
%             mat2str(size(reduced_data)), mat2str(size(reduced_data_old)));
%     end
% 
%     % 2. feature_indices vs idx
%     fprintf('Comparing feature_indices (new) vs idx (old):\n');
%     if isequal(size(feature_indices), size(idx))
%         if isequal(feature_indices, idx)
%             fprintf('  EXACT MATCH\n\n');
%         else
%             fprintf('  Size match but values differ\n');
%             fprintf('  Number of differences: %d\n\n', sum(feature_indices ~= idx));
%         end
%     else
%         fprintf('  SIZE MISMATCH! New: %s, Old: %s\n\n', ...
%             mat2str(size(feature_indices)), mat2str(size(idx)));
%     end
% 
%     % 3. tasks_instantwise vs tasks_instantwise_old
%     fprintf('Comparing tasks_instantwise:\n');
%     if isequal(size(tasks_instantwise), size(tasks_instantwise_old))
%         max_diff = sum(strcmp(tasks_instantwise, tasks_instantwise_old) == 0);
%             fprintf('  Number of differences: %.15e\n', max_diff);
%     end
% 
%     % 4. feature_removal_mask vs removed_feature_indices
%     fprintf('Comparing feature_removal_mask vs removed_feature_indices:\n');
%     if exist('removed_feature_indices', 'var')
%         % Convert mask to indices for comparison
% 
%         if isequal(feature_removal_mask, removed_feature_indices)
%             fprintf('  EXACT MATCH\n\n');
%         else
%             fprintf('  MISMATCH in removed features\n\n');
%         end
%     else
%         fprintf('  removed_feature_indices not returned by old function\n\n');
%     end
% end

% 
% target_num_features = 50;
% 
% for simplex = ["node", "edge", "triangle"]
%     [reduced_data, feature_indices, tasks_instantwise, feature_removal_mask, missing_data_flag, pca_results, debug_data] = ...
%         fcn_edgeMapper_get_processed_simplex_time_series_data(subject, parcellation, session, simplex, "dim_reduction_type", "pca_fixed_components", "target_num_features", target_num_features);
% 
% 
%     [reduced_data_old, idx, tasks_instantwise_old, removed_feature_indices, debug_data_old] = edgeAct_get_reduced_data(subject, parcellation, session, simplex, "preprocessing_method", preprocessing_method, "dim_reduction_type", 'PCA', "target_num_features", target_num_features);
% 
%     % 1. reduced_data vs reduced_data_old
%     fprintf('Comparing reduced_data:\n');
%     if isequal(size(reduced_data), size(reduced_data_old))
%         max_diff = max(abs(reduced_data - reduced_data_old), [], 'all');
%         fprintf('  Size match: %s\n', mat2str(size(reduced_data)));
%         fprintf('  Max absolute difference: %.15e\n', max_diff);
%     else
%         fprintf('  SIZE MISMATCH! New: %s, Old: %s\n\n', ...
%             mat2str(size(reduced_data)), mat2str(size(reduced_data_old)));
%     end
% 
%     % 2. feature_indices vs idx
%     fprintf('Comparing feature_indices (new) vs idx (old):\n');
%     if isequal(size(feature_indices), size(idx))
%         if isequal(feature_indices, idx)
%             fprintf('  EXACT MATCH\n\n');
%         else
%             fprintf('  Size match but values differ\n');
%             fprintf('  Number of differences: %d\n\n', sum(feature_indices ~= idx));
%         end
%     else
%         fprintf('  SIZE MISMATCH! New: %s, Old: %s\n\n', ...
%             mat2str(size(feature_indices)), mat2str(size(idx)));
%     end
% 
%     % 3. tasks_instantwise vs tasks_instantwise_old
%     fprintf('Comparing tasks_instantwise:\n');
%     if isequal(size(tasks_instantwise), size(tasks_instantwise_old))
%         max_diff = sum(strcmp(tasks_instantwise, tasks_instantwise_old) == 0);
%             fprintf('  Number of differences: %.15e\n', max_diff);
%     end
% 
%     % 4. feature_removal_mask vs removed_feature_indices (inverse relationship)
%     fprintf('Comparing feature_removal_mask vs removed_feature_indices:\n');
%     if exist('removed_feature_indices', 'var')
%         % Convert mask to indices for comparison
% 
%         if isequal(feature_removal_mask, removed_feature_indices)
%             fprintf('  EXACT MATCH\n\n');
%         else
%             fprintf('  MISMATCH in removed features\n\n');
%         end
%     else
%         fprintf('  removed_feature_indices not returned by old function\n\n');
%     end
% end

target_explained_variance = 0.80;

%%% old code is wrong.

for simplex = ["node", "edge", "triangle"]
    [reduced_data, feature_indices, tasks_instantwise, feature_removal_mask, missing_data_flag, pca_results, debug_data] = ...
        fcn_edgeMapper_get_processed_simplex_time_series_data(subject, parcellation, session, simplex, "dim_reduction_type", "pca_variance_threshold", "target_explained_variance", target_explained_variance);


    [reduced_data_old, idx, tasks_instantwise_old, removed_feature_indices, debug_data_old] = edgeAct_get_reduced_data(subject, parcellation, session, simplex, "preprocessing_method", preprocessing_method, "dim_reduction_type", 'PCA_target_explained_variance', "PCA_target_explained_variance", target_explained_variance);

    % 1. reduced_data vs reduced_data_old
    fprintf('Comparing reduced_data:\n');
    if isequal(size(reduced_data), size(reduced_data_old))
        max_diff = max(abs(reduced_data - reduced_data_old), [], 'all');
        fprintf('  Size match: %s\n', mat2str(size(reduced_data)));
        fprintf('  Max absolute difference: %.15e\n', max_diff);
    else
        fprintf('  SIZE MISMATCH! New: %s, Old: %s\n\n', ...
            mat2str(size(reduced_data)), mat2str(size(reduced_data_old)));
    end

    % 2. feature_indices vs idx
    fprintf('Comparing feature_indices (new) vs idx (old):\n');
    if isequal(size(feature_indices), size(idx))
        if isequal(feature_indices, idx)
            fprintf('  EXACT MATCH\n\n');
        else
            fprintf('  Size match but values differ\n');
            fprintf('  Number of differences: %d\n\n', sum(feature_indices ~= idx));
        end
    else
        fprintf('  SIZE MISMATCH! New: %s, Old: %s\n\n', ...
            mat2str(size(feature_indices)), mat2str(size(idx)));
    end

    % 3. tasks_instantwise vs tasks_instantwise_old
    fprintf('Comparing tasks_instantwise:\n');
    if isequal(size(tasks_instantwise), size(tasks_instantwise_old))
        max_diff = sum(strcmp(tasks_instantwise, tasks_instantwise_old) == 0);
            fprintf('  Number of differences: %.15e\n', max_diff);
    end

    % 4. feature_removal_mask vs removed_feature_indices (inverse relationship)
    fprintf('Comparing feature_removal_mask vs removed_feature_indices:\n');
    if exist('removed_feature_indices', 'var')
        % Convert mask to indices for comparison

        if isequal(feature_removal_mask, removed_feature_indices)
            fprintf('  EXACT MATCH\n\n');
        else
            fprintf('  MISMATCH in removed features\n\n');
        end
    else
        fprintf('  removed_feature_indices not returned by old function\n\n');
    end
end