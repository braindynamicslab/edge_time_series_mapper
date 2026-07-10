function expt_05a_combine_simplex_tables_session_both()
% Combine simplex mapper tables across simplexes and sessions
%
% For each combination of cohort and parcellation, combines node, edge,
% and triangle tables across LR and RL sessions into a single wide-format
% output table with columns like LR_node_modularity, RL_edge_modularity, etc.
%
% After processing individual cohorts, combines "one" and "all_but_one"
% to create the "all" cohort tables.
%
% Output directory: <repo_root>/data_pipeline/simplex_mappers/
% Output format: simplex_mapper_raw_features_cohort_<cohort>_session_both_<parcellation>.csv

fprintf('\n');
fprintf('================================================================================\n');
fprintf('COMBINING SIMPLEX MAPPER TABLES (SESSION BOTH)\n');
fprintf('================================================================================\n\n');

% Get configuration
config = fcn_utils_get_config();

% Define output directory
output_directory = fullfile(config.repo_root, 'data_pipeline', 'simplex_mappers');

% Create output directory if it doesn't exist
if ~exist(output_directory, 'dir')
    fprintf('Creating output directory: %s\n\n', output_directory);
    mkdir(output_directory);
end

% Define condition (only raw_features)
condition = "raw_features";

% Define cohorts to process individually
% - "one": First cohort
% - "all_but_one": Second cohort
% These will be processed separately, then "one" + "all_but_one" will be
% concatenated to create the combined "all" cohort
cohorts = ["one", "all_but_one"];

% Define sessions, simplexes, parcellations
sessions = ["LR", "RL"];
simplexes = ["node", "edge", "triangle"];
parcellations = ["schaefer100x7", "schaefer200x7"];

% Track statistics
num_total = 0;
num_created = 0;
num_skipped = 0;
num_errors = 0;

% Loop through cohorts and parcellations
for cohort_idx = 1:numel(cohorts)
    cohort = cohorts(cohort_idx);

    for parcellation_idx = 1:numel(parcellations)
        parcellation = parcellations(parcellation_idx);

        num_total = num_total + 1;

        fprintf('Processing [%d]: condition=%s, cohort=%s, parcellation=%s\n', ...
            num_total, condition, cohort, parcellation);

        % Get subject table for session_both
        subject_table_path = fullfile(config.repo_root, 'data_pipeline', 'data_cohort', ...
            strcat('cohort_', cohort, '_session_both.csv'));

        if ~isfile(subject_table_path)
            fprintf('  Subject table not found: %s\n', subject_table_path);
            fprintf('  Status: SKIPPED ✗\n\n');
            num_skipped = num_skipped + 1;
            continue;
        end

        % Read subject table
        subject_table = readtable(subject_table_path, ...
            'TextType', 'string', ...
            'VariableNamingRule', 'preserve');

        % Normalize column name from 'Subject' to 'subject'
        if ismember('Subject', subject_table.Properties.VariableNames)
            subject_table.Properties.VariableNames{'Subject'} = 'subject';
        end

        if ~ismember('subject', subject_table.Properties.VariableNames)
            fprintf('  Subject table missing "subject" or "Subject" column\n');
            fprintf('  Status: ERROR ✗\n\n');
            num_errors = num_errors + 1;
            continue;
        end

        num_subjects = height(subject_table);
        fprintf('  Found %d subjects in cohort table\n', num_subjects);

        % Join simplex tables across all sessions
        try
            combined_table = fcn_join_session_simplex_tables(subject_table, ...
                cohort, ...
                condition, ...
                sessions, ...
                simplexes, ...
                parcellation, ...
                config);

        catch ME
            fprintf('  Error processing simplex tables: %s\n', ME.message);
            fprintf('  Status: ERROR ✗\n\n');
            num_errors = num_errors + 1;
            continue;
        end

        % Define output filename
        output_filename = strcat('simplex_mapper_', condition, ...
            '_cohort_', cohort, ...
            '_session_both', ...
            '_', parcellation, '.csv');
        output_path = fullfile(output_directory, output_filename);

        % Write output
        try
            writetable(combined_table, output_path);

            fprintf('  Output written: %s\n', output_filename);
            fprintf('  Output rows: %d, columns: %d\n', height(combined_table), width(combined_table));
            fprintf('  Status: SUCCESS ✓\n\n');
            num_created = num_created + 1;

        catch ME
            fprintf('  Error writing output: %s\n', ME.message);
            fprintf('  Status: ERROR ✗\n\n');
            num_errors = num_errors + 1;
        end
    end
