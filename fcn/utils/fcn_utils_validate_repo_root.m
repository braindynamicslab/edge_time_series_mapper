function is_validated = fcn_utils_validate_repo_root(repo_root)
    is_validated = 0;
    % Validate
    if ~exist(repo_root, 'dir')
        warning('Path in config/repo_root_local.txt does not exist: %s', repo_root);
        return;
    end
    
    has_fcn = exist(fullfile(repo_root, 'fcn'), 'dir') == 7;
    has_config = exist(fullfile(repo_root, 'config'), 'dir') == 7;
    
    if ~has_fcn || ~has_config
        warning(['Path in config/repo_root_local.txt is invalid.\n', ...
               'Missing fcn/ or config/ directories at: %s'], repo_root);
        return;
    end
    is_validated = 1;
end