function stats = fcn_test_compare_vectors(vec1, vec2, varargin)
% COMPARE_VECTORS Compare two vectors with error metrics and optional plotting
%
% Syntax:
%   stats = compare_vectors(vec1, vec2)
%   stats = compare_vectors(vec1, vec2, 'extra_flag', true)
%   stats = compare_vectors(vec1, vec2, 'plot_flag', true)
%   stats = compare_vectors(vec1, vec2, 'extra_flag', true, 'plot_flag', true)
%
% Inputs:
%   vec1        - First vector (reference/old data)
%   vec2        - Second vector (new data to compare)
%   extra_flag  - Compute additional metrics (default: false)
%   plot_flag   - Generate comparison plots (default: false)
%
% Outputs:
%   stats       - Structure containing comparison metrics
%
% Example:
%   stats = compare_vectors(data_old.amplitude, data_new.amplitude_nodewise, ...
%                          'extra_flag', true, 'plot_flag', true);

%% Parse input arguments
p = inputParser;
addRequired(p, 'vec1');
addRequired(p, 'vec2');
addParameter(p, 'extra_flag', false, @islogical);
addParameter(p, 'plot_flag', false, @islogical);
addParameter(p, 'vec1_name', 'Vector 1', @ischar);
addParameter(p, 'vec2_name', 'Vector 2', @ischar);

parse(p, vec1, vec2, varargin{:});

extra_flag = p.Results.extra_flag;
plot_flag = p.Results.plot_flag;
vec1_name = p.Results.vec1_name;
vec2_name = p.Results.vec2_name;

%% Prepare vectors
vec1 = vec1(:);
vec2 = vec2(:);

% Check length compatibility
if length(vec1) ~= length(vec2)
    warning('Vectors have different lengths: %d vs %d', length(vec1), length(vec2));
    min_len = min(length(vec1), length(vec2));
    vec1 = vec1(1:min_len);
    vec2 = vec2(1:min_len);
end

%% Basic Metrics (always computed)
stats.length = length(vec1);

% Maximum Absolute Error
stats.max_error = max(abs(vec2 - vec1));

% Relative Maximum Error
denominator = max(abs(vec1));
if denominator == 0
    stats.rel_max_error = NaN;
else
    stats.rel_max_error = stats.max_error / denominator;
end

% Element-wise Relative Error
rel_errors = abs(vec2 - vec1) ./ (abs(vec1) + eps);
stats.max_rel_error_elementwise = max(rel_errors);

% Correlation Coefficient
if std(vec1) > 0 && std(vec2) > 0
    stats.correlation = corr(vec1, vec2);
    stats.r_squared = stats.correlation^2;
else
    stats.correlation = NaN;
    stats.r_squared = NaN;
end

%% Extra Metrics (computed if extra_flag is true)
if extra_flag
    % Mean Absolute Error
    stats.mae = mean(abs(vec2 - vec1));

    % Root Mean Square Error
    stats.rmse = sqrt(mean((vec2 - vec1).^2));

    % Normalized RMSE
    range_val = max(vec1) - min(vec1);
    if range_val > 0
        stats.nrmse = stats.rmse / range_val;
    else
        stats.nrmse = NaN;
    end

    % Mean Error (bias)
    stats.mean_error = mean(vec2 - vec1);

    % Standard deviation of error
    stats.std_error = std(vec2 - vec1);

    % Median Absolute Error
    stats.median_error = median(abs(vec2 - vec1));

    % Percentile errors
    stats.error_90th_percentile = prctile(abs(vec2 - vec1), 90);
    stats.error_95th_percentile = prctile(abs(vec2 - vec1), 95);
    stats.error_99th_percentile = prctile(abs(vec2 - vec1), 99);

    % Mean Absolute Percentage Error (MAPE)
    nonzero_idx = abs(vec1) > eps;
    if any(nonzero_idx)
        stats.mape = mean(abs((vec2(nonzero_idx) - vec1(nonzero_idx)) ./ vec1(nonzero_idx))) * 100;
    else
        stats.mape = NaN;
    end
end

%% Display Results
fprintf('\n========== VECTOR COMPARISON SUMMARY ==========\n');
fprintf('Vector Length: %d\n', stats.length);
fprintf('\n--- Basic Metrics ---\n');
fprintf('Max Absolute Error: %.6e\n', stats.max_error);
fprintf('Relative Max Error: %.4f%%\n', stats.rel_max_error*100);
fprintf('Max Element-wise Rel Error: %.4f%%\n', stats.max_rel_error_elementwise*100);
fprintf('Correlation Coefficient: %.6f\n', stats.correlation);
fprintf('R-squared: %.6f\n', stats.r_squared);

