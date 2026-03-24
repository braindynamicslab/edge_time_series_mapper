function config = config_sherlock()
    % Sherlock HPC configuration settings
    %
    % Outputs:
    %   config - Configuration struct with Sherlock-specific paths
    
    % Detect repository root
    config.repo_root = fcn_utils_detect_repo_root();
    
    % HCP fMRI data paths on Oak
    config.hcp_fmri_dir = "/oak/stanford/groups/saggar/hcp_processed/xcpengine_2025_out";
    config.batch_table_path = fullfile(config.hcp_fmri_dir, "subject_batch.csv");
    
    % Scratch directory for temporary files
    username = getenv("USER");
    config.scratch_dir = fullfile("/scratch/users", username, "edge_time_series_mapper");
end