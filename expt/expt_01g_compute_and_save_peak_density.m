% expt_add_peak_density_to_mat_files.m
% Compute and save peak_density to simplex mapper mat files
%
% This script:
%   1. Iterates through all subjects in cohorts one and two
%   2. Loads existing simplex mapper mat files
%   3. Computes peak_density using peak_threshold = 0.95
%   4. Saves peak_density as a new field: amplitude_peak_density_peak_threshold_95

%% Setup
clear; close all; clc;

% Configuration
cohorts = ["one", "two"];
session = "LR";
simplices = ["node", "edge", "triangle"];
parcellation = "schaefer100x7";
peak_threshold = 0.95;

config = fcn_utils_get_config();

%% Process each cohort and simplex
for cohort = cohorts
    fprintf('\n===========================================\n');
    fprintf('Processing Cohort: %s\n', cohort);
    fprintf('===========================================\n\n');
    
    % Determine cohort storage directory name
    if cohort == "one"
        cohort_storage = "one";
    else
        cohort_storage = "all_but_one";
    end
    
    % Load subject list
    cohort_csv = fullfile(config.repo_root, "data_pipeline", "data_cohort", ...
        sprintf("cohort_%s_session_%s.csv", cohort, session));
    
    if ~exist(cohort_csv, 'file')
        warning('Cohort file not found: %s', cohort_csv);
        continue;
    end
    
    subjects = readtable(cohort_csv, "VariableNamingRule", "preserve").Subject;
    num_subjects = numel(subjects);
    
    fprintf('Found %d subjects in cohort %s\n\n', num_subjects, cohort);
    
    for simplex = simplices
        fprintf('-------------------------------------------\n');
        fprintf('Simplex: %s\n', simplex);
        fprintf('-------------------------------------------\n');
        
        % Define data directory
        data_directory = fullfile(config.scratch_dir, sprintf(...
            "simplex_mapper_raw_features_cohort_%s_%s_%s_%s", ...
            cohort_storage, session, simplex, parcellation));
        
        if ~exist(data_directory, 'dir')
            warning('Data directory not found: %s', data_directory);
            continue;
        end
        
        % Process each subject
        for subject_idx = 1:num_subjects
            subject = subjects(subject_idx);
            
            fprintf('%s. Subject %d (%d/%d): ', ...
                datetime('now'), subject, subject_idx, num_subjects);
            
            % Construct filename
            filename = sprintf("simplexMapper_%s_%d_%s_%s_data.mat", ...
                simplex, subject, session, parcellation);
            filepath = fullfile(data_directory, filename);
            
            % Check if file exists
            if ~exist(filepath, 'file')
                fprintf('File not found - SKIP\n');
                continue;
            end
            
            % Load mat file
            loaded_data = matfile(filepath, 'Writable', true);
            
            % Check if amplitude_peak_density_peak_threshold_95 already exists
            file_info = whos('-file', filepath);
            var_names = {file_info.name};
            
            if ismember('amplitude_peak_density_peak_threshold_95', var_names)
                fprintf('Already computed - SKIP\n');
                continue;
            end
            
            % Load required variables
            try
                nodeTpMat = loaded_data.mapper_nodeTpMat;
                amplitude_framewise = loaded_data.amplitude_framewise;
            catch ME
                fprintf('Error loading variables: %s - SKIP\n', ME.message);
                continue;
            end
            
            % Compute peak_density
            peak_density = fcn_edgeMapper_compute_peak_density(nodeTpMat, amplitude_framewise, peak_threshold);
            
            % Save to mat file
            loaded_data.amplitude_peak_density_peak_threshold_95 = peak_density;
            
            fprintf('Computed and saved (size: %s)\n', mat2str(size(peak_density)));
        end
        
        fprintf('\n');
    end
end

fprintf('\n===========================================\n');
fprintf('Peak density computation complete!\n');
fprintf('===========================================\n');