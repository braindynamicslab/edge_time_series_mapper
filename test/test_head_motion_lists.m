for session = ["LR", "RL"]
    
    fprintf('\n========================================\n');
    fprintf('Comparing Head Motion: Session %s\n', session);
    fprintf('========================================\n\n');
    
    % Define filenames
    cohort_filename = sprintf("/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/data_cohort/cohort_all_session_%s.csv", session);
    old_filename = sprintf("/Users/siuc/Documents/GitHub/brain_HOI/data_output_lightweight/expt_250829_meanHeadMotion_cohort_all_%s.txt", session);
    new_filename = sprintf("/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline_gitignore/mean_head_motion/mean_head_motion_cohort_all_session_%s.csv", session);
    
    % Load cohort list (defines which subjects to keep)
    cohort_table = readtable(cohort_filename, "TextType", "string", ...
                             "VariableNamingRule", "preserve");
    cohort_table.Properties.VariableNames = {'subject'};  % Rename for consistency
    
    % Load old head motion data
    old_table = readtable(old_filename, "TextType", "string", ...
                          "VariableNamingRule", "preserve");
    old_table.Properties.VariableNames = {'subject', 'old_head_motion'};
    
    % Load new head motion data
    new_table = readtable(new_filename, "TextType", "string", ...
                          "VariableNamingRule", "preserve");
    new_table.Properties.VariableNames = {'subject', 'new_head_motion'};
    
    % Merge tables using left join (keep all cohort subjects)
    merged_table = outerjoin(cohort_table, old_table, ...
                             'Keys', 'subject', 'MergeKeys', true, 'Type', 'left');
    merged_table = outerjoin(merged_table, new_table, ...
                             'Keys', 'subject', 'MergeKeys', true, 'Type', 'left');
    
    % Reorder columns
    merged_table = merged_table(:, {'subject', 'old_head_motion', 'new_head_motion'});
    
    % Compute correlation (excluding NaN values)
    valid_idx = ~isnan(merged_table.old_head_motion) & ~isnan(merged_table.new_head_motion);
    correlation = corr(merged_table.old_head_motion(valid_idx), ...
                       merged_table.new_head_motion(valid_idx));
    
    fprintf('Number of subjects in cohort: %d\n', height(cohort_table));
    fprintf('Subjects with old data: %d\n', sum(~isnan(merged_table.old_head_motion)));
    fprintf('Subjects with new data: %d\n', sum(~isnan(merged_table.new_head_motion)));
    fprintf('Subjects with both: %d\n', sum(valid_idx));
    fprintf('Correlation (old vs new): r = %.4f\n\n', correlation);
    
    % Create scatter plot
    figure('Position', [100, 100, 600, 600]);
    
    % Plot data points
    scatter(merged_table.old_head_motion(valid_idx), ...
            merged_table.new_head_motion(valid_idx), ...
            50, 'filled', 'MarkerFaceAlpha', 0.6);
    hold on;
    
    % Plot y=x line
    all_values = [merged_table.old_head_motion(valid_idx); ...
                  merged_table.new_head_motion(valid_idx)];
    min_val = min(all_values);
    max_val = max(all_values);
    plot([min_val, max_val], [min_val, max_val], 'r--', 'LineWidth', 2);
    
    % Formatting
    xlabel('Old Head Motion (mm)', 'FontSize', 12);
    ylabel('New Head Motion (mm)', 'FontSize', 12);
    title(sprintf('Head Motion Comparison - Session %s\nr = %.4f (n = %d)', ...
                  session, correlation, sum(valid_idx)), 'FontSize', 14);
    grid on;
    axis equal;
    legend('Data', 'y = x', 'Location', 'southeast');
    
    hold off;
    
    % Save figure
    %fig_filename = sprintf('head_motion_comparison_session_%s.png', session);
    %saveas(gcf, fig_filename);
    %fprintf('✓ Figure saved: %s\n', fig_filename);
    
end

fprintf('\n========================================\n');
fprintf('Comparison complete!\n');
fprintf('========================================\n\n');