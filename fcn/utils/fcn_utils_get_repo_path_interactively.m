function repo_path = fcn_utils_get_repo_path_interactively()
    % Get repository path from user
    
    fprintf('Please provide the repository path:\n');
    fprintf('  Option 1: Type the full path and press Enter\n');
    fprintf('  Option 2: Type "browse" to select folder using dialog\n');
    fprintf('  Option 3: Press Enter to use current directory\n\n');
    
    user_input = input('Repository path: ', 's');
    
    if isempty(user_input)
        % Use current directory
        repo_path = pwd;
        fprintf('Using current directory: %s\n', repo_path);
        
        % Confirm with user
        confirm = input('Is this correct? (y/n): ', 's');
        if ~strcmpi(confirm, 'y')
            repo_path = fcn_utils_get_repo_path_interactively(); % Recursive call to try again
            return;
        end
        
    elseif strcmpi(user_input, 'browse')
        % Use folder browser
        repo_path = uigetdir(pwd, 'Select Repository Folder');
        
        if repo_path == 0
            fprintf('✗ No folder selected.\n');
            repo_path = [];
            return;
        end
        fprintf('Selected: %s\n', repo_path);
        
    else
        % Use provided path
        repo_path = user_input;
        
        % Check if path exists
        if ~exist(repo_path, 'dir')
            fprintf('✗ Warning: Path does not exist: %s\n', repo_path);
            retry = input('Try again? (y/n): ', 's');
            if strcmpi(retry, 'y')
                repo_path = fcn_utils_get_repo_path_interactively(); % Recursive call to try again
            else
                repo_path = [];
            end
            return;
        end
        fprintf('Using path: %s\n', repo_path);
    end
end