cohort = "one";
session = "LR";
parcellation = "schaefer100x7";

config = fcn_utils_get_config();
data_directory = fullfile(config.scratch_dir, "cumulative_explained_variance_processed_simplex_time_series");
input_filename = sprintf("cumulative_explained_variance_processed_simplex_time_series_%s_cohort_%s_session_%s_%s.csv", simplex, cohort, session, parcellation);
data = readmatrix(...
        fullfile(data_directory, input_filename));
subjects = data(:, 1);
pca_explained_variance_per_component = data(:, 2:end);

figure;
plot(pca_explained_variance_per_component');
xline([30, 40, 50])
yline([80, 90, 95])
title(simplex);

explaiend_variance_threshold = 90;
[~, num_features] = max(pca_explained_variance_per_component > explaiend_variance_threshold, [], 2);

figure;
histogram(num_features);
title(sprintf("Number of features to explain %d percent of variance", explaiend_variance_threshold));

fprintf('Mean: %.2f\n', mean(num_features));
fprintf('Median: %.2f\n', median(num_features));
fprintf('Lower quartile (Q1): %.2f\n', quantile(num_features, 0.25));
fprintf('Upper quartile (Q3): %.2f\n', quantile(num_features, 0.75));
