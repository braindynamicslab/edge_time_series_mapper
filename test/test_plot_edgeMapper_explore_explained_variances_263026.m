% Script to plot cumulative explained variance from saved data

cohort = "one";
session = "LR";
parcellation = "schaefer100x7";

config = fcn_utils_get_config();
data_directory = fullfile(config.scratch_dir, "cumulative_explained_variance_processed_simplex_time_series");

simplices = [...
    "node", ...
    "edge", ...
    % "triangle"...
    ];

num_brain_regions = 100;

for simplex = simplices

    if strcmp(simplex, "node")
        dim = 0;
    elseif strcmp(simplex, "edge")
        dim = 1;
    elseif strcmp(simplex, "triangle")
        dim = 2;
    end
        num_higher_features = nchoosek(num_brain_regions, dim + 1);
    % Construct filename
    filename = sprintf("cumulative_explained_variance_processed_simplex_time_series_%s_cohort_%s_session_%s_%s", ...
        simplex, cohort, session, parcellation);
    input_filepath = fullfile(data_directory, strcat(filename, ".csv"));
    
    % Check if file exists
    if ~isfile(input_filepath)
        warning("File not found: %s", input_filepath);
        continue;
    end
    
    % Load data
    data = readmatrix(input_filepath);
    
    % First column is subject IDs, rest is cumulative explained variance
    subjects = data(:, 1);
    cumulative_explained_variance = data(:, 2:end);
    
    % Plot
    fig = figure;
    plot(cumulative_explained_variance');
    title(sprintf("Cumulative Explained Variance - %s", simplex));
    xlabel("Component Number");
    ylabel("Cumulative Explained Variance");
    xlim([0, min(500, num_higher_features)]);
    grid on;
    
    % Optional: Add a horizontal line at 0.8 (target explained variance)
    hold on;
    yline([80, 90, 95], 'r--', 'LineWidth', 1.5);
    xline([20, 40, 60, 80, 100], 'r--', 'LineWidth', 1.5);
    hold off;
    
    fprintf("Plotted data for simplex: %s\n", simplex);

    output_filepath = fullfile(data_directory, strcat(filename, ".png"));
    saveas(fig, output_filepath)

    fprintf("Saved plot for simplex %s at %s", simplex, output_filepath)
end