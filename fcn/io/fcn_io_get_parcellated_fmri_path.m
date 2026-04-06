function filepath = fcn_io_get_parcellated_fmri_path(base_dir, subject, task, session, ...
                                                     parcellation, batch, varargin)
    % Build full path to xcpengine parcellated fMRI timeseries file
    %
    % Constructs the file path following xcpengine output structure:
    % base_dir/xa<batch>/sub-<subject>_task-<task>_acq-<session>/fcon/<parcellation>/
    %   sub-<subject>_task-<task>_acq-<session>_<parcellation>_ts.1D
    %
    % Inputs:
    %   base_dir - Base xcpengine output directory
    %   subject - Subject ID number (e.g., 100206)
    %   task - Task name (e.g., "WM", "REST")
    %   session - Session identifier (e.g., "LR", "LR_run-1")
    %   parcellation - Parcellation name (e.g., "schaefer100x7")
    %   batch - Batch letter (e.g., "a", "b")
    %
    % Variable Inputs:
    %   motion_data_flag - (0|1) If 1, return path to motion data file 
    %                      instead of parcellated timeseries (default: 0)
    %
    % Outputs:
    %   filepath - Full path to .1D timeseries file (or motion data file)
    %
    % Example:
    %   path = fcn_io_get_parcellated_fmri_path( ...
    %       "/oak/.../xcpengine_2025_out", 100206, "WM", "LR", ...
    %       "schaefer100x7", "a");
    %   % Returns: .../xaa/sub-100206_task-WM_acq-LR/fcon/schaefer100x7/
    %   %          sub-100206_task-WM_acq-LR_schaefer100x7_ts.1D
    %
    %   path = fcn_io_get_parcellated_fmri_path( ...
    %       "/oak/.../xcpengine_2025_out", 100206, "WM", "LR", ...
    %       "schaefer100x7", "a", "motion_data_flag", 1);
    %   % Returns: .../xaa/sub-100206_task-WM_acq-LR/confound2/mc/
    %   %          sub-100206_task-WM_acq-LR_fd.1D
    %
    % See also: fcn_io_check_fmri_data_availability
    
    % Parse optional inputs
    p = inputParser;
    addParameter(p, 'motion_data_flag', 0, @(x) isnumeric(x) && isscalar(x));
    parse(p, varargin{:});
    motion_data_flag = p.Results.motion_data_flag;
    
    % Build batch directory (e.g., "a" -> "xaa")
    batch_dir = strcat("xa", batch);
    
    % Build scan identifier
    scan_id = sprintf("sub-%d_task-%s_acq-%s", subject, task, session);
    
    % Construct full path
    if motion_data_flag
        filename = sprintf("%s_fd.1D", scan_id);
        filepath = fullfile(base_dir, batch_dir, scan_id, "confound2/mc", filename);
    else
        filename = sprintf("%s_%s_ts.1D", scan_id, parcellation);
        filepath = fullfile(base_dir, batch_dir, scan_id, "fcon", parcellation, filename);
    end
end