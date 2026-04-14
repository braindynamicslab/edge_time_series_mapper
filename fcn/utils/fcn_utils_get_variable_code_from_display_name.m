function var_code = fcn_utils_get_variable_code_from_display_name(var_dict, display_name)
    % Reverse lookup: find variable code from display name
    fields = fieldnames(var_dict);
    
    for i = 1:length(fields)
        field = fields{i};
        if startsWith(field, 'response_') && strcmp(var_dict.(field), display_name)
            var_code = strrep(field, 'response_', '');
            return;
        end
    end
    
    % If not found, return the display name (shouldn't happen)
    var_code = display_name;
end