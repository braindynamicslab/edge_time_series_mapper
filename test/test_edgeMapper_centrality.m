% Parameters
subject = 100206;
cohort = "one";
session = "LR";
parcellation = "schaefer100x7";
simplex = "edge";

% Old file
old_directory = sprintf("/scratch/users/siuc/HOI_data_output/xcpenging_2025_noFeatureMassaging_%s_%s", ...
    session, parcellation);
old_filename = sprintf("brain_state_mapper_noFeatureMassaging_%d_%s_%s_%s_xcpengine_2025_data.mat", ...
    subject, session, simplex, parcellation);
old_file = matfile(fullfile(old_directory, old_filename));

% New file
new_directory = sprintf("/scratch/users/siuc/edge_time_series_mapper/simplex_mapper_raw_features_cohort_%s_%s_%s_%s", ...
    cohort, session, simplex, parcellation);
new_filename = sprintf("simplexMapper_%s_%d_%s_%s_data.mat", ...
    simplex, subject, session, parcellation);
new_file = matfile(fullfile(new_directory, new_filename));

% Inspect fields
fprintf('Old file fields:\n');
disp(who(old_file));

fprintf('\nNew file fields:\n');
disp(who(new_file));

old_centrality = old_file.task_specific_closeness_centrality;
new_centrality = new_file.mapper_stat_within_task_centrallity;
fprintf('Old centrality length: %d\n', length(old_centrality));
fprintf('New centrality length: %d\n', length(new_centrality));

figure;
scatter(old_centrality, new_centrality);
fprintf('correlation: %.3g\n', corr(old_centrality(:), new_centrality(:)))