function test_simplex_mapper_duplicates()
    % Check for duplicate subjects in simplex_mapper directories
    %
    % Loops through all directories in data_pipeline starting with "simplex_mapper_",
    % opens summary.csv in each, and checks for duplicate Subject IDs.
    %
    % Outputs:
    %   Prints directory name and whether duplicates were found
    
    fprintf('\n');
    fprintf('================================================================================\n');
    fprintf('CHECKING FOR DUPLICATE SUBJECTS IN SIMPLEX_MAPPER DIRECTORIES\n');
    fprintf('================================================================================\n\n');
    
    % Get all directories starting with "simplex_mapper_"
    config = fcn_utils_get_config();
    dirs = dir(fullfile(config.repo_root, 'data_pipeline/simplex_mapper_*'));
    dirs = dirs([dirs.isdir]);  % Keep only directories
    
    % Filter out '.' and '..' if present
    dir_names = string({dirs.name});
    valid_idx = ~(dir_names == "." | dir_names == "..");
    dirs = dirs(valid_idx);
    
    num_dirs = numel(dirs);
    
    if num_dirs == 0
        fprintf('No directories found matching pattern "simplex_mapper_*"\n\n');
        return;
    end
    
    fprintf('Found %d directories to check\n\n', num_dirs);
    
    % Track summary statistics
    num_checked = 0;
    num_with_duplicates = 0;
    num_no_file = 0;
    num_errors = 0;
    
    % Loop through each directory
    for dir_idx = 1:num_dirs
        dir_name = string(dirs(dir_idx).name);
        summary_path = fullfile('data_pipeline', dir_name, 'summary_raw.csv');
        
        fprintf('Directory %d/%d: %s\n', dir_idx, num_dirs, dir_name);
        fprintf('  File: %s\n', summary_path);
        
        % Check if summary.csv exists
        if ~isfile(summary_path)
            fprintf('  Result: summary_raw.csv NOT FOUND ✗\n\n');
            num_no_file = num_no_file + 1;
            continue;
        end
        
        % Try to read the file
        try
            % Read CSV with preserved column names
            data = readtable(summary_path, ...
                            'TextType', 'string', ...
                            'VariableNamingRule', 'preserve');
            
            % Check if Subject column exists
            if ~ismember('subject', data.Properties.VariableNames)
                fprintf('  Result: Subject column NOT FOUND ✗\n\n');
                num_errors = num_errors + 1;
                continue;
            end
            
            % Get Subject column
            subjects = data.subject;
            num_subjects = numel(subjects);
            
            % Find duplicates
            [unique_subjects, ~, idx] = unique(subjects);
            num_unique = numel(unique_subjects);
            
            if num_unique < num_subjects
                % Duplicates found
                num_duplicates = num_subjects - num_unique;
                
                % Find which subjects are duplicated
                counts = histcounts(idx, 1:(num_unique+1));
                duplicated_subjects = unique_subjects(counts > 1);
                
                fprintf('  Total subjects: %d\n', num_subjects);
                fprintf('  Unique subjects: %d\n', num_unique);
                fprintf('  Result: DUPLICATES FOUND ✗\n');
                fprintf('  Duplicated subjects (%d):\n', numel(duplicated_subjects));
                
                for dup_idx = 1:numel(duplicated_subjects)
                    dup_subject = duplicated_subjects(dup_idx);
                    count = sum(subjects == dup_subject);
                    fprintf('    - %s (appears %d times)\n', dup_subject, count);
                end
                fprintf('\n');
                
                num_with_duplicates = num_with_duplicates + 1;
            else
                % No duplicates
                fprintf('  Total subjects: %d\n', num_subjects);
                fprintf('  Result: NO DUPLICATES ✓\n\n');
            end
            
            num_checked = num_checked + 1;
            
        catch ME
            % Error reading file
            fprintf('  Result: ERROR reading file ✗\n');
            fprintf('  Error: %s\n\n', ME.message);
            num_errors = num_errors + 1;
        end
    end
    
    % Print summary
    fprintf('================================================================================\n');
    fprintf('SUMMARY:\n');
    fprintf('  Total directories found:     %d\n', num_dirs);
    fprintf('  Successfully checked:        %d\n', num_checked);
    fprintf('  Directories with duplicates: %d\n', num_with_duplicates);
    fprintf('  Files not found:             %d\n', num_no_file);
    fprintf('  Errors:                      %d\n', num_errors);
    
    if num_with_duplicates == 0 && num_checked > 0
        fprintf('  Status:                      ALL CLEAN ✓✓✓\n');
    elseif num_with_duplicates > 0
        fprintf('  Status:                      DUPLICATES DETECTED - REVIEW NEEDED\n');
    end
    fprintf('================================================================================\n\n');
end