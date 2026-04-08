function [stats, data_table] = fcn_brainBehavior_lme_modularity_predicts_behavior(feature_processing, cohort, session, parcellation, modularity_prefix, response_variable, control_variables_fixed, control_variables_random, config, verbose_flag)

unrestricted_csv = config.hcp_unrestricted_data_path;
restricted_csv = config.hcp_restricted_data_path;

unrestricted_features = [...
    "Gender", ...
    "NEOFAC_A", ...
    "NEOFAC_O", ...
    "NEOFAC_C", ...
    "NEOFAC_N", ...
    "NEOFAC_E", ...
    "PMAT24_A_CR"
    ];
restricted_features = [...
    "Age_in_Yrs", ...
    "Family_ID", ...
    "ASR_Intn_T", ...
    "ASR_Extn_T", ...
    ];
head_motion_features = [sprintf("%s_mean_head_motion", session)];
simplex_modularity_features = [
    sprintf("%s_node_modularity", session), ...
    sprintf("%s_edge_modularity", session), ...
    sprintf("%s_triangle_modularity", session)
    ];

features_to_zscore = [...
    sprintf("%s_node_modularity", session), ...
    sprintf("%s_edge_modularity", session), ...
    sprintf("%s_triangle_modularity", session), ...
    "NEOFAC_A", ...
    "NEOFAC_O", ...
    "NEOFAC_C", ...
    "NEOFAC_N", ...
    "NEOFAC_E", ...
    "Age_in_Yrs", ...
    "ASR_Intn_T", ...
    "ASR_Extn_T", ...
    "PMAT24_A_CR"
    ];


subject_csv = fullfile(config.repo_root, "data_pipeline", "data_cohort", ...
sprintf("cohort_%s_session_%s.csv", cohort, session));

head_motion_csv = fullfile(config.repo_root, "data_pipeline_gitignore", "mean_head_motion", ...
    sprintf("mean_head_motion_cohort_all_session_both.csv"));
modularity_csv = fullfile(config.repo_root, "data_pipeline", "simplex_mappers", ...
    sprintf("simplex_mapper_%s_cohort_%s_session_%s_%s.csv", feature_processing, cohort, "both", parcellation));

csv_table = table();
csv_table.csv = [unrestricted_csv; restricted_csv; head_motion_csv; modularity_csv];
csv_table.features = {unrestricted_features; restricted_features; head_motion_features; simplex_modularity_features};

grand_table = readtable(subject_csv, "FileType", "text");
grand_table.Properties.VariableNames = strrep(...
    grand_table.Properties.VariableNames, "Subject", "subject");

for csv_idx = 1:height(csv_table)
    new_table = readtable(csv_table.csv(csv_idx));
    new_table.Properties.VariableNames = strrep(new_table.Properties.VariableNames, ...
        "Subject", "subject");
    new_table = new_table(:, ["subject", csv_table.features{csv_idx}]);
    grand_table = outerjoin(grand_table, new_table, 'Keys', 'subject', 'Type','left', 'MergeKeys', true);
end


%% process features

grand_table.is_female = strcmp(grand_table.Gender, "F");
grand_table(:, features_to_zscore) = normalize(grand_table(:, features_to_zscore));

%% test

predictor = strjoin([session, modularity_prefix, "modularity"], "_");
control_variables_fixed = strrep(control_variables_fixed, "MeanHeadMotion", sprintf("%s_mean_head_motion", session));
% if a control variable is a nested random effect a:b, e.g.
% school:school_class
% strip a from a:b to recover the relevant column name b in the table
control_variables_random_without_nesting = fcn_brainBehavior_drop_parent_variable(control_variables_random);

% formula = "%s ~ mod + Age_in_Yrs + IsFemale + (1 | Family_ID)";
formula = strcat(response_variable, " ~ ", strjoin([predictor, control_variables_fixed, "(1 | " + control_variables_random + ")"], " + "));        

if verbose_flag
    fprintf(formula); fprintf("\n");
end
data_table = grand_table(:, [response_variable, predictor, control_variables_fixed, control_variables_random_without_nesting]);
lme = fitlme(grand_table(:, [response_variable, predictor, control_variables_fixed, control_variables_random_without_nesting]), formula, 'verbose', verbose_flag);
[~, ~, stats] = fixedEffects(lme);

% % Extract statistics for the predictor
% predictor_idx = find(strcmp(stats.Name, predictor));
% 
% if isempty(predictor_idx)
%     error('Predictor %s not found in model coefficients', predictor);
% end
% 
% % Create results table
% results_table = table();
% results_table.coefficient = stats.Estimate(predictor_idx);
% results_table.standard_error = stats.SE(predictor_idx);
% results_table.t_statistic = stats.tStat(predictor_idx);
% results_table.degree_of_freedom = stats.DF(predictor_idx);
% results_table.p_value = stats.pValue(predictor_idx);
% 
% if verbose_flag
%     fprintf('\nPredictor Statistics:\n');
%     disp(results_table);
% end

end