function expt_01f_clean_up_directory()
    % Rename simplex_mapper directories to standardized format
    %
    % Loops through all directories in data_pipeline starting with "simplex_mapper_",
    % parses and reformats the names, then moves them to data_pipeline/simplex_mappers_raw/
    % with the new standardized names.
    %
    % Outputs:
    %   Prints old and new directory names and performs renaming
    
    fprintf('\n');
    fprintf('================================================================================\n');
    fprintf('RENAMING SIMPLEX_MAPPER DIRECTORIES\n');
    fprintf('================================================================================\n\n');
    
    % Get configuration
    config = fcn_utils_get_config();
    
    % Get all directories starting with "simplex_mapper_"
    dirs = dir(fullfile(config.repo_root, 'data_pipeline', 'simplex_mapper_*'));
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
    
    fprintf('Found %d directories to process\n\n', num_dirs);
    
    % Create target directory if it doesn't exist
    target_base_dir = fullfile(config.repo_root, 'data_pipeline', 'simplex_mappers_raw');
    if ~exist(target_base_dir, 'dir')
        fprintf('Creating target directory: %s\n\n', target_base_dir);
        mkdir(target_base_dir);
    end
    
    % Track statistics
    num_renamed = 0;
    num_skipped = 0;
    num_errors = 0;
    
    % Loop through each directory
    for dir_idx = 1:num_dirs
        directory_name = string(dirs(dir_idx).name);
        
        fprintf('Processing %d/%d:\n', dir_idx, num_dirs);
        fprintf('  Old: %s\n', directory_name);
        
        % Parse and format the directory name
        [rename_flag, new_directory_name] = fcn_io_parse_and_format_simplex_mapper_directory_name(directory_name);
        
        % Check if parsing succeeded
        if new_directory_name == ""
            fprintf('  New: [FAILED TO PARSE]\n');
            fprintf('  Action: SKIPPED ✗\n\n');
            num_skipped = num_skipped + 1;
            continue;
        end
        
        fprintf('  New: %s\n', new_directory_name);
        
        % Build full paths
        old_path = fullfile(config.repo_root, 'data_pipeline', directory_name);
        new_path = fullfile(target_base_dir, new_directory_name);
        
        % Check if target already exists
        if exist(new_path, 'dir')
            fprintf('  Target already exists: %s\n', new_path);
            fprintf('  Action: SKIPPED (target exists) ✗\n\n');
            num_skipped = num_skipped + 1;
            continue;
        end
        
        % Check if old and new are the same (already in correct location with correct name)
        if strcmp(old_path, new_path)
            fprintf('  Already in correct location with correct name\n');
            fprintf('  Action: SKIPPED (already correct) ✓\n\n');
            num_skipped = num_skipped + 1;
            continue;
        end
        
        % Perform the move/rename
        try
            fprintf('  Moving from: %s\n', old_path);
            fprintf('  Moving to:   %s\n', new_path);
            
            movefile(old_path, new_path);
            
            fprintf('  Action: RENAMED ✓\n\n');
            num_renamed = num_renamed + 1;
            
        catch ME
            fprintf('  Error: %s\n', ME.message);
            fprintf('  Action: ERROR ✗\n\n');
            num_errors = num_errors + 1;
        end
    end
    
    % Print summary
    fprintf('================================================================================\n');
    fprintf('SUMMARY:\n');
    fprintf('  Total directories found: %d\n', num_dirs);
    fprintf('  Successfully renamed:    %d\n', num_renamed);
    fprintf('  Skipped:                 %d\n', num_skipped);
    fprintf('  Errors:                  %d\n', num_errors);
    
    if num_errors == 0 && num_renamed > 0
        fprintf('  Status:                  SUCCESS ✓✓✓\n');
    elseif num_errors > 0
        fprintf('  Status:                  COMPLETED WITH ERRORS\n');
    else
        fprintf('  Status:                  NO CHANGES NEEDED\n');
    end
    fprintf('================================================================================\n\n');
    
    % Final note
    if num_renamed > 0
        fprintf('NOTE: Directories have been moved to: %s\n', target_base_dir);
        fprintf('      Please verify the results before proceeding.\n\n');
    end
end