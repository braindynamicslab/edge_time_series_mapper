config = fcn_utils_get_config();


subjects = [...
    100206;...
    ]
session = "LR";
parcellation = "schaefer100x7";
simplex = "node";

input_pdist_directory = fullfile(config.scratch_dir, "data_pipeline", "pairwise_distances");
input_task_directory = fullfile(config.scratch_dir);
output_directory = fullfile(config.repo_root, "data_pipeline", "pairwise_distances");

num_subjects = numel(subjects);
top_dist_across_subjects_table = table(zeros(num_subjects * 2,1), strings(num_subjects * 2, 1), strings(num_subjects * 2, 1), zeros(num_subjects * 2, 1), zeros(num_subjects * 2, 1), zeros(num_subjects * 2, 1), zeros(num_subjects * 2, 1), zeros(num_subjects * 2, 1), zeros(num_subjects * 2, 1), ...
    'VariableNames', ["Subject", "task 1", "task 2", "TR 1 within task", "TR 2 within task", "is maximum across tasks", "TR 1 in concatenated tasks", "TR 2 in concatenated tasks", "pdist"]);

for subject_idx = 1:numel(subjects)
    subject = subjects(subject_idx);
    feature_processing = "raw_features";
    pdist_filename = sprintf("framewise_pairwise_distances_%s_%d_%s_%s.mat", simplex, subject, session, parcellation);
    dist_mat = matfile(fullfile(input_pdist_directory, pdist_filename)).dist_mat;

    
    tasks_filename = sprintf("simplex_mapper_raw_features_cohort_one_%s_%s_%s/simplexMapper_%s_%d_%s_%s_data.mat", session, simplex, parcellation, simplex, subject, session, parcellation);
    tasks_instantwise = matfile(fullfile(input_task_directory, tasks_filename)).feature_tasks_instantwise;
    % numel(tasks_instantwise)

    dist_mat_square = squareform(dist_mat);

    [~, sorted_idx] = sort(-reshape(squareform(dist_mat), numel(tasks_instantwise) * numel(tasks_instantwise), 1)); % negative to go descending
    [sorted_i, sorted_j] = ind2sub([numel(tasks_instantwise), numel(tasks_instantwise)], sorted_idx);
    num_pairs = 5000;
    top_dist_table = table( ...
        tasks_instantwise(sorted_i(2:2:2*num_pairs)), ...
        tasks_instantwise(sorted_j(2:2:2*num_pairs)), ...
        0.72*abs(sorted_i(2:2:2*num_pairs) - sorted_j(2:2:2*num_pairs)), ...
        sorted_i(2:2:2*num_pairs), ...
        sorted_j(2:2:2*num_pairs), ...
        dist_mat_square(sorted_idx(2:2:2*num_pairs)), ...
        'VariableNames', ["task 1", "task 2", "difference in time (seconds)", "TR 1", "TR 2", "pdist"]);

    isSame = find(strcmp(top_dist_table.("task 1"), top_dist_table.("task 2")) == 1);


    isRest = find(and(strcmp(top_dist_table.("task 1"), "REST") == 1, strcmp(top_dist_table.("task 2"), "REST") == 1));


    for i = height(top_dist_table):-1:1
        top_dist_table{i, "TR 1 within task"} = top_dist_table{i, "TR 1"} - find(strcmp(tasks_instantwise, top_dist_table{i, "task 1"}), 1) + 1;
        top_dist_table{i, "TR 2 within task"} = top_dist_table{i, "TR 2"} - find(strcmp(tasks_instantwise, top_dist_table{i, "task 2"}), 1) + 1;
    end

    top_dist_table([1, isSame(1), isRest(1)], :)
    top_dist_across_subjects_table{2*subject_idx - 1, "Subject"} = subject;
    top_dist_across_subjects_table(2*subject_idx - 1, ["task 1", "task 2", "TR 1 within task", "TR 2 within task", "TR 1 in concatenated tasks", "TR 2 in concatenated tasks", "pdist"]) = ...
        top_dist_table(1, ["task 1", "task 2", "TR 1 within task", "TR 2 within task", "TR 1", "TR 2", "pdist"]);
    top_dist_across_subjects_table{2*subject_idx - 1, "is maximum across tasks"} = 1;
    top_dist_across_subjects_table{2*subject_idx, "Subject"} = subject;
    top_dist_across_subjects_table(2*subject_idx, ["task 1", "task 2", "TR 1 within task", "TR 2 within task", "TR 1 in concatenated tasks", "TR 2 in concatenated tasks", "pdist"]) = ...
        top_dist_table(isRest(1), ["task 1", "task 2", "TR 1 within task", "TR 2 within task", "TR 1", "TR 2", "pdist"]);
    top_dist_across_subjects_table{2*subject_idx, "is maximum across tasks"} = 0;

end

filename = fullfile(output_directory, sprintf("top_pdist_%s_%s.csv", session, parcellation));
writetable(top_dist_across_subjects_table, filename)