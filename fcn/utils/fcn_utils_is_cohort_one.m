function is_cohort_one = fcn_utils_is_cohort_one(subject, session)

config = fcn_utils_get_config();
cohort_one_subjects_filename = sprintf("cohort_one_session_%s.csv", session);
cohort_one_subjects_path = fullfile(config.repo_root, "data_pipeline", "data_cohort", cohort_one_subjects_filename);
cohort_one_subjects = readtable(cohort_one_subjects_path).Subject;

is_cohort_one = ismember(subject, cohort_one_subjects);
end