function expt_04a_combine_simplex_tables()
    % Combine simplex mapper tables across simplexes for each configuration
    %
    % For each combination of condition, cohort, session, and parcellation,
    % combines node, edge, and triangle tables into a single output table
    % with subjects from the cohort table.
    %
    % Output directory: <repo_root>/data_pipeline/simplex_mappers/
    % Output format: simplex_mapper_<condition>_cohort_<cohort>_<session>_<parcellation>.csv
    
    fprintf('\n');
    fprintf('================================================================================\n');
    fprintf('COMBINING SIMPLEX MAPPER TABLES\n');
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
    
    % Define conditions
    conditions = [
        "raw_features";
        "pca_fixed_components_30";
        "pca_fixed_components_40";
        "pca_fixed_components_50";
        "pca_variance_threshold_90";
        "pca_variance_threshold_95";
        "coherence"
    ];
    
    % Define cohorts, sessions, simplexes, parcellations
    cohorts = ["one", "two"];
    sessions = ["LR", "RL"];
    simplexes = ["node", "edge", "triangle"];
    parcellations = ["schaefer100x7", "schaefer200x7"];
    
    % Track statistics
    num_total = 0;
    num_created = 0;
    num_skipped = 0;
    num_errors = 0;
    
    % Loop through all combinations
    for condition_idx = 1:numel(conditions)
        condition = conditions(condition_idx);
        
        for cohort_idx = 1:numel(cohorts)
            cohort = cohorts(cohort_idx);
            
            % Map cohort name to storage name
            if cohort == "one"
                cohort_storage = "one";
            elseif cohort == "two"
                cohort_storage = "all_but_one";
            else
                error('Unknown cohort: %s', cohort);
            end
            
            for session_idx = 1:numel(sessions)
                session = sessions(session_idx);
                
                for parcellation_idx = 1:numel(parcellations)
                    parcellation = parcellations(parcellation_idx);
                    
                    num_total = num_total + 1;
                    
                    fprintf('Processing [%d]: condition=%s, cohort=%s, session=%s, parcellation=%s\n', ...
                            num_total, condition, cohort, session, parcellation);
                    
                    % Get subject table
                    subject_table_path = fullfile(config.repo_root, 'data_pipeline', 'data_cohort', ...
                                                  strcat('cohort_', cohort, '_session_', session, '.csv'));
                    
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
                    
                    % Load simplex tables
                    simplex_tables = struct();
                    any_table_exists = false;
                    
                    for simplex_idx = 1:numel(simplexes)
                        simplex = simplexes(simplex_idx);
                        
                        % Build directory name
                        simplex_dir = strcat('simplex_mapper_', condition, ...
                                           '_cohort_', cohort_storage, ...
                                           '_', session, ...
                                           '_', simplex, ...
                                           '_', parcellation);
                        
                        % Build full path to summary file
                        summary_path = fullfile(config.repo_root, 'data_pipeline', ...
                                               'simplex_mappers_raw', simplex_dir, ...
                                               'summary_raw.csv');
                        
                        if ~isfile(summary_path)
                            fprintf('  %s table not found: %s\n', simplex, summary_path);
                            fprintf('    WARNING: Experiment may not have been run, or directory needs renaming.\n');
                            fprintf('    Run expt_01f_clean_up_directory in expt folder to fix directory names.\n');
                            simplex_tables.(simplex) = [];
                        else
                            % Read simplex table
                            simplex_table = readtable(summary_path, ...
                                                     'TextType', 'string', ...
                                                     'VariableNamingRule', 'preserve');
                            simplex_tables.(simplex) = simplex_table;
                            any_table_exists = true;
                            fprintf('  %s table loaded: %d rows\n', simplex, height(simplex_table));
                        end
                    end
                    
                    % Skip if no tables exist
                    if ~any_table_exists
                        fprintf('  No simplex tables found for this configuration\n');
                        fprintf('  Status: SKIPPED ✗\n\n');
                        num_skipped = num_skipped + 1;
                        continue;
                    end
                    
                    % Create combined table using joins
                    try
                        combined_table = fcn_combine_simplex_tables(subject_table, simplex_tables, simplexes);
                        
                        % Define output filename
                        output_filename = strcat('simplex_mapper_', condition, ...
                                               '_cohort_', cohort, ...
                                               '_', session, ...
                                               '_', parcellation, '.csv');
                        output_path = fullfile(output_directory, output_filename);
                        
                        % Write output
                        writetable(combined_table, output_path);
                        
                        fprintf('  Output written: %s\n', output_filename);
                        fprintf('  Output rows: %d, columns: %d\n', height(combined_table), width(combined_table));
                        fprintf('  Status: SUCCESS ✓\n\n');
                        num_created = num_created + 1;
                        
                    catch ME
                        fprintf('  Error creating combined table: %s\n', ME.message);
                        fprintf('  Status: ERROR ✗\n\n');
                        num_errors = num_errors + 1;
                    end
                end
            end
        end
    end
    
    % Print summary
    fprintf('================================================================================\n');
    fprintf('SUMMARY:\n');
    fprintf('  Total configurations: %d\n', num_total);
    fprintf('  Successfully created: %d\n', num_created);
    fprintf('  Skipped:              %d\n', num_skipped);
    fprintf('  Errors:               %d\n', num_errors);
    
    if num_errors == 0 && num_created > 0
        fprintf('  Status:               SUCCESS ✓✓✓\n');
    elseif num_errors > 0
        fprintf('  Status:               COMPLETED WITH ERRORS\n');
    else
        fprintf('  Status:               NO TABLES CREATED\n');
    end
    fprintf('================================================================================\n\n');
