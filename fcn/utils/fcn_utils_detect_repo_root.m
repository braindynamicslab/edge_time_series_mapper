function repo_root = fcn_utils_detect_repo_root()
    % Detect repository root directory
    %
    % Attempts to find repository root by:
    %   1. Using known location of this file (fcn/utils/) - FAST
    %   2. Searching upward for .git directory - ROBUST
    %   3. Reading from config/repo_root_local.txt - FALLBACK
    %
    % This file should be at: <repo_root>/fcn/utils/fcn_utils_detect_repo_root.m
    %
    % Outputs:
    %   repo_root - Absolute path to repository root directory
    %
    % Example:
    %   repo_root = fcn_utils_detect_repo_root();
    %   data_dir = fullfile(repo_root, 'data_raw');
    %
    % See also: fcn_utils_get_config
    
    %% Method 1: Use known file location (FAST - called frequently)
    this_file_path = mfilename('fullpath');
    utils_dir = fileparts(this_file_path);      % <repo_root>/fcn/utils
    fcn_dir = fileparts(utils_dir);             % <repo_root>/fcn
    repo_root_candidate = fileparts(fcn_dir);   % <repo_root>
    
    % Validate structure
    [~, utils_folder_name] = fileparts(utils_dir);
    [~, fcn_folder_name] = fileparts(fcn_dir);
    
    is_valid_structure = strcmp(utils_folder_name, 'utils') && ...
                        strcmp(fcn_folder_name, 'fcn');
    
    if is_valid_structure
        has_fcn_dir = exist(fullfile(repo_root_candidate, 'fcn'), 'dir') == 7;
        has_config_dir = exist(fullfile(repo_root_candidate, 'config'), 'dir') == 7;
        
        if has_fcn_dir && has_config_dir
            repo_root = repo_root_candidate;
            return;
        end
    end
    
    %% Method 2: Search upward for .git directory (ROBUST)
    fprintf('Warning: Fast detection failed. Searching for .git directory...\n');
    
    search_dir = fileparts(this_file_path);
    
    for level = 1:10
        if exist(fullfile(search_dir, '.git'), 'dir') == 7
            repo_root = search_dir;
            fprintf('Found repository root via .git search: %s\n', repo_root);
            return;
        end
        
        parent_dir = fileparts(search_dir);
        if strcmp(parent_dir, search_dir)
            break;  % Reached filesystem root
        end
        search_dir = parent_dir;
    end
    
    %% Method 3: Read from config/repo_root_local.txt (FALLBACK)
    fprintf('Warning: .git directory not found. Trying config/repo_root_local.txt...\n');
    
    config_file_path = fullfile(repo_root_candidate, 'config', 'repo_root_local.txt');
    
    if exist(config_file_path, 'file') == 2
        fid = fopen(config_file_path, 'r');
        if fid == -1
            error('Could not open config/repo_root_local.txt for reading');
        end
        
        repo_root = strtrim(fgetl(fid));
        fclose(fid);
        repo_root = string(repo_root);
        
        % Validate
        if ~exist(repo_root, 'dir')
            error('Path in config/repo_root_local.txt does not exist: %s', repo_root);
        end
        
        has_fcn = exist(fullfile(repo_root, 'fcn'), 'dir') == 7;
        has_config = exist(fullfile(repo_root, 'config'), 'dir') == 7;
        
        if ~has_fcn || ~has_config
            error(['Path in config/repo_root_local.txt is invalid.\n', ...
                   'Missing fcn/ or config/ directories at: %s'], repo_root);
        end
        
        fprintf('Successfully loaded repository root from config/repo_root_local.txt\n');
        return;
    end
    
    %% All methods failed - provide detailed error message
    error_msg = sprintf(['\n', ...
        '================================================================================\n', ...
        'ERROR: Cannot detect repository root directory\n', ...
        '================================================================================\n\n', ...
        'All detection methods failed:\n\n', ...
        '(1) FAST METHOD - Expected file structure:\n', ...
        '    This file should be at: <repo_root>/fcn/utils/fcn_utils_detect_repo_root.m\n', ...
        '    Current file location:  %s\n', ...
        '    Expected repo root:     %s\n\n', ...
        '    Found directories:\n', ...
        '      utils folder name: %s (expected: "utils")\n', ...
        '      fcn folder name:   %s (expected: "fcn")\n', ...
        '      fcn/ exists:       %s\n', ...
        '      config/ exists:    %s\n\n', ...
        '    → PROBLEM: File structure does not match expected layout.\n', ...
        '              Either this file was moved, or repository structure changed.\n\n', ...
        '(2) ROBUST METHOD - Searched for .git directory:\n', ...
        '    Searched up to 10 levels from: %s\n', ...
        '    → PROBLEM: No .git directory found.\n', ...
        '              Are you inside a git repository?\n', ...
        '              Did you download as ZIP instead of git clone?\n\n', ...
        '(3) FALLBACK METHOD - config/repo_root_local.txt:\n', ...
        '    Expected file location: %s\n', ...
        '    → PROBLEM: File does not exist.\n\n', ...
        '================================================================================\n', ...
        'HOW TO FIX (Choose one option):\n', ...
        '================================================================================\n\n', ...
        'OPTION A: Fix repository structure (recommended)\n', ...
        '  - Ensure this file is at: <repo_root>/fcn/utils/fcn_utils_detect_repo_root.m\n', ...
        '  - Ensure you have fcn/ and config/ directories in repository root\n\n', ...
        'OPTION B: Create manual configuration file\n', ...
        '  1. Create a new text file at this location:\n', ...
        '     %s\n\n', ...
        '  2. Open the file in any text editor (TextEdit, Notepad, nano, etc.)\n\n', ...
        '  3. Type the FULL PATH to your repository root on a single line.\n', ...
        '     For example:\n', ...
        '       /Users/yourname/Documents/GitHub/brain_HOI\n', ...
        '     or on Windows:\n', ...
        '       C:/Users/yourname/Documents/GitHub/brain_HOI\n\n', ...
        '  4. Save the file (make sure it is named exactly "repo_root_local.txt")\n\n', ...
        '  5. Re-run your script\n\n', ...
        '  Note: This file is automatically git-ignored (follows *_local.* pattern)\n', ...
        '        so it will not be committed to version control.\n\n', ...
        '================================================================================\n'], ...
        this_file_path, ...                           % Current file location
        repo_root_candidate, ...                      % Expected repo root
        utils_folder_name, ...                        % Found utils folder name
        fcn_folder_name, ...                          % Found fcn folder name
        tf_to_string(has_fcn_dir), ...                % fcn/ exists?
        tf_to_string(has_config_dir), ...             % config/ exists?
        fileparts(this_file_path), ...                % Search start location
        config_file_path, ...                         % Expected config file
        config_file_path);                            % Repeated for fix instructions
    
    error(error_msg);
end


function str = tf_to_string(tf)
    % Convert true/false to "YES"/"NO" for display
    if tf
        str = 'YES';
    else
        str = 'NO';
    end
end