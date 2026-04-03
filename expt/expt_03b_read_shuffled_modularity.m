%% Aggregate shuffled modularity results across subjects

cohorts = "two"; ["one", "two"];
session = "LR";
simplex = "edge";
parcellation = "schaefer100x7";
purity_thresholds = 0.75;
peak_threshold = 0.95;
num_shuffling = 1000;
seed = 0;

config = fcn_utils_get_config();

% Create output directory if it doesn't exist
output_directory = fullfile(config.repo_root, "data_pipeline", "shuffled_modularity");
if ~isfolder(output_directory)
    mkdir(output_directory);
end

% Directory where individual shuffled modularity files are stored
shuffled_modularity_directory = fullfile(config.scratch_dir, "shuffled_modularity");
input_shuffled_modularity_filename = "shuffled_modularity";

peak_density_thresholds = [0.8, 0.9, 0.95];

for cohort = cohorts

    if strcmp(cohort, "one")
        cohort_storage = "one";
    else
        cohort_storage = "all_but_one";
    end

    for purity_threshold = purity_thresholds
        
        % Get subject list
        cohort_csv = fullfile(config.repo_root, "data_pipeline", "data_cohort", ...
            sprintf("cohort_%s_session_%s.csv", cohort, session));
        subjects_table = readtable(cohort_csv, 'VariableNamingRule', 'preserve');
        num_subjects = height(subjects_table);
        
        % Get "none" (original modularity) values
        modularity_none_filename = fullfile(config.repo_root, "data_pipeline", ...
            sprintf("simplex_mapper_raw_features_cohort_%s_%s_%s_%s", ...
            cohort_storage, session, simplex, parcellation), "summary_raw.csv");
        modularity_none_table = readtable(modularity_none_filename, 'VariableNamingRule', 'preserve');
        
        % Create base table with Subject and none columns
        result_table = join(subjects_table(:, "Subject"), ...
            modularity_none_table(:, ["subject", "mapper_stat_modularity"]), ...
            'LeftKeys', 'Subject', 'RightKeys', 'subject');
        result_table.Properties.VariableNames{'mapper_stat_modularity'} = 'none';
        
        % Preallocate columns
        result_table.all = nan(num_subjects, 1);
        
        for peak_density_threshold = peak_density_thresholds
            density_suffix = sprintf('_%d', round(100*peak_density_threshold));
            result_table.(sprintf('peak_dense%s', density_suffix)) = nan(num_subjects, 1);
            result_table.(sprintf('matched_random%s', density_suffix)) = nan(num_subjects, 1);
        end
        
        % Process each peak density threshold
        for peak_density_threshold = peak_density_thresholds
            
            % Determine if this threshold has "all" column
            if abs(peak_density_threshold - 0.9) < 0.01
                has_all_column = true;
            else
                has_all_column = false;
            end
            
            % Determine column names based on peak density threshold
            density_suffix = sprintf('_%d', round(100*peak_density_threshold));
            peak_dense_col = sprintf('peak_dense%s', density_suffix);
            matched_random_col = sprintf('matched_random%s', density_suffix);
            peak_dense_na_col = sprintf('peak_dense_num_na%s', density_suffix);
            matched_random_na_col = sprintf('matched_random_num_na%s', density_suffix);
            
            % Loop through subjects and read individual files
            for subject_idx = 1:num_subjects
                subject = subjects_table.Subject(subject_idx);
                
                % Build filename suffix
                suffix = sprintf('%s_%d_%s_%s_peak_%d_density_%d_purity_%d_num_shuffling_%d_seed_%d', ...
                    simplex, subject, session, parcellation, ...
                    round(100*peak_threshold), round(100*peak_density_threshold), ...
                    round(100*purity_threshold), num_shuffling, seed);
                
                % Full filename
                shuffled_file = fullfile(shuffled_modularity_directory, ...
                    sprintf("%s_%s.csv", input_shuffled_modularity_filename, suffix));
                
                % Read file and compute means
                if isfile(shuffled_file)
                    shuffled_data = readtable(shuffled_file, 'VariableNamingRule', 'preserve');
                    
                    if has_all_column
                        result_table.all(subject_idx) = mean(shuffled_data.all, 'omitnan');
                    end
                    result_table.(peak_dense_na_col)(subject_idx) = sum(isnan(shuffled_data.peak_dense_pure_nodes));
                    result_table.(matched_random_na_col)(subject_idx) = sum(isnan(shuffled_data.matched_random_nodes, 'omitnan'));                    
                    result_table.(peak_dense_col)(subject_idx) = mean(shuffled_data.peak_dense_pure_nodes, 'omitnan');
                    result_table.(matched_random_col)(subject_idx) = mean(shuffled_data.matched_random_nodes, 'omitnan');
                else
                    warning('File not found: %s', shuffled_file);
                end

                fprintf("cohort: %s, purity threshold: %.2f, peak density threshold: %.2f, subject %d (%d/%d)\n", cohort, purity_threshold, peak_density_threshold, subject, subject_idx, num_subjects);
            end
        end
        
        % Save output file
        output_filename = sprintf('shuffled_modularity_mean_%s_%s_peak_%d_purity_%d.csv', ...
            cohort, session, round(100*peak_threshold), round(100*purity_threshold));
        output_full_path = fullfile(output_directory, output_filename);
        writetable(result_table, output_full_path);
        
        fprintf('Saved: %s\n', output_full_path);
    end
end