end

% Combine "one" and "all_but_one" to create "all" cohort
fprintf('================================================================================\n');
fprintf('COMBINING COHORTS TO CREATE "ALL"\n');
fprintf('================================================================================\n\n');

num_combined = 0;
num_combined_errors = 0;

for parcellation_idx = 1:numel(parcellations)
    parcellation = parcellations(parcellation_idx);

    fprintf('Creating all cohort for parcellation: %s\n', parcellation);

    % Define input filenames
    one_filename = strcat('simplex_mapper_', condition, ...
        '_cohort_one', ...
        '_session_both', ...
        '_', parcellation, '.csv');
    all_but_one_filename = strcat('simplex_mapper_', condition, ...
        '_cohort_all_but_one', ...
        '_session_both', ...
        '_', parcellation, '.csv');

    one_path = fullfile(output_directory, one_filename);
    all_but_one_path = fullfile(output_directory, all_but_one_filename);

    % Check if both input files exist
    if ~isfile(one_path)
        fprintf('  Input file not found: %s\n', one_filename);
        fprintf('  Status: ERROR ✗\n\n');
        num_combined_errors = num_combined_errors + 1;
        continue;
    end

    if ~isfile(all_but_one_path)
        fprintf('  Input file not found: %s\n', all_but_one_filename);
        fprintf('  Status: ERROR ✗\n\n');
        num_combined_errors = num_combined_errors + 1;
        continue;
    end

    try
        % Read both tables
        one_table = readtable(one_path, ...
            'TextType', 'string', ...
            'VariableNamingRule', 'preserve');
        all_but_one_table = readtable(all_but_one_path, ...
            'TextType', 'string', ...
            'VariableNamingRule', 'preserve');

        fprintf('  Loaded one: %d rows\n', height(one_table));
        fprintf('  Loaded all_but_one: %d rows\n', height(all_but_one_table));

        % Vertically concatenate
        all_table = [one_table; all_but_one_table];

        fprintf('  Combined: %d rows\n', height(all_table));

        % Define output filename
        all_filename = strcat('simplex_mapper_', condition, ...
            '_cohort_all', ...
            '_session_both', ...
            '_', parcellation, '.csv');
        all_path = fullfile(output_directory, all_filename);

        % Write output
        writetable(all_table, all_path);

        fprintf('  Output written: %s\n', all_filename);
        fprintf('  Status: SUCCESS ✓\n\n');
        num_combined = num_combined + 1;

    catch ME
        fprintf('  Error combining tables: %s\n', ME.message);
        fprintf('  Status: ERROR ✗\n\n');
        num_combined_errors = num_combined_errors + 1;
    end
end

% ================================================================================
% EXTRACT COHORT TWO FROM ALL_BUT_ONE
% ================================================================================
fprintf('================================================================================\n');
fprintf('EXTRACTING COHORT TWO FROM ALL_BUT_ONE\n');
fprintf('================================================================================\n\n');

num_two_created = 0;
num_two_skipped = 0;
num_two_errors = 0;

