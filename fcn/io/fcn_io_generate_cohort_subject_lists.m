function fcn_io_generate_cohort_subject_lists()
    % Generate subject lists for each cohort and session combination
    %
    % Creates CSV files containing subject IDs that have complete data
    % for specified cohort and session combinations. Filters subjects
    % based on cohort membership and data availability.
    %
    % Outputs:
    %   Creates CSV files in data_pipeline/data_cohort/:
    %     cohort_<cohort_choice>_session_<session_choice>.csv
    %   
    %   Where:
    %     cohort_choice: one, two, all, all_but_one, all_but_one_two
    %     session_choice: LR, RL, both
    %
    % Example:
    %   fcn_io_generate_cohort_subject_lists();
    
    %% Get configuration
    config = fcn_utils_get_config();
    
    %% Define output filenames upfront
    cohorts = ["one", "two", "all", "all_but_one", "all_but_one_two"];
    sessions = ["LR", "RL", "both"];
    
    output_dir = fullfile(config.repo_root, "data_pipeline", "data_cohort");
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    % Generate all output filenames
    output_filenames = struct();
    for cohort = cohorts
        for session = sessions
            field_name = sprintf("%s_%s", cohort, session);
            output_filenames.(field_name) = fullfile(output_dir, ...
                sprintf("cohort_%s_session_%s.csv", cohort, session));
        end
    end
    
    %% Load input data
    
    % Load data availability table (from previous script output)
    data_availability_filename = fullfile(config.repo_root, "data_pipeline", ...
        "data_cohort", "fmri_data_availability_by_subject.csv");
    data_availability = readtable(data_availability_filename, ...
        "VariableNamingRule", "preserve");
    
    % Load cohort definitions from raw data
    cohort_one_filename = fullfile(config.repo_root, "data_raw", "data_cohort", "cohort_one.csv");
    cohort_two_filename = fullfile(config.repo_root, "data_raw", "data_cohort", "cohort_two.csv");
    
    cohort_one_subjects = readtable(cohort_one_filename, ...
        "VariableNamingRule", "preserve");
    cohort_two_subjects = readtable(cohort_two_filename, ...
        "VariableNamingRule", "preserve");
    
    % Extract subject ID columns (preserve original ordering)
    cohort_one_subject_ids = cohort_one_subjects.Subject;
    cohort_two_subject_ids = cohort_two_subjects.Subject;
    all_subjects = data_availability.Subject;
    
    %% Process each cohort and session combination
    
    for cohort = cohorts
        
        % Get subjects in this cohort (in original order)
        cohort_subject_ids = get_cohort_subjects(cohort, ...
            cohort_one_subject_ids, cohort_two_subject_ids, all_subjects);
        
        % Filter data_availability to only subjects in this cohort
        % Use ismember to preserve original cohort ordering
        [is_in_cohort, idx_in_availability] = ismember(cohort_subject_ids, ...
            data_availability.Subject);
        
        % Get rows from data_availability in cohort order
        cohort_data = data_availability(idx_in_availability(is_in_cohort), :);
        
        for session = sessions
            
            % Find relevant columns for this session
            var_names = cohort_data.Properties.VariableNames;
            
            if strcmp(session, "both")
                % Both sessions: need both LR and RL data
                relevant_columns = ~strcmpi(var_names, "Subject") & ...
                                  ~contains(var_names, "run-2") & ...
                                  (contains(var_names, "LR") | contains(var_names, "RL"));
            else
                % Single session: LR or RL
                relevant_columns = ~strcmpi(var_names, "Subject") & ...
                                  ~contains(var_names, "run-2") & ...
                                  contains(var_names, session);
            end
            
            % Filter subjects with complete data for this session
            subject_complete_data_rows = all(cohort_data{:, relevant_columns}, 2);
            subject_complete_data_table = cohort_data(subject_complete_data_rows, "Subject");
            
            % Write output
            field_name = sprintf("%s_%s", cohort, session);
            output_filename = output_filenames.(field_name);
            writetable(subject_complete_data_table, output_filename);
            
            % Progress feedback
            fprintf("Created %s with %d subjects\n", ...
                output_filename, height(subject_complete_data_table));
        end
    end
    
    fprintf("\nAll cohort subject lists generated successfully\n");
end


function cohort_subjects = get_cohort_subjects(cohort_name, ...
    cohort_one_subject_ids, cohort_two_subject_ids, all_subjects)
    % Get list of subjects belonging to specified cohort
    %
    % Returns subjects in the order they appear in the original cohort files
    %
    % Inputs:
    %   cohort_name - "one", "two", "all", "all_but_one", "all_but_one_two"
    %   cohort_one_subject_ids - Subject IDs from cohort_one.csv
    %   cohort_two_subject_ids - Subject IDs from cohort_two.csv
    %   all_subjects - All subject IDs from data availability table
    %
    % Outputs:
    %   cohort_subjects - String array of subject IDs in the cohort
    
    switch cohort_name
        case "one"
            cohort_subjects = cohort_one_subject_ids;
            
        case "two"
            cohort_subjects = cohort_two_subject_ids;
            
        case "all"
            cohort_subjects = all_subjects;
            
        case "all_but_one"
            % All subjects except those in cohort one
            is_not_in_one = ~ismember(all_subjects, cohort_one_subject_ids);
            cohort_subjects = all_subjects(is_not_in_one);
            
        case "all_but_one_two"
            % All subjects except those in cohort one or two
            is_not_in_one = ~ismember(all_subjects, cohort_one_subject_ids);
            is_not_in_two = ~ismember(all_subjects, cohort_two_subject_ids);
            cohort_subjects = all_subjects(is_not_in_one & is_not_in_two);
            
        otherwise
            error('Unknown cohort: %s', cohort_name);
    end
end