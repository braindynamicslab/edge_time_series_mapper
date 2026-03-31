function test_io_generate_cohort_subject_lists()

% Verify set relationships: all_but_one_two ∪ two = all_but_one
% For each session choice (LR, RL, both)

%% Setup
config = fcn_utils_get_config();
data_dir = fullfile(config.repo_root, "data_pipeline", "data_cohort");

sessions = ["LR", "RL", "both"];

fprintf('Verifying: all_but_one_two ∪ cohort_two = all_but_one\n\n');

%% Check each session
all_verified = true;

for session = sessions
    % Load subject lists
    all_but_one_two_file = fullfile(data_dir, ...
        sprintf("cohort_all_but_one_two_session_%s.csv", session));
    cohort_two_file = fullfile(data_dir, ...
        sprintf("cohort_two_session_%s.csv", session));
    all_but_one_file = fullfile(data_dir, ...
        sprintf("cohort_all_but_one_session_%s.csv", session));
    
    all_but_one_two_table = readtable(all_but_one_two_file, ...
        "VariableNamingRule", "preserve");
    cohort_two_table = readtable(cohort_two_file, ...
        "VariableNamingRule", "preserve");
    all_but_one_table = readtable(all_but_one_file, ...
        "VariableNamingRule", "preserve");
    
    all_but_one_two_subjects = all_but_one_two_table.Subject;
    cohort_two_subjects = cohort_two_table.Subject;
    all_but_one_subjects = all_but_one_table.Subject;
    
    % Compute union
    union_subjects = unique([all_but_one_two_subjects; cohort_two_subjects]);
    
    % Check if union equals all_but_one
    is_equal = isequal(sort(union_subjects), sort(all_but_one_subjects));
    
    % Report results
    if is_equal
        fprintf('✓ Session %s: VERIFIED\n', session);
        fprintf('  all_but_one_two: %d subjects\n', numel(all_but_one_two_subjects));
        fprintf('  cohort_two: %d subjects\n', numel(cohort_two_subjects));
        fprintf('  union: %d subjects\n', numel(union_subjects));
        fprintf('  all_but_one: %d subjects\n', numel(all_but_one_subjects));
    else
        fprintf('✗ Session %s: FAILED\n', session);
        fprintf('  Union has %d subjects, all_but_one has %d subjects\n', ...
            numel(union_subjects), numel(all_but_one_subjects));
        
        % Find discrepancies
        only_in_union = setdiff(union_subjects, all_but_one_subjects);
        only_in_all_but_one = setdiff(all_but_one_subjects, union_subjects);
        
        if ~isempty(only_in_union)
            fprintf('  Subjects in union but not all_but_one: %d\n', ...
                numel(only_in_union));
        end
        if ~isempty(only_in_all_but_one)
            fprintf('  Subjects in all_but_one but not union: %d\n', ...
                numel(only_in_all_but_one));
        end
        
        all_verified = false;
    end
    fprintf('\n');
end

%% Final summary
if all_verified
    fprintf('All session checks passed! ✓\n');
else
    fprintf('Some session checks failed! ✗\n');
end

end