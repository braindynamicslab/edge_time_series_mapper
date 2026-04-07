function [is_match, cohort, session, simplex, parcellation, feature_processing, target, value] = fcn_io_parse_simplex_mapper_directory_name_pca(directory_name)
    % Parse simplex mapper directory name into components
    %
    % Uses regular expression with named capture groups to extract all fields.
    % The pattern is built around our custom "||" marker that separates
    % experiment configuration from pipeline configuration.
    %
    % Directory name pattern:
    %   simplex_mapper_raw_features_cohort_<cohort>_<session>_<simplex>_<parcellation>||_dim_reduction_type_<feature_processing>_target_<target>_<value>
    %
    % Where:
    %   cohort - May contain underscores (e.g., "one", "all_but_one")
    %   session - Exactly "LR" or "RL"
    %   simplex - Exactly "node", "edge", or "triangle"
    %   parcellation - Format "schaefer###x##" (e.g., "schaefer100x7")
    %   feature_processing - Exactly "pca_fixed_component" or "pca_variance_threshold"
    %   target - Exactly "num_features" or "explained_variance"
    %   value - Digits and underscores only (e.g., "0_95", "20")
    %
    % Inputs:
    %   dirname - Directory name string to parse
    %
    % Outputs:
    %   cohort - Cohort identifier
    %   session - Session identifier
    %   simplex - Simplex type
    %   parcellation - Parcellation name
    %   feature_processing - Feature processing method
    %   target - Target metric
    %   value - Target value
    %   All outputs are empty strings ("") if pattern doesn't match
    %
    % Example:
    %   dirname = "simplex_mapper_raw_features_cohort_all_but_one_LR_edge_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    %   [cohort, session, simplex, parcellation, feature_processing, target, value] = ...
    %       fcn_utils_parse_simplex_mapper_dirname(dirname);
    %   % Returns:
    %   % cohort="all_but_one", session="LR", simplex="edge", parcellation="schaefer100x7"
    %   % feature_processing="pca_variance_threshold", target="explained_variance", value="0_95"
    %
    % See also: regexp, strsplit
    
    % Initialize outputs to empty strings (returned if parsing fails)
    is_match = 0;
    cohort = "";
    session = "";
    simplex = "";
    parcellation = "";
    feature_processing = "";
    target = "";
    value = "";
    
    % Convert to string if needed
    directory_name = string(directory_name);
    
    % Build regex pattern with named capture groups
    % Use char array (single quotes) to avoid double-escaping backslashes
    pattern = strcat(...
        'simplex_mapper_raw_features_cohort_', ...  % Fixed literal prefix
        '(?<cohort>.+?)', ...                       % Cohort: any chars, non-greedy (handles "all_but_one")
        '_(?<session>LR|RL)', ...                   % Session: exactly LR or RL
        '_(?<simplex>node|edge|triangle)', ...      % Simplex: exactly one of three values
        '_(?<parcellation>schaefer\d+x\d+)', ...    % Parcellation: schaefer###x## format
        '\|\|_dim_reduction_type_', ...             % Our custom || marker + fixed text (|| escaped as \|\|)
        '(?<feature_processing>pca_fixed_components|pca_variance_threshold)', ... % Feature processing: exactly one of two values
        '_target_', ...                             % Fixed separator
        '(?<target>num_features|explained_variance)', ... % Target: exactly one of two values
        '_(?<value>[\d_]+)$');                      % Value: digits and underscores only, must end string ($)
    
    % Attempt to match pattern
    % regexp returns empty array if no match, struct with fields if match succeeds
    tokens = regexp(char(directory_name), pattern, 'names');
    
    % If match successful, extract fields from struct
    if ~isempty(tokens)
        is_match = 1;
        cohort = string(tokens.cohort);
        session = string(tokens.session);
        simplex = string(tokens.simplex);
        parcellation = string(tokens.parcellation);
        feature_processing = string(tokens.feature_processing);
        target = string(tokens.target);
        value = string(tokens.value);
    end
end