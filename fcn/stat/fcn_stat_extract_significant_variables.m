function [node_vars, edge_vars, triangle_vars] = fcn_stat_extract_significant_variables(table1_results, var_dict)
    % Extract response variables that show significance in Table 1
    % Priority: BH-corrected significance, then raw significance
    
    modularity_types = ["Node", "Edge", "Triangle"];
    var_arrays = cell(1, 3);
    
    for i = 1:length(modularity_types)
        simplex_name = modularity_types(i);
        
        % Filter to this simplex type
        idx = strcmp(table1_results.Simplex, simplex_name);
        simplex_data = table1_results(idx, :);
        
        % Try BH-corrected significance first
        sig_col = "Significance (two-tail, BH corrected)";
        if ismember(sig_col, simplex_data.Properties.VariableNames)
            sig_vars = simplex_data.("Response Variable")(~strcmp(string(simplex_data.(sig_col)), "0"));
        else
            sig_vars = [];
        end
        
        % Fallback to raw significance if no BH-significant variables
        if isempty(sig_vars)
            sig_col = "Significance (two-tail)";
            sig_vars = simplex_data.("Response Variable")(~strcmp(string(simplex_data.(sig_col)), "0"));
        end
        
        % Convert display names back to variable codes
        unique_sig_vars = unique(sig_vars, 'stable');
        var_codes = string([]);
        
        for j = 1:length(unique_sig_vars)
            display_name = unique_sig_vars(j);
            % Find the original code from var_dict
            var_code = fcn_utils_get_variable_code_from_display_name(var_dict, display_name);
            var_codes = [var_codes; var_code];
        end
        
        var_arrays{i} = var_codes;
    end
    
    node_vars = var_arrays{1};
    edge_vars = var_arrays{2};
    triangle_vars = var_arrays{3};
end

