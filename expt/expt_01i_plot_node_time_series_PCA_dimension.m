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
%xline(median_val, '-', 'LineWidth', 2, 'Color', 'k');

% Add legend
%legend('', 'Interquartile region', 'Mean', 'Median', 'Location', 'best');
legend('', sprintf('Interquartile\nregion'), 'Mean', 'Location', 'northeast');
set(gca, 'FontSize', 8);  % Axis tick labels
title({sprintf("Number of features to explain %d percent of variance", explaiend_variance_threshold), ""});

% Set figure size
fig = gcf;
fig.Units = 'centimeters';
fig.Position = [1, 1, 8, 5]; % [x, y, width, height]

% Set resolution
fig.PaperPositionMode = 'auto';
fig_pos = fig.PaperPosition;
fig.PaperSize = [fig_pos(3) fig_pos(4)];

% Define output paths
repo_root = config.repo_root; % Assuming this is available in config
output_dir = fullfile(repo_root, 'fig_polished');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
output_base = fullfile(output_dir, 'fig_S2_PCA_components');

% Save as PNG with 300 DPI
exportgraphics(fig, [output_base '.png'], 'Resolution', 300);
% Save as PDF
exportgraphics(fig, [output_base '.pdf'], 'ContentType', 'vector');

fprintf('Figures saved to:\n');
fprintf('  %s.png\n', output_base);
fprintf('  %s.pdf\n', output_base);

hold off;



fprintf('Mean: %.2f\n', mean_val);
fprintf('Median: %.2f\n', median_val);
fprintf('Lower quartile (Q1): %.2f\n', q1);
fprintf('Upper quartile (Q3): %.2f\n', q3);