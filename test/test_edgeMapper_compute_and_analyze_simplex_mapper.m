
session = "LR";
parcellation = "schaefer100x7";
simplex = "node";
% simplex = "edge";

subject = 100206;

config = fcn_utils_get_config();
output_directory = fullfile(config.repo_root, "data_pipeline_gitignore/test/test_fcn_edgeMapper_compute_and_analyze_simplex_mapper");

compute_flag = 1;
% compute_flag = 0;

% pretuned_mapper_param_flag = 0;
pretuned_mapper_param_flag = 1;

debug_flag = 0;
% debug_flag = 1;

% tmp_csv_flag = 0;
tmp_csv_flag = 1;

mapper_params = fcn_edgeMapper_get_default_mapper_parameters(pretuned_mapper_param_flag == 0);
if pretuned_mapper_param_flag
    mapper_auto_tune_flag = 0;
    mapper_params.num_k = 48;
    mapper_params.res_val = 9;
    mapper_params.gain_val = 50;
    mapper_params.num_bin_cluster = 10;
else
    mapper_auto_tune_flag = 1;
end

summary_csv_path = "/scratch/users/siuc/edge_time_series_mapper/tmp/tmp.txt";

if compute_flag
    debug_filename = fullfile(output_directory, sprintf("test_compute_and_analyze_simplex_mapper_100206_%s_mapper_input.mat", simplex));
    fcn_edgeMapper_compute_and_analyze_simplex_mapper(subject, parcellation, session, simplex, output_directory, "mapper_auto_tune_flag", mapper_auto_tune_flag, "mapper_params", mapper_params, "debug_flag", debug_flag, "debug_filename", debug_filename, "copy_data_flag", tmp_csv_flag, "summary_csv_path", summary_csv_path);

%     preprocessing_method = 'xcpengine_2025';
%     input_data_path = "/oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/";
%     rest_path = "/oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/";
%     rest_session = strcat(session, '_run-1');
%     
%     new_input_data_path = "/oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out/";
%     new_rest_path = new_input_data_path;
% 
%     zscore_scope = 'each_task';
%     feature_removal_criterion = 'rest_and_all_tasks';
%     mapper_auto_tune_flag = mapper_auto_tune_flag; 
%     dim_reduction_type = 'none'; 
%     activity_mask_flag = 0; 
%     sign_by_coherence_flag = 0; 
%     
%     % parcellation = 'schaefer100x7';
%     target_num_features = 80; 
%     task_configuration = 'rest_5min_and_tasks';
% 
%     output_data_path = output_directory;
%     output_filename = sprintf("simplexMapper_%s_old", simplex);
% 
%     batch_flag = 1;
%     batch_table = readtable("/home/users/siuc/HCP_preprocessing_xcpengine_250827/data/subject_batch.csv");
% 
%     debug_flag = 1;
%     debug_filename_old = fullfile(output_directory, sprintf("test_compute_and_analyze_simplex_mapper_100206_%s_mapper_input_old.mat", simplex));
%     edgeAct_compute_hoi_modularity(input_data_path, output_data_path, subject, parcellation, session, task_configuration, rest_path, rest_session, simplex, dim_reduction_type, zscore_scope, feature_removal_criterion, sign_by_coherence_flag, activity_mask_flag, target_num_features, 1, output_filename, "preprocessing_method", preprocessing_method, "new_input_data_path", new_input_data_path, "new_rest_path", new_rest_path, "batch_flag", batch_flag, "batch_table", batch_table, "debug_flag", debug_flag, "debug_filename", debug_filename_old);
end
% filename_new = sprintf("simplexMapper_%s_%d_%s_%s_data.mat", simplex, subject, session, parcellation);
% data_new = load(fullfile(output_directory, filename_new));
% pre_mapper_param_new = load(fullfile(output_directory, sprintf("test_compute_and_analyze_simplex_mapper_100206_%s_mapper_input.mat", simplex)));
% 
% filename_old = sprintf("simplexMapper_%s_old_data.mat", simplex);
% data_old = load(fullfile(output_directory, filename_old));
% pre_mapper_param_old = load(fullfile(output_directory, sprintf("test_compute_and_analyze_simplex_mapper_100206_%s_mapper_input_old.mat", simplex)));
% 
% 
% data_very_old = load(sprintf("/scratch/users/siuc/HOI_data_output/xcpenging_2025_noFeatureMassaging_%s_%s/brain_state_mapper_noFeatureMassaging_%d_%s_%s_%s_xcpengine_2025_data.mat", session, parcellation, subject, session, simplex, parcellation));
% 
% fprintf("Comparing new codes and old codes\n")
% compare_mapper_data(data_new, data_old);
% 
% fprintf("\n============================\nComparing old codes and results\n")
% compare_mapper_data(data_old, data_very_old);
% fprintf("\n============================\nComparing intermediate results\n")
% for fieldname = ["reduced_data", "mapper_param_res_vals", "mapper_param_gain_vals", "mapper_param_nums_k", "mapper_param_nums_bin_cluster", "ndim"]
%     try
%         max_error = max(max(pre_mapper_param_new.(fieldname) - pre_mapper_param_old.(fieldname)));
%     catch
%         max_error = max(max(pre_mapper_param_new.(fieldname) - pre_mapper_param_old.(strrep(fieldname, "mapper_param_", ""))));
%     end
%     fprintf("%s: %d\n", fieldname, max_error);
% end
% if strcmp(pre_mapper_param_new.metricType, pre_mapper_param_old.metricType)
%     fprintf("metric Type matched: %s\n", pre_mapper_param_new.metricType);
% else
%     fprintf("metric Type matched: new: %s, old: %s", pre_mapper_param_new.metricType, pre_mapper_param_old.metricType);
% end
% 
% figure; scatter(data_old.filter(:, 1), data_old.filter(:, 2)); title("old filter");
% figure; scatter(data_new.mapper_filter(:, 1), data_new.mapper_filter(:, 2)); title("new filter");
% figure; scatter(data_new.mapper_filter(:, 1) - data_old.filter(:, 1), data_new.mapper_filter(:, 2) - data_old.filter(:, 2)); title("difference in filter");

