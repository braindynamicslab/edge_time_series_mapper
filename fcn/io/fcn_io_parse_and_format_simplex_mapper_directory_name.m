function [rename_flag, output_name] = fcn_io_parse_and_format_simplex_mapper_directory_name(dirname)
    % Parse simplex mapper directory name and format for output
    %
    % This function handles different naming conventions for simplex mapper
    % directories and returns a standardized output format based on the
    % directory structure.
    %
    % Logic:
    %   1. If dirname contains "||":
    %      a. If nothing after "||": return everything before "||"
    %      b. If contains "pca": parse with fcn_io_parse_simplex_mapper_dirname,
    %         format as: simplex_mapper_<feature_processing>_<value>_cohort_<cohort>_<session>_<simplex>_<parcellation>
    %         where value is the part after "_" in the original value (e.g., "0_95" → "95")
    %      c. If contains "sign" and "mask": return simplex_mapper_coherence_cohort_<cohort>_<session>_<simplex>_<parcellation>
    %   2. If dirname doesn't contain "||": return empty string
    %
    % Inputs:
    %   dirname - Directory name string to parse
    %
    % Outputs:
    %   output_name - Formatted directory name string, or "" if parsing fails
    %
    % Example 1 (PCA case):
    %   dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    %   output_name = fcn_io_parse_and_format_simplex_mapper_dirname(dirname);
    %   % Returns: "simplex_mapper_pca_variance_threshold_95_cohort_one_LR_edge_schaefer100x7"
    %
    % Example 2 (Nothing after ||):
    %   dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7||";
    %   output_name = fcn_io_parse_and_format_simplex_mapper_dirname(dirname);
    %   % Returns: "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7"
    %
    % Example 3 (Coherence case):
    %   dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7||_sign_mask_coherence_analysis";
    %   output_name = fcn_io_parse_and_format_simplex_mapper_dirname(dirname);
    %   % Returns: "simplex_mapper_coherence_cohort_one_LR_edge_schaefer100x7"
    %
    % See also: fcn_io_parse_simplex_mapper_dirname
    
    % Initialize output to empty string
    output_name = dirname;
    
    % Convert to string if needed
    dirname = string(dirname);
    
    % Check if dirname contains "||"
    if ~contains(dirname, "||")
        rename_flag = 0;
        return;
    end

    rename_flag = 1;
    
    % Split at "||" marker
    parts = split(dirname, "||");
    left_part = parts(1);   % Everything before ||
    
    % Check if there's anything after ||
    if numel(parts) == 1 || strlength(parts(2)) == 0
        % Case 1: Nothing after || - return everything before ||
        output_name = left_part;
        return;
    end
    
    right_part = parts(2);  % Everything after ||
    
    % Check which type of processing is indicated
    if contains(right_part, "pca")
        % Case 2: PCA processing - parse and reformat
        
        % Call the parsing function
        [is_match, cohort, session, simplex, parcellation, feature_processing, target, value] = ...
            fcn_io_parse_simplex_mapper_directory_name_pca(dirname);
        
        % Check if parsing succeeded
        if ~is_match
            warning('Failed to parse PCA directory name: %s', dirname);
            return;
        end
        
        % Process value: if it contains "_", take everything after the last "_"
        if contains(value, "_")
            value_parts = strsplit(char(value), "_");
            value_formatted = string(value_parts{end});
        else
            value_formatted = value;
        end
        
        % Format output: simplex_mapper_<feature_processing>_<value>_cohort_<cohort>_<session>_<simplex>_<parcellation>
        output_name = strcat(...
            "simplex_mapper_", ...
            feature_processing, "_", ...
            value_formatted, "_", ...
            "cohort_", cohort, "_", ...
            session, "_", ...
            simplex, "_", ...
            parcellation);
        
    elseif contains(right_part, "sign") && contains(right_part, "mask")
        % Case 3: Coherence analysis - extract cohort/session/simplex/parcellation from left part
        
        % Parse left part to extract fields
        % Expected format: simplex_mapper_raw_features_cohort_<cohort>_<session>_<simplex>_<parcellation>
        
        % Remove prefix
        PREFIX = "simplex_mapper_raw_features_cohort_";
        if ~startsWith(left_part, PREFIX)
            warning('Left part does not start with expected prefix "%s": %s', PREFIX, left_part);
            return;
        end
        left_part_trimmed = erase(left_part, PREFIX);
        
        % Split by underscores and parse backward
        left_parts = strsplit(char(left_part_trimmed), "_");
        
        % Need at least 4 parts: cohort, session, simplex, parcellation
        if numel(left_parts) < 4
            warning('Left part has too few fields: %s', left_part_trimmed);
            return;
        end
        
        % Parse backward from end
        parcellation = string(left_parts{end});         % Last field
        simplex = string(left_parts{end-1});            % Third-to-last
        session = string(left_parts{end-2});            % Second-to-last
        
        % Cohort is everything remaining (may contain underscores)
        if numel(left_parts) == 4
            cohort = string(left_parts{1});
        else
            cohort = string(strjoin(left_parts(1:end-3), "_"));
        end
        
        % Format output: simplex_mapper_coherence_cohort_<cohort>_<session>_<simplex>_<parcellation>
        output_name = strcat(...
            "simplex_mapper_coherence_", ...
            "cohort_", cohort, "_", ...
            session, "_", ...
            simplex, "_", ...
            parcellation);
        
    else
        % Unknown type after ||
        warning('Directory name contains || but does not match known patterns (pca, or sign+mask): %s', dirname);
        return;
    end
end