for parcellation_idx = 1:numel(parcellations)
    parcellation = parcellations(parcellation_idx);

    fprintf('Extracting cohort_two for parcellation: %s\n', parcellation);

    % Load cohort_two subject list
    cohort_two_path = fullfile(config.repo_root, 'data_pipeline', 'data_cohort', ...
        'cohort_two_session_both.csv');

    if ~isfile(cohort_two_path)
        fprintf('  Cohort two subject file not found: %s\n', cohort_two_path);
        fprintf('  Status: SKIPPED ✗\n\n');
        num_two_skipped = num_two_skipped + 1;
        continue;
    end

    % Load all_but_one data
    all_but_one_filename = strcat('simplex_mapper_', condition, ...
        '_cohort_all_but_one', ...
        '_session_both', ...
        '_', parcellation, '.csv');
    all_but_one_path = fullfile(output_directory, all_but_one_filename);

    if ~isfile(all_but_one_path)
        fprintf('  All_but_one file not found: %s\n', all_but_one_filename);
        fprintf('  Status: ERROR ✗\n\n');
        num_two_errors = num_two_errors + 1;
        continue;
    end

    try
        % Read cohort_two subject list
        cohort_two_table = readtable(cohort_two_path, ...
            'TextType', 'string', ...
            'VariableNamingRule', 'preserve');

        % Normalize column name from 'Subject' to 'subject'
        if ismember('Subject', cohort_two_table.Properties.VariableNames)
            cohort_two_table.Properties.VariableNames{'Subject'} = 'subject';
        end

        fprintf('  Loaded cohort_two subject list: %d subjects\n', height(cohort_two_table));

        % Read all_but_one data
        all_but_one_table = readtable(all_but_one_path, ...
            'TextType', 'string', ...
            'VariableNamingRule', 'preserve');

        fprintf('  Loaded all_but_one data: %d rows\n', height(all_but_one_table));

        % Extract only cohort_two subjects (preserves all_but_one row/column order)
        mask = ismember(all_but_one_table.subject, cohort_two_table.subject);
        two_table = all_but_one_table(mask, :);

        % Sanity check: warn if any cohort_two subjects were not found
        num_found = height(two_table);
        num_expected = height(cohort_two_table);
        if num_found < num_expected
            fprintf('    WARNING: %d cohort_two subjects not found in all_but_one\n', ...
                num_expected - num_found);
        end

        fprintf('  Extracted cohort_two: %d rows\n', height(two_table));

        % Define output filename
        two_filename = strcat('simplex_mapper_', condition, ...
            '_cohort_two', ...
            '_session_both', ...
            '_', parcellation, '.csv');
        two_path = fullfile(output_directory, two_filename);

        % Write output
        writetable(two_table, two_path);

        fprintf('  Output written: %s\n', two_filename);
        fprintf('  Status: SUCCESS ✓\n\n');
        num_two_created = num_two_created + 1;

    catch ME
        fprintf('  Error extracting cohort_two: %s\n', ME.message);
        fprintf('  Status: ERROR ✗\n\n');
        num_two_errors = num_two_errors + 1;
    end
end

% Compute averaged modularity across sessions for existing files
fprintf('================================================================================\n');
fprintf('COMPUTING AVERAGED MODULARITY ACROSS SESSIONS\n');
fprintf('================================================================================\n\n');

num_averaged = 0;
num_averaged_errors = 0;

% Process both individual cohorts and the combined "all" cohort
cohorts_to_average = ["one", "all_but_one", "two", "all"];