% checked that fcn_mapper_runBDLMapper is the same as hoiAux_runBDL_mapper
% up to function renaming

function compare_mapper_data(data_new, data_old)
    % Compare two mapper datasets - only fields that exist in new data
    
    fprintf('=== MAPPER DATA COMPARISON ===\n\n');
    
    % Field name mapping (new -> old)
    field_map = struct(...
        'mapper_filter', 'filter', ...
        'mapper_nodeBynode', 'nodeBynode', ...
        'mapper_nodeTpMat', 'nodeTpMat', ...
        'mapper_tpMat', 'tpMat', ...
        'mapper_param_gain_vals', 'mapper_gain_vals', ...
        'mapper_param_nums_bin_cluster', 'mapper_nums_bin_cluster', ...
        'mapper_param_nums_k', 'mapper_nums_k', ...
        'mapper_param_res_vals', 'mapper_res_vals', ...
        'mapper_stat_mode_task_indices', 'modeTaskIndices', ...
        'mapper_stat_modularity', 'mod', ...
        'mapper_stat_task_count_per_node', 'taskCountPerNode', ...
        'feature_tasks_instantwise', 'tasks_instantwise', ...
        'amplitude_nodewise', 'amplitude', ...
        'pca_explained_variance', 'pca_explained_variance', ...
        'mapper_nodes_positions', 'mapper_nodes_positions' ...
    );
    
    % Get new data field names
    new_fields = fieldnames(data_new);
    
    % Compare each field in new data
    num_compared = 0;
    num_identical = 0;
    num_different = 0;
    num_no_old_match = 0;
    
    for i = 1:length(new_fields)
        new_field = new_fields{i};
        
        % Check if this field has a mapping to old data
        if isfield(field_map, new_field)
            old_field = field_map.(new_field);
        else
            % Try exact match
            if isfield(data_old, new_field)
                old_field = new_field;
            else
                fprintf('⊘ %s (no corresponding field in old data)\n', new_field);
                num_no_old_match = num_no_old_match + 1;
                continue;
            end
        end
        
        % Check if old field exists
        if ~isfield(data_old, old_field)
            fprintf('⊘ %s -> %s (old field not found)\n', new_field, old_field);
            num_no_old_match = num_no_old_match + 1;
            continue;
        end
        
        num_compared = num_compared + 1;
        
        % Compare values
        old_val = data_old.(old_field);
        new_val = data_new.(new_field);
        
        [is_equal, msg] = compare_values(old_val, new_val);
        
        if is_equal
            fprintf('✓ %s == %s\n', new_field, old_field);
            num_identical = num_identical + 1;
        else
            fprintf('✗ %s != %s: %s\n', new_field, old_field, msg);
            num_different = num_different + 1;
        end
    end
    
    % Summary
    fprintf('\n=== SUMMARY ===\n');
    fprintf('Total fields in new data: %d\n', length(new_fields));
    fprintf('Compared: %d\n', num_compared);
    fprintf('Identical: %d\n', num_identical);
    fprintf('Different: %d\n', num_different);
    fprintf('No old match: %d\n', num_no_old_match);
    
    if num_different > 0
        fprintf('\n⚠ WARNING: %d fields differ between datasets\n', num_different);
    end
    
    if num_compared == num_identical
        fprintf('\n✓ All comparable fields are identical!\n');
    end
