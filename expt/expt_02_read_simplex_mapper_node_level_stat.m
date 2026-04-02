%% Extract Node-Level Features from Mapper Output
% Extract node-level features from Mapper analysis results for all subjects

%% Configuration

config = fcn_utils_get_config();
parcellation = "schaefer100x7";
simplices = ["node", "edge"];
cohorts = ["one", "two"];  % cohort two is in 'all_but_one'
sessions = ["LR", "RL"];
output_directory = fullfile(config.repo_root, "data_pipeline", "mapper_node_features");
if ~exist(output_directory, "dir")
    mkdir(output_directory);
end


% Feature fields to extract
feature_fields = [
    "amplitude_nodewise", ...
    "mapper_stat_node_purity", ...
    "mapper_stat_mode_task_indices", ...
    "mapper_stat_within_task_centrallity"
    ];

for simplex_idx = 1:numel(simplices)
    simplex = simplices(simplex_idx);
    %% Process each cohort and session
    for cohort_idx = 1:numel(cohorts)
        cohort = cohorts(cohort_idx);

        % Determine cohort name for output file
        if strcmp(cohort, "two")
            cohort_data_storage = "all_but_one";
        else
            cohort_data_storage = cohort;
        end

        for session_idx = 1:numel(sessions)
            session = sessions(session_idx);

            fprintf("\n=== Processing cohort %s, session %s ===\n", cohort, session);

            %% Load cohort subject list
            cohort_filename = fullfile(config.repo_root, "data_pipeline", "data_cohort", ...
                sprintf("cohort_%s_session_%s.csv", cohort, session));
            cohort_table = readtable(cohort_filename, "VariableNamingRule", "preserve");
            subjects = cohort_table.Subject;

            fprintf("Found %d subjects in cohort\n", numel(subjects));

            %% Initialize output table
            output_table = table();

            %% Data directory
            data_directory = fullfile(config.scratch_dir, ...
                sprintf("simplex_mapper_raw_features_cohort_%s_%s_%s_%s\n", ...
                cohort_data_storage, session, simplex, parcellation));

            if ~exist(data_directory, "dir")
                warning("Data directory does not exist: %s", data_directory);
                continue;
            end

            output_filename = sprintf("mapper_node_features_%s_%s_%s.csv", simplex, cohort, session);

            %% Process each subject
            for subject_idx = 1:numel(subjects)
                subject = subjects(subject_idx);

                % Construct data filename
                data_file = fullfile(data_directory, ...
                    sprintf("simplexMapper_%s_%d_%s_%s_data.mat", ...
                    simplex, subject, session, parcellation));

                if ~exist(data_file, "file")
                    warning("Data file not found for subject %d: %s", subject, data_file);
                    continue;
                end

                % Load data using matfile
                try
                    m = matfile(data_file);

                    % Extract features
                    amplitude_nodewise = m.amplitude_nodewise;
                    mapper_stat_node_purity = m.mapper_stat_node_purity;
                    mapper_stat_mode_task_indices = m.mapper_stat_mode_task_indices;
                    mapper_stat_within_task_centrallity = m.mapper_stat_within_task_centrallity;

                    % Get number of nodes
                    num_nodes = numel(amplitude_nodewise);

                    % Create subject_node identifiers
                    subject_node = strings(num_nodes, 1);
                    for node_idx = 1:num_nodes
                        subject_node(node_idx) = sprintf("%d_%03d", subject, node_idx);
                    end

                    % Create table for this subject
                    subject_table = table(...
                        subject_node, ...
                        repmat(subject, num_nodes, 1), ...
                        (1:num_nodes)', ...
                        amplitude_nodewise(:), ...
                        mapper_stat_node_purity(:), ...
                        mapper_stat_mode_task_indices(:), ...
                        mapper_stat_within_task_centrallity(:), ...
                        'VariableNames', ["subject_node", "subject", "node", ...
                        "amplitude_nodewise", "mapper_stat_node_purity", ...
                        "mapper_stat_mode_task_indices", "mapper_stat_within_task_centrallity"]);

                    % Append to output table
                    output_table = [output_table; subject_table];

                    fprintf("Processed subject %d (%d/%d), %d nodes\n", ...
                        subject, subject_idx, numel(subjects), num_nodes);

                    % Save every 20 subjects
                    if mod(subject_idx, 20) == 0 || subject_idx == numel(subjects)

                        writetable(output_table, fullfile(output_directory, output_filename));
                        fprintf("Saved intermediate results (%d subjects processed) to: %s\n", ...
                            subject_idx, fullfile(output_directory, output_filename));
                    end

                catch ME
                    warning("Error processing subject %d: %s", subject, ME.message);
                    continue;
                end
            end

            %% Final save

            writetable(output_table, fullfile(output_directory, output_filename));
            fprintf("\nFinal save complete: %s\n", fullfile(output_directory, output_filename));
            fprintf("Total rows: %d\n", height(output_table));
        end
    end
end
fprintf("\n=== All processing complete ===\n");