for cohort_idx = 1:numel(cohorts_to_average)
    cohort = cohorts_to_average(cohort_idx);

    for parcellation_idx = 1:numel(parcellations)
        parcellation = parcellations(parcellation_idx);

        fprintf('Adding averaged columns for cohort=%s, parcellation=%s\n', cohort, parcellation);

        % Define filename
        filename = strcat('simplex_mapper_', condition, ...
            '_cohort_', cohort, ...
            '_session_both', ...
            '_', parcellation, '.csv');
        filepath = fullfile(output_directory, filename);

        % Check if file exists
        if ~isfile(filepath)
            fprintf('  File not found: %s\n', filename);
            fprintf('  Status: SKIPPED ✗\n\n');
            continue;
        end

        try
            % Read table
            data_table = readtable(filepath, ...
                'TextType', 'string', ...
                'VariableNamingRule', 'preserve');

            fprintf('  Loaded: %d rows, %d columns\n', height(data_table), width(data_table));

            % Compute averaged modularity across sessions
            for simplex_idx = 1:numel(simplexes)
                simplex = simplexes(simplex_idx);

                % Define column names
                lr_col = strcat('LR_', simplex, '_modularity');
                rl_col = strcat('RL_', simplex, '_modularity');
                both_col = strcat('both_', simplex, '_modularity');

                % Check if LR and RL columns exist
                if ~ismember(lr_col, data_table.Properties.VariableNames)
                    fprintf('    WARNING: Column %s not found\n', lr_col);
                    continue;
                end
                if ~ismember(rl_col, data_table.Properties.VariableNames)
                    fprintf('    WARNING: Column %s not found\n', rl_col);
                    continue;
                end

                % Compute average (if either is NaN, result is NaN)
                data_table.(both_col) = mean([data_table.(lr_col), data_table.(rl_col)], 2);

                fprintf('    Created %s\n', both_col);
            end

            % Write back to same file
            writetable(data_table, filepath);

            fprintf('  Updated file: %s\n', filename);
            fprintf('  New column count: %d\n', width(data_table));
            fprintf('  Status: SUCCESS ✓\n\n');
            num_averaged = num_averaged + 1;

        catch ME
            fprintf('  Error processing file: %s\n', ME.message);
            fprintf('  Status: ERROR ✗\n\n');
            num_averaged_errors = num_averaged_errors + 1;
        end
    end
end

% Combine head motion data across sessions
    fprintf('================================================================================\n');
    fprintf('COMBINING HEAD MOTION DATA\n');
    fprintf('================================================================================\n\n');
    
    num_head_motion_success = 0;
    num_head_motion_errors = 0;
    
    fprintf('Processing head motion data for cohort=all\n');
    
    % Define paths
    cohort_path = fullfile(config.repo_root, 'data_pipeline', 'data_cohort', ...
                          'cohort_all_session_both.csv');
    lr_motion_path = fullfile(config.repo_root, 'data_pipeline_gitignore', 'mean_head_motion', ...
                             'mean_head_motion_cohort_all_session_LR.csv');
    rl_motion_path = fullfile(config.repo_root, 'data_pipeline_gitignore', 'mean_head_motion', ...
                             'mean_head_motion_cohort_all_session_RL.csv');
    
    % Check if all files exist
    if ~isfile(cohort_path)
        fprintf('  Cohort file not found: %s\n', cohort_path);
        fprintf('  Status: ERROR ✗\n\n');
        num_head_motion_errors = num_head_motion_errors + 1;
    elseif ~isfile(lr_motion_path)
        fprintf('  LR head motion file not found: %s\n', lr_motion_path);
        fprintf('  Status: ERROR ✗\n\n');
        num_head_motion_errors = num_head_motion_errors + 1;
    elseif ~isfile(rl_motion_path)
        fprintf('  RL head motion file not found: %s\n', rl_motion_path);
        fprintf('  Status: ERROR ✗\n\n');
        num_head_motion_errors = num_head_motion_errors + 1;
    else
        try
            % Read cohort table
            cohort_table = readtable(cohort_path, ...
                                    'TextType', 'string', ...
                                    'VariableNamingRule', 'preserve');
            
            % Normalize column name from 'Subject' to 'subject'
            cohort_table.Properties.VariableNames = strrep(...
                cohort_table.Properties.VariableNames, ...
                'Subject', 'subject');
            
            fprintf('  Loaded cohort table: %d rows\n', height(cohort_table));
            
            % Read LR head motion
            lr_motion_table = readtable(lr_motion_path, ...
                                       'TextType', 'string', ...
                                       'VariableNamingRule', 'preserve');
            
            % Rename column to LR_mean_head_motion
            lr_motion_table.Properties.VariableNames = strrep(...
                lr_motion_table.Properties.VariableNames, ...
                'mean_head_motion', 'LR_mean_head_motion');
            
            fprintf('  Loaded LR head motion: %d rows\n', height(lr_motion_table));
            
            % Read RL head motion
            rl_motion_table = readtable(rl_motion_path, ...
                                       'TextType', 'string', ...
                                       'VariableNamingRule', 'preserve');
            
            % Rename column to RL_mean_head_motion
            rl_motion_table.Properties.VariableNames = strrep(...
                rl_motion_table.Properties.VariableNames, ...
                'mean_head_motion', 'RL_mean_head_motion');
            
            fprintf('  Loaded RL head motion: %d rows\n', height(rl_motion_table));
            
            % Start with cohort table (keep only subject column)
            combined_motion = cohort_table(:, 'subject');
            
            % Left join LR head motion
            combined_motion = outerjoin(combined_motion, lr_motion_table, ...
                                       'Keys', 'subject', ...
                                       'Type', 'left', ...
                                       'MergeKeys', true);
            
            % Left join RL head motion
            combined_motion = outerjoin(combined_motion, rl_motion_table, ...
                                       'Keys', 'subject', ...
                                       'Type', 'left', ...
                                       'MergeKeys', true);
            
            fprintf('  Joined tables: %d rows, %d columns\n', height(combined_motion), width(combined_motion));
            
            % Compute average head motion (if either is NaN, result is NaN)
            combined_motion.both_mean_head_motion = mean([combined_motion.LR_mean_head_motion, ...
                                                          combined_motion.RL_mean_head_motion], 2);
            
            fprintf('  Created both_mean_head_motion column\n');
            
            % Define output path
            output_motion_path = fullfile(config.repo_root, 'data_pipeline_gitignore', 'mean_head_motion', ...
                                         'mean_head_motion_cohort_all_session_both.csv');
            
            % Create output directory if it doesn't exist
            output_motion_dir = fullfile(config.repo_root, 'data_pipeline', 'mean_head_motion');
            if ~exist(output_motion_dir, 'dir')
                fprintf('  Creating output directory: %s\n', output_motion_dir);
                mkdir(output_motion_dir);
            end
            
            % Write output
            writetable(combined_motion, output_motion_path);
            
            fprintf('  Output written: mean_head_motion_cohort_all_session_both.csv\n');
            fprintf('  Output rows: %d, columns: %d\n', height(combined_motion), width(combined_motion));
            fprintf('  Status: SUCCESS ✓\n\n');
            num_head_motion_success = num_head_motion_success + 1;
            
        catch ME
            fprintf('  Error processing head motion data: %s\n', ME.message);
            fprintf('  Status: ERROR ✗\n\n');
            num_head_motion_errors = num_head_motion_errors + 1;
        end
    end

    % Print summary
    fprintf('================================================================================\n');
    fprintf('SUMMARY:\n');
    fprintf('  Individual cohort configurations: %d\n', num_total);
    fprintf('  Successfully created:              %d\n', num_created);
    fprintf('  Skipped:                           %d\n', num_skipped);
    fprintf('  Errors:                            %d\n', num_errors);
    fprintf('\n');
    fprintf('  Combined "all" cohort files:       %d\n', num_combined);
    fprintf('  Combined errors:                   %d\n', num_combined_errors);
    fprintf('  Cohort two files extracted:        %d\n', num_two_created);
    fprintf('  Cohort two skipped:                %d\n', num_two_skipped);
    fprintf('  Cohort two errors:                 %d\n', num_two_errors);
    fprintf('\n');
    fprintf('\n');
    fprintf('  Files with averaged modularity:    %d\n', num_averaged);
    fprintf('  Averaging errors:                  %d\n', num_averaged_errors);
    fprintf('\n');
    fprintf('  Head motion files created:         %d\n', num_head_motion_success);
    fprintf('  Head motion errors:                %d\n', num_head_motion_errors);
    fprintf('\n');
    
    if num_errors == 0 && num_two_errors == 0 && num_combined_errors == 0 && num_averaged_errors == 0 && num_head_motion_errors == 0 && num_created > 0
        fprintf('  Status:                            SUCCESS ✓✓✓\n');
    elseif num_errors > 0 || num_two_errors > 0 || num_combined_errors > 0 || num_averaged_errors > 0 || num_head_motion_errors > 0
        fprintf('  Status:                            COMPLETED WITH ERRORS\n');
    else
        fprintf('  Status:                            NO TABLES CREATED\n');
    end
    fprintf('================================================================================\n\n');
