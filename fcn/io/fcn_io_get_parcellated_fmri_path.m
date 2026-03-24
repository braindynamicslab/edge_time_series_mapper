function filepath = fcn_io_get_parcellated_fmri_path(base_dir, subject, task, session, ...
                                                     parcellation, batch)
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
    % Outputs:
    %   filepath - Full path to .1D timeseries file
    %
    % Example:
    %   path = fcn_io_get_parcellated_fmri_path( ...
    %       "/oak/.../xcpengine_2025_out", 100206, "WM", "LR", ...
    %       "schaefer100x7", "a");
    %   % Returns: .../xaa/sub-100206_task-WM_acq-LR/fcon/schaefer100x7/
    %   %          sub-100206_task-WM_acq-LR_schaefer100x7_ts.1D
    %
    % See also: fcn_io_check_fmri_data_availability
    
    % Build batch directory (e.g., "a" -> "xaa")
    batch_dir = strcat("xa", batch);
    
    % Build scan identifier
    scan_id = sprintf("sub-%d_task-%s_acq-%s", subject, task, session);
    
    % Build filename
    filename = sprintf("%s_%s_ts.1D", scan_id, parcellation);
    
    % Construct full path
    filepath = fullfile(base_dir, batch_dir, scan_id, "fcon", parcellation, filename);
end