end

function [is_equal, msg] = compare_values(val1, val2)
    % Compare two values with detailed diagnostics
    
    % Check class
    if ~strcmp(class(val1), class(val2))
        is_equal = false;
        msg = sprintf('Different types: %s vs %s', class(val1), class(val2));
        return;
    end
    
    % Check size
    if ~isequal(size(val1), size(val2))
        is_equal = false;
        msg = sprintf('Different sizes: [%s] vs [%s]', ...
            mat2str(size(val1)), mat2str(size(val2)));
        return;
    end
    
    % Compare based on type
    if isnumeric(val1) || islogical(val1)
        % Numeric/logical comparison
        if all(isnan(val1(:))) && all(isnan(val2(:)))
            is_equal = true;
            msg = 'Both all NaN';
        elseif isequaln(val1, val2)
            is_equal = true;
            msg = 'Identical';
        else
            % Check if nearly equal
            if isnumeric(val1) && ~isempty(val1)
                max_diff = max(abs(val1(:) - val2(:)));
                max_val = max(abs(val1(:)));
                
                if max_val > 0
                    rel_diff = max_diff / max_val;
                else
                    rel_diff = 0;
                end
                
                if max_diff < 1e-10
                    is_equal = true;
                    msg = sprintf('Nearly equal (max diff: %.2e)', max_diff);
                else
                    is_equal = false;
                    msg = sprintf('Max diff: %.2e, Rel diff: %.2e', max_diff, rel_diff);
                end
            else
                num_diff = sum(val1(:) ~= val2(:));
                is_equal = false;
                msg = sprintf('%d/%d elements differ', num_diff, numel(val1));
            end
        end
        
    elseif ischar(val1) || isstring(val1)
        % String comparison
        if isequal(val1, val2)
            is_equal = true;
            msg = 'Identical';
        else
            is_equal = false;
            if isscalar(val1) && isscalar(val2)
                msg = sprintf('"%s" vs "%s"', string(val1), string(val2));
            else
                msg = 'String contents differ';
            end
        end
        
    elseif iscell(val1)
        % Cell comparison
        if isequaln(val1, val2)
            is_equal = true;
            msg = 'Identical';
        else
            is_equal = false;
            msg = 'Cell contents differ';
        end
        
    elseif isstruct(val1)
        % Struct comparison
        if isequaln(val1, val2)
            is_equal = true;
            msg = 'Identical';
        else
            is_equal = false;
            msg = 'Struct contents differ';
        end
        
    else
        % Unknown type
        is_equal = isequaln(val1, val2);
        if is_equal
            msg = 'Identical';
        else
            msg = sprintf('Differ (type: %s)', class(val1));
        end
    end
end