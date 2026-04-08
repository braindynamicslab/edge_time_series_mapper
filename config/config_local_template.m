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

    % HCP non-imaging data
    config.hcp_restricted_data_path = "/Users/siuc/Documents/hcp_nonimaging_data/restricted_siuc_3_24_2025_15_27_00.csv";
    config.hcp_unrestricted_data_path = "/Users/siuc/Documents/hcp_nonimaging_data/unrestricted_siuc_2_17_2025_12_16_57.csv";
end