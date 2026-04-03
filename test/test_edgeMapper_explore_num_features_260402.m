cohort = "one";
session = "LR";
parcellation = "schaefer100x7";
simplex = "node";

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

mean_val = mean(num_features);
median_val = median(num_features);
q1 = quantile(num_features, 0.25);
q3 = quantile(num_features, 0.75);

figure;
hold on;

% Plot histogram
h = histogram(num_features);

% Shade interquartile region
y_lim = ylim;
patch([q1 q3 q3 q1], [0 0 y_lim(2) y_lim(2)], 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

% Add vertical lines
xline(mean_val, ':', 'LineWidth', 2, 'Color', 'b');
xline(median_val, '-', 'LineWidth', 2, 'Color', 'k');

% Add legend
legend('', 'Interquartile region', 'Mean', 'Median', 'Location', 'best');

title(sprintf("Number of features to explain %d percent of variance", explaiend_variance_threshold));
hold off;

fprintf('Mean: %.2f\n', mean_val);
fprintf('Median: %.2f\n', median_val);
fprintf('Lower quartile (Q1): %.2f\n', q1);
fprintf('Upper quartile (Q3): %.2f\n', q3);