if extra_flag
    fprintf('\n--- Extra Metrics ---\n');
    fprintf('Mean Absolute Error: %.6e\n', stats.mae);
    fprintf('Root Mean Square Error: %.6e\n', stats.rmse);
    fprintf('Normalized RMSE: %.4f%%\n', stats.nrmse*100);
    fprintf('Mean Error (Bias): %.6e\n', stats.mean_error);
    fprintf('Std Dev of Error: %.6e\n', stats.std_error);
    fprintf('Median Absolute Error: %.6e\n', stats.median_error);
    fprintf('MAPE: %.4f%%\n', stats.mape);
    fprintf('90th Percentile Error: %.6e\n', stats.error_90th_percentile);
    fprintf('95th Percentile Error: %.6e\n', stats.error_95th_percentile);
    fprintf('99th Percentile Error: %.6e\n', stats.error_99th_percentile);
end

fprintf('===============================================\n\n');

%% Plotting (if plot_flag is true)
if plot_flag
    errors = vec2 - vec1;

    figure('Name', 'Vector Comparison', 'Position', [100, 100, 1400, 900]);

    % Subplot 1: Scatter plot
    subplot(2,3,1);
    scatter(vec1, vec2, 20, 'filled', 'MarkerFaceAlpha', 0.5);
    hold on;
    min_val = min([vec1; vec2]);
    max_val = max([vec1; vec2]);
    plot([min_val, max_val], [min_val, max_val], 'r--', 'LineWidth', 2);
    xlabel(vec1_name);
    ylabel(vec2_name);
    title(sprintf('Scatter Plot\nR=%.4f, R²=%.4f', stats.correlation, stats.r_squared));
    grid on;
    axis equal tight;

    % Subplot 2: Error distribution
    subplot(2,3,2);
    histogram(errors, 50, 'Normalization', 'probability', 'FaceColor', [0.3 0.6 0.9]);
    xlabel('Error (Vec2 - Vec1)');
    ylabel('Probability');
    title(sprintf('Error Distribution\nMean=%.2e, Std=%.2e', mean(errors), std(errors)));
    grid on;

    % Subplot 3: Index-wise comparison
    subplot(2,3,3);
    plot(vec1, 'b.-', 'DisplayName', vec1_name, 'LineWidth', 1.5);
    hold on;
    plot(vec2, 'r.-', 'DisplayName', vec2_name, 'LineWidth', 1.5);
    xlabel('Index');
    ylabel('Value');
    title('Index-wise Comparison');
    legend('Location', 'best');
    grid on;

    % Subplot 4: Absolute error vs index
    subplot(2,3,4);
    plot(abs(errors), 'k.-', 'LineWidth', 1);
    hold on;
    yline(stats.max_error, 'r--', 'LineWidth', 2, 'DisplayName', 'Max Error');
    if extra_flag
        yline(stats.mae, 'g--', 'LineWidth', 2, 'DisplayName', 'Mean Error');
    end
    xlabel('Index');
    ylabel('Absolute Error');
    title('Absolute Error vs Index');
    legend('Location', 'best');
    grid on;

    % Subplot 5: Bland-Altman plot
    subplot(2,3,5);
    mean_vals = (vec1 + vec2) / 2;
    scatter(mean_vals, errors, 20, 'filled', 'MarkerFaceAlpha', 0.5);
    hold on;
    yline(mean(errors), 'r-', 'LineWidth', 2, 'DisplayName', 'Mean');
    yline(mean(errors) + 1.96*std(errors), 'r--', 'LineWidth', 1.5, 'DisplayName', '±1.96 SD');
    yline(mean(errors) - 1.96*std(errors), 'r--', 'LineWidth', 1.5);
    xlabel('Mean of Two Vectors');
    ylabel('Difference (Vec2 - Vec1)');
    title('Bland-Altman Plot');
    legend('Location', 'best');
    grid on;

    % Subplot 6: Q-Q plot
    subplot(2,3,6);
    qqplot(vec1, vec2);
    title('Q-Q Plot');
    xlabel([vec1_name ' Quantiles']);
    ylabel([vec2_name ' Quantiles']);
    grid on;

    % Add overall title
    sgtitle(sprintf('Vector Comparison: Max Err=%.2e, Rel Err=%.2f%%, Corr=%.4f', ...
        stats.max_error, stats.rel_max_error*100, stats.correlation), ...
        'FontSize', 12, 'FontWeight', 'bold');
end

end