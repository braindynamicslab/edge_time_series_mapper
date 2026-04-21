config = fcn_utils_get_config();

output_directory = fullfile(config.scratch_dir, "data_pipeline", "pairwise_distances");
if ~isfolder(output_directory)
    mkdir(output_directory);
end

parcellation = "schaefer100x7";
cohorts = ["one", "two"];
simplices = ["node"];%, "edge"];

tasks = ["REST", ...
    "EMOTION", ...
    "GAMBLING", ...
    "LANGUAGE", ...
    "MOTOR", ...
    "RELATIONAL", ...
    "SOCIAL", ...
    "WM"];
% Get time windows (first 5 min of REST)
[start_times, end_times, unit, tr] = ...
    fcn_edgeMapper_get_time_windows(tasks, "rest_5min_and_tasks");

auto_tune_flag = 1;
mapper_params = fcn_edgeMapper_get_default_mapper_parameters(auto_tune_flag);
metric_type = mapper_params.metric_type;


for cohort = cohorts

    for session = ["LR"] %["LR", "RL"]
        %         if strcmp(cohort, "one") && strcmp(session, "LR")
        %             fprintf("done\n")
        %             break;
        %         end

        sublist_csv = fullfile(config.repo_root, "data_pipeline", "data_cohort", sprintf("cohort_%s_session_%s.csv", cohort, session));
        subjects = readtable(sublist_csv).Subject;

        for subject_idx = 1:numel(subjects) %subjects = [143325]; % cohort 1 RL subject_id = 158, no pure node for gambling task
            subject = subjects(subject_idx);
            fprintf("%s: %d (%d  out of %d)\n", datetime('now'), subject, subject_idx, numel(subjects))
            for simplex = simplices
                [reduced_data, feature_indices, tasks_instantwise, feature_removal_mask, missing_data_flag, ~] = ...
                    fcn_edgeMapper_get_processed_simplex_time_series_data(...
                    subject, parcellation, session, simplex, tasks, ...
                    'starting_times', start_times, ...
                    'ending_times', end_times, ...
                    'unit_time', unit, ...
                    'seconds_per_TR', tr, ...
                    'verbose_flag', 0);
                dist_mat = pdist(reduced_data, metric_type);
                output_filename = sprintf("framewise_pairwise_distances_%s_%d_%s_%s.mat", simplex, subject, session, parcellation);
                full_output_filename =fullfile(output_directory, output_filename);
                save(full_output_filename, "dist_mat", '-v7.3');
            end

        end

    end
end