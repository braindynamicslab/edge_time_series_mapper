function config = fcn_utils_get_config()
    % Get project configuration settings
    %
    % Returns configuration struct with paths and settings appropriate
    % for the current environment (local vs Sherlock HPC).
    %
    % The function detects the environment and calls the appropriate
    % configuration file:
    %   - config_sherlock() on Sherlock (detected via hostname)
    %   - config_local() on local machines
    %
    % Outputs:
    %   config - Configuration struct with fields:
    %            .repo_root - Repository root directory
    %            .hcp_fmri_dir - HCP fMRI data directory on Oak
    %            .batch_table_path - Path to subject_batch.csv
    %            .scratch_dir - Temporary/scratch directory
    %
    % Example:
    %   config = fcn_utilsConfig_get_config();
    %   data = load(fullfile(config.repo_root, 'data_raw', 'example.mat'));
    %
    % See also: config_sherlock, config_local
    
    % Detect environment
    [~, hostname] = system('hostname');
    hostname = string(strtrim(hostname));
    
    % Sherlock nodes have hostnames like:
    %   - Login: "sherlock.stanford.edu", "login.sherlock.stanford.edu"
    %   - Compute: "sh-101-58", "sh-102-12", etc.
    if contains(hostname, "sherlock") || contains(hostname, "sh")
        config = config_sherlock();
    else
        config = config_local();
    end
end