end

function combined_table = fcn_join_session_simplex_tables(subject_table, cohort, condition, sessions, simplexes, parcellation, config)
% Join simplex tables across all sessions and simplexes with session-prefixed column names
%
% Creates a table with one row per subject from subject_table,
% joining modularity data from all combinations of sessions and simplexes
% with column names formatted as "<session>_<simplex>_modularity".
%
% Inputs:
%   subject_table - Table with 'subject' column (master subject list)
%   cohort - String specifying cohort (e.g., "one", "all_but_one")
%   condition - String specifying condition (e.g., "raw_features")
%   sessions - String array of session names (e.g., ["LR", "RL"])
%   simplexes - String array of simplex names (e.g., ["node", "edge", "triangle"])
%   parcellation - String specifying parcellation (e.g., "schaefer100x7")
%   config - Configuration struct with repo_root field
%
% Outputs:
%   combined_table - Table with columns:
%                    subject,
%                    LR_node_modularity, LR_edge_modularity, LR_triangle_modularity,
%                    RL_node_modularity, RL_edge_modularity, RL_triangle_modularity
%
% Uses left outer joins to preserve all subjects from subject_table.
% Missing values are filled with NaN.
%
% See also: outerjoin

% Start with subject table (only keep 'subject' column)
combined_table = subject_table(:, 'subject');
num_subjects = height(combined_table);

% Loop through all session-simplex combinations
for session_idx = 1:numel(sessions)
    session = sessions(session_idx);

    fprintf('  Processing session: %s\n', session);

    for simplex_idx = 1:numel(simplexes)
        simplex = simplexes(simplex_idx);

        % Define column name with session_simplex prefix
        output_col_name = strcat(session, '_', simplex, '_modularity');

        % Build directory name
        simplex_dir = strcat('simplex_mapper_', condition, ...
            '_cohort_', cohort, ...
            '_', session, ...
            '_', simplex, ...
            '_', parcellation);

        % Build full path to summary file
        summary_path = fullfile(config.repo_root, 'data_pipeline', ...
            'simplex_mappers_raw', simplex_dir, ...
            'summary_raw.csv');

        if ~isfile(summary_path)
            fprintf('    %s_%s table not found\n', session, simplex);
            % Create NaN column
            combined_table.(output_col_name) = NaN(num_subjects, 1);
        else
            % Read simplex table
            simplex_table = readtable(summary_path, ...
                'TextType', 'string', ...
                'VariableNamingRule', 'preserve');

            fprintf('    %s_%s table loaded: %d rows\n', session, simplex, height(simplex_table));

            % Extract only subject and modularity columns
            if ismember('mapper_stat_modularity', simplex_table.Properties.VariableNames)
                simplex_subset = simplex_table(:, {'subject', 'mapper_stat_modularity'});
                simplex_subset.Properties.VariableNames = strrep(...
                    simplex_subset.Properties.VariableNames, ...
                    "mapper_stat_modularity", output_col_name);

                % Perform left outer join
                combined_table = outerjoin(combined_table, simplex_subset, ...
                    'Keys', 'subject', ...
                    'Type', 'left', ...
                    'MergeKeys', true);
            else
                % Column doesn't exist, create NaN column
                fprintf('    WARNING: mapper_stat_modularity column not found\n');
                combined_table.(output_col_name) = NaN(num_subjects, 1);
            end
        end
    end
end
end