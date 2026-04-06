function mean_head_motion = fcn_io_get_mean_head_motion(subject, session, varargin)
% Compute mean head motion (framewise displacement) across tasks
%
% Loads motion data for specified tasks and computes the overall mean
% framewise displacement value for quality control and subject screening.
%
% Inputs:
%   subject - Subject ID number (e.g., 100206)
%   session - Session identifier: "LR" or "RL"
%
% Optional Parameters (name-value pairs):
%   'rest_session' - REST session identifier (default: "<session>_run-1")
%   'task_configuration' - Which tasks to include (default: "rest_5min_and_tasks")
%                          "rest_5min_and_tasks" - First 5min REST + all tasks
%                          "rest_all_and_tasks" - Full REST + all tasks
%                          "tasks_only" - Tasks only (no REST)
%   'verbose_flag' - Print progress: 1=yes, 0=no (default: 1)
%
% Outputs:
%   mean_head_motion - Scalar mean framewise displacement (mm) across all
%                      specified tasks and timepoints. Returns NaN if data missing.
%
% Example:
%   config = fcn_utils_get_config();
%   mean_fd = fcn_io_get_mean_head_motion(100206, "LR");
%   % Returns: 0.15 (example mean FD in mm)
%
%   % Custom configuration
%   mean_fd = fcn_io_get_mean_head_motion(100206, "LR", ...
%       'task_configuration', 'tasks_only', 'verbose_flag', 0);
%
% See also: fcn_io_load_fmri_data_for_subject, fcn_edgeMapper_preprocess_data,
%  fcn_edgeMapper_compute_and_analyze_simplex_mapper

%% Parse and validate inputs

p = inputParser;
addRequired(p, 'subject', @isnumeric);
addRequired(p, 'session', @(x) isStringScalar(x) || ischar(x));

% Data parameters
addParameter(p, 'rest_session', '', @(x) isStringScalar(x) || ischar(x));

% Preprocessing parameters
addParameter(p, 'task_configuration', 'rest_5min_and_tasks', @(x) isStringScalar(x) || ischar(x));


% Output parameters
addParameter(p, 'verbose_flag', 1, @isnumeric);

parse(p, subject, session, varargin{:});

% Extract parameters
session = string(p.Results.session);
task_configuration = string(p.Results.task_configuration);
rest_session = string(p.Results.rest_session);
verbose_flag = p.Results.verbose_flag;


% Set defaults
if strlength(rest_session) == 0
    rest_session = strcat(session, "_run-1");
end

%% Print configuration

if verbose_flag
    fprintf('\n========================================\n');
    fprintf('Mean Head Motion Extraction\n');
    fprintf('========================================\n\n');
    fprintf('Subject: %d\n', subject);
    fprintf('Session: %s\n', session);
    fprintf('Rest session: %s\n', rest_session);
    fprintf('Task configuration: %s\n', task_configuration);
    fprintf('\n');
end

%% Define tasks and get time windows

tasks_string = ["EMOTION", "GAMBLING", "LANGUAGE", "MOTOR", "RELATIONAL", "SOCIAL", "WM"];
if ismember(task_configuration, ["rest_5min_and_tasks", "rest_all_and_tasks"])
    tasks_string = ["REST", tasks_string];
end

[starting_times, ending_times, unit_time, seconds_per_TR] = ...
    fcn_edgeMapper_get_time_windows(tasks_string, task_configuration);

parcellation = "schaefer100x7"; % dummy, not going to be relevant
config = fcn_utils_get_config();
[motion_cell, missing_data_flag] = fcn_io_load_fmri_data_for_subject(subject, ...
    tasks_string, session, rest_session, parcellation, config, ...
    'verbose_flag', verbose_flag, 'motion_data_flag', 1);

if missing_data_flag
    warning('Missing data for subject %d', subject);
    mean_head_motion = nan;
    return;
end

[concatenated_motion_data, ~, ~] = ...
    fcn_edgeMapper_preprocess_data(tasks_string, motion_cell, ...
    'starting_times', starting_times, ...
    'ending_times', ending_times, ...
    'unit_time', unit_time, ...
    'seconds_per_TR', seconds_per_TR, ...
    'motion_data_flag', 1);

mean_head_motion = mean(concatenated_motion_data);
if verbose_flag
    fprintf('Mean framewise displacement: %.4f mm\n\n', mean_head_motion);
end
end