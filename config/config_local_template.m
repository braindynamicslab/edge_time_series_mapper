function config = config_local()
    % Local machine configuration settings
    %
    % Note: Assumes Oak is mounted locally for data access
    %
    % Outputs:
    %   config - Configuration struct with local machine paths
    
    % Detect repository root
    config.repo_root = fcn_utils_detect_repo_root();
    
    % HCP fMRI data paths (assumes Oak is mounted)
    config.hcp_fmri_dir = "/oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out";
    config.batch_table_path = fullfile(config.hcp_fmri_dir, "subject_batch.csv");
    
    % Scratch directory for temporary files
    config.scratch_dir = fullfile(config.repo_root, "data_pipeline_gitignore", "temp");
end