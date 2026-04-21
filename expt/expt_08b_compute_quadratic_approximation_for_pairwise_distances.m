config = fcn_utils_get_config();
session = "LR";
parcellation = "schaefer100x7";
input_directory = fullfile(config.scratch_dir, "data_pipeline", "pairwise_distances");
output_directory = fullfile(config.repo_root, "data_pipeline", "pairwise_distances");

if ~isfolder(output_directory)
    mkdir(output_directory);
end

upperbound = @(x) 1.1 * (1 - 0.5*(1 - x).^2  - 0.5*(1 - x).^4);
lowerbound = @(x) 1 - 0.5*(1 - x).^2  - 0.5*abs(1 - x);
estimate = @(x) 1 - (1 - x).^2;

for cohort = ["two"]%["one", "two"]
    sublist_csv = fullfile(config.repo_root, "data_pipeline", "data_cohort", sprintf("cohort_%s_session_%s.csv", cohort, session));
    subjects = readtable(sublist_csv).Subject;

    upper_bound_violation = nan(numel(subjects), 1);
    lower_bound_violation = nan(numel(subjects), 1);
    coefficients = nan(numel(subjects), 3);
    Rsquared = nan(numel(subjects), 1);
    Rsquared_hypothesis = nan(numel(subjects), 1);

    for subject_idx = 1:numel(subjects)
        subject = subjects(subject_idx);
        if mod(subject_idx, 10) == 0
            fprintf("%d\n", subject_idx);
        end
        filename_edge = fullfile(input_directory, sprintf("framewise_pairwise_distances_%s_%d_%s_%s.mat", "edge", subject, session, parcellation));
        dist_mat_edge = matfile(filename_edge).dist_mat;

        filename_node = fullfile(input_directory, sprintf("framewise_pairwise_distances_%s_%d_%s_%s.mat", "node", subject, session, parcellation));
        dist_mat_node = matfile(filename_node).dist_mat;

        upper_bound_violation(subject_idx) = sum(dist_mat_edge > upperbound(dist_mat_node))/numel(dist_mat_edge);
        lower_bound_violation(subject_idx) = sum(dist_mat_edge < lowerbound(dist_mat_node))/numel(dist_mat_edge);

        lm = fitlm([dist_mat_node' - 1, (dist_mat_node' - 1).^2], dist_mat_edge);
        coefficients(subject_idx, :) = lm.Coefficients.Estimate';
        Rsquared(subject_idx) = lm.Rsquared.Ordinary;

        Rsquared_hypothesis(subject_idx) = 1 - norm(dist_mat_edge - (1 - (1 - dist_mat_node).^2))^2/std(dist_mat_edge)^2/(numel(dist_mat_edge)-1);
    end

    result_table = table(subjects(:), upper_bound_violation, lower_bound_violation, coefficients(:, 1), coefficients(:, 2), coefficients(:, 3), Rsquared, Rsquared_hypothesis, ...
        'VariableNames', ["Subject", "Upper bound violation", "Lower bound violation", "Coeff Est (constant)", "Coeff Est (linear)", "Coeff Est (quadratic)", "R squared", "R squared hypothesis"]);
    writetable(result_table, fullfile(output_directory, sprintf("quadratic_approximation_%s_%s_%s.csv", cohort, session, parcellation)));
    
    fprintf("min R^2: %.3g\n", min(Rsquared));
    fprintf("min model R^2: %.3g\n", min(Rsquared_hypothesis));
    fprintf("max upper bound violation: %.3g\n", max(upper_bound_violation));
    fprintf("max lower bound violation: %.3g\n", max(lower_bound_violation));
    fprintf("max bound violation: %.3g\n", max(lower_bound_violation + upper_bound_violation));
end