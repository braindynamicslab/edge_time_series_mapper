report_cohort_descriptive_statistics("all", "LR")

function report_cohort_descriptive_statistics(cohort, session)
% REPORT_COHORT_DESCRIPTIVE_STATISTICS Report N, sex, and age statistics
%
% Inputs:
%   cohort - "one" or "all"

arguments
    cohort {mustBeMember(cohort, ["one", "all"])} = "all"
    session {mustBeMember(session, ["LR", "RL"])} = "LR"
end

config = fcn_utils_get_config();

% Load the subject list and merge with unrestricted/restricted data
unrestricted_csv = config.hcp_unrestricted_data_path;
restricted_csv = config.hcp_restricted_data_path;

% Get subjects from specified cohort
subject_csv = fullfile(config.repo_root, "data_pipeline", "data_cohort", ...
    sprintf("cohort_%s_session_%s.csv", cohort, session));

% Load subject list
grand_table = readtable(subject_csv, "FileType", "text");
grand_table.Properties.VariableNames = strrep(...
    grand_table.Properties.VariableNames, "Subject", "subject");

% Load unrestricted data (contains Gender)
unrestricted_table = readtable(unrestricted_csv);
unrestricted_table.Properties.VariableNames = strrep(...
    unrestricted_table.Properties.VariableNames, "Subject", "subject");
grand_table = outerjoin(grand_table, unrestricted_table(:, ["subject", "Gender"]), ...
    'Keys', 'subject', 'Type', 'left', 'MergeKeys', true);

% Load restricted data (contains Age_in_Yrs)
restricted_table = readtable(restricted_csv);
restricted_table.Properties.VariableNames = strrep(...
    restricted_table.Properties.VariableNames, "Subject", "subject");
grand_table = outerjoin(grand_table, restricted_table(:, ["subject", "Age_in_Yrs"]), ...
    'Keys', 'subject', 'Type', 'left', 'MergeKeys', true);

% Get unique subjects (in case cohort has multiple rows per subject)
[unique_subjects, unique_idx] = unique(grand_table.subject);
unique_data = grand_table(unique_idx, :);

% Compute statistics
n_total = height(unique_data);
n_female = sum(strcmp(unique_data.Gender, "F"));
mean_age = mean(unique_data.Age_in_Yrs, 'omitnan');
sd_age = std(unique_data.Age_in_Yrs, 'omitnan');

% Report
fprintf('\nCohort "%s" Descriptive Statistics:\n', cohort);
fprintf('N = %d\n', n_total);
fprintf('N_female = %d (%.1f%%)\n', n_female, 100*n_female/n_total);
fprintf('Age: M = %.2f, SD = %.2f\n', mean_age, sd_age);

end