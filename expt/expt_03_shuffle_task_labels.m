%cohorts = ["one", "two"];
cohorts = ["two"];
session = "LR";

config = fcn_utils_get_config();
shuffled_modularity_directory = fullfile(...
    config.scratch_dir, "shuffled_modularity");
shuffled_modularity_filename = "shuffled_modularity";


if ~isfolder(shuffled_modularity_directory)
    mkdir(shuffled_modularity_directory);
end
shuffled_modularity_full_filename = fullfile(shuffled_modularity_directory, shuffled_modularity_filename);

%purity_thresholds = [0.75, 1];
purity_thresholds = 0.75;
peak_density_thresholds = [0.8, 0.9, 0.95];

simplex = "edge";
parcellation = "schaefer100x7";
peak_threshold = 0.95;
num_shuffling = 1000;
seed = 0;

for cohort = cohorts
    for purity_threshold = purity_thresholds
        for peak_density_threshold = peak_density_thresholds
            
            if abs(peak_density_threshold - 0.9) < 0.01
                shuffle_all_flag = 1;
            else
                shuffle_all_flag = 0; % no need to repeat the shuffle all experiment because this has already been done
            end
            
            cohort_csv = fullfile(config.repo_root, "data_pipeline", "data_cohort", ...
                sprintf("cohort_%s_session_%s.csv", cohort, session));
            subjects = readtable(cohort_csv).Subject;
            num_subjects = numel(subjects);
            parfor subject_idx = 1:numel(subjects)
                subject = subjects(subject_idx);
                fprintf("%s. cohort: %s, purity_threshold: %.2g, peak_density_threshold: %.2g, subject: %d (%d/%d) \n", ...
                    datetime('now'), cohort, purity_threshold, peak_density_threshold, subject, subject_idx, num_subjects);
                fcn_peakDense_shuffle_task_labels(simplex, subject, session, parcellation, peak_threshold, peak_density_threshold, purity_threshold, num_shuffling, seed, shuffled_modularity_full_filename, 'shuffle_all_flag', shuffle_all_flag);
            end
        end
    end
end