end

function combined_table = fcn_combine_simplex_tables(subject_table, simplex_tables, simplices)
    % Combine simplex tables using left joins
    %
    % Creates a combined table with one row per subject from subject_table,
    % joining data from node, edge, and triangle simplex tables.
    %
    % Inputs:
    %   subject_table - Table with 'subject' column (master subject list)
    %   simplex_tables - Struct with fields 'node', 'edge', 'triangle' containing tables
    %                    (or empty arrays if table doesn't exist)
    %   simplexes - String array of simplex names to process (e.g., ["node", "edge", "triangle"])
    %
    % Outputs:
    %   combined_table - Table with columns:
    %                    subject, 
    %                    node_modularity, edge_modularity, triangle_modularity,
    %                    node_num_nodes, edge_num_nodes, triangle_num_nodes,
    %                    node_num_edges, edge_num_edges, triangle_num_edges
    %
    % Uses left outer joins to preserve all subjects from subject_table.
    % Missing values are filled with NaN.
    %
    % Example:
    %   subject_table has subjects: [100206, 100307, 100408]
    %   node_table has: [100206, 100408] with modularity values
    %   After join:
    %     subject | node_modularity
    %     100206  | 0.42
    %     100307  | NaN              (not in node_table)
    %     100408  | 0.45
    %
    % See also: outerjoin
    
    % Start with subject table (only keep 'subject' column)
    combined_table = subject_table(:, 'subject');
    num_subjects = height(combined_table);
    
    % Join each simplex table
    for simplex_idx = 1:numel(simplices)
        simplex = simplices(simplex_idx);
        
        output_col_names = ["subject", strcat(simplex, ["_modularity", "_num_nodes", "_num_edges"])];
        cols_to_extract = ["subject", "mapper_stat_modularity", "mapper_num_nodes", "mapper_num_edges"];
        
        % Check if simplex table exists and has data
        if ~isempty(simplex_tables.(simplex))
            simplex_table = simplex_tables.(simplex);
            simplex_table_extracted = simplex_table(:, cols_to_extract);
            simplex_table_extracted.Properties.VariableNames = output_col_names;
            
            % Perform left outer join
            % - Keeps all rows from combined_table (all subjects)
            % - Adds columns from simplex_subset
            % - Subjects not in simplex_subset get NaN values
            combined_table = outerjoin(combined_table, simplex_table_extracted, ...
                                      'Keys', 'subject', ...
                                      'Type', 'left', ...
                                      'MergeKeys', true);
        else
            for col_idx = 2:numel(output_col_names) % skip "subject"
                combined_table.(output_col_names(col_idx)) = NaN(num_subjects, 1);
            end
        end
    end
end