config = fcn_utils_get_config();

session = "LR";
parcellation = "schaefer100x7";
simplex = "edge";

cohort = "one";

subject = 100206;
selected_nodes = 1:812; % for edge

% subject = 125525;
% selected_nodes_old = (1:575 ~= 103); for edge

data_input_old = load(sprintf("/scratch/users/siuc/HOI_data_output/xcpenging_2025_noFeatureMassaging_%s_%s/brain_state_mapper_noFeatureMassaging_%d_%s_%s_%s_xcpengine_2025_data.mat", session, parcellation, subject, session, simplex, parcellation));
data_input_new = load(fullfile(config.scratch_dir, sprintf("simplex_mapper_raw_features_cohort_%s_%s_%s_%s/simplexMapper_%s_%d_%s_%s_data.mat", cohort, session, simplex, parcellation, simplex, subject, session, parcellation)));

data_output_old = load(sprintf("/scratch/users/siuc/HOI_data_output/high_amplitude_functional_connectivity_90/high_amplitude_functional_connectivity_noFeatureMassaging_%d_%s_%s_%s_xcpengine_2025_data.mat", subject, session, simplex, parcellation));
data_output_new = load(fullfile(config.scratch_dir, sprintf("data_pipeline/high_amplitude_functional_connectivity/high_amplitude_functional_connectivity_%d_%s_%s_%s_data.mat", subject, session, simplex, parcellation)));

task = "REST";
task_id = 1; % REST

task = "WM";
task_id = 8; % WM

FC_notion_id_old = 8;
FC_notion_id_new = 3;
fprintf(data_output_old.row_names{FC_notion_id_old});
fprintf("\n");
fprintf(data_output_new.row_names{FC_notion_id_new});
fprintf("\n");

high_amp_FC_old = data_output_old.subject_functional_connectivity_cell{task_id}(FC_notion_id_old, :);
high_amp_FC_new = data_output_new.subject_functional_connectivity_cell{task_id}(FC_notion_id_new, :);

fcn_test_compare_vectors(high_amp_FC_old, high_amp_FC_new);

% old input arguments
amplitude_measure_old = data_input_old.high_amplitude;
task_count_per_node_old = data_input_old.taskCountPerNode;
mode_task_indices_old = data_input_old.modeTaskIndices;
within_task_timeframes_old = strcmp(data_input_old.tasks_instantwise, task);
purity_threshold_old = 0.75;

% new input arguments
amplitude_measure = data_input_new.amplitude_peak_density_peak_threshold_95;
task_count_per_node = data_input_new.mapper_stat_task_count_per_node;
mode_task_indices = data_input_new.mapper_stat_mode_task_indices;
within_task_timeframes = strcmp(data_input_new.feature_tasks_instantwise, task);
purity_threshold = 0.75;

fcn_test_compare_vectors(amplitude_measure_old, amplitude_measure);
fcn_test_compare_vectors(task_count_per_node_old, task_count_per_node);
fcn_test_compare_vectors(mode_task_indices_old, mode_task_indices);
fcn_test_compare_vectors(within_task_timeframes_old, within_task_timeframes);
