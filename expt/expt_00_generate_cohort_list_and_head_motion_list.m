repo_path = fcn_utils_get_repo_path_interactively();
addpath(genpath(repo_path))

fcn_io_check_fmri_data_valid_proportion();
fcn_io_generate_cohort_subject_lists();
fcn_io_generate_mean_head_motion_csv();

