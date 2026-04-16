config = fcn_utils_get_config();

tasks = ["REST", ...
    "EMOTION", ...
    "GAMBLING", ...
    "LANGUAGE", ...
    "MOTOR", ...
    "RELATIONAL", ...
    "SOCIAL", ...
    "WM"];

% task_configurations = {"WM", "all"};
task_configuration = "WM";
task_configuration = "all_tasks";
subtract_rest_flag = 0;

parcellation = "schaefer100x7";
simplex = "edge";

peak_density_threshold = 0.9;
text_flag = 0;

input_directory = fullfile(config.scratch_dir, "high_amplitude_functional_connectivity");
output_directory = fullfile(config.repo_root, "data_pipeline/high_amplitude_functional_connectivity");
if ~isfolder(output_directory)
    mkdir(output_directory);
end

pretty_row_names = ["Traditional", "Peak Frame", "Peak-Dense-Pure-Node"];
num_notions = numel(pretty_row_names);

read_data_flag = 1;
% read_data_flag = 0;

schaefer100x7_xticks = [1    10    16    24    31    34    38    51    59    67    74    79    81    90];
schaefer100x7_xticklabels = ["L VIS","L SOM","L DAN","L VAN","L LIM/CON","", "L DMN","R VIS","R SOM","R DAN","R VAN","R LIM/CON", "","R DMN"];

cohorts = ["one"];
cohorts = ["one", "two"];
sessions = ["LR"];
% sessions = ["LR", "RL"];
subtract_rest_flag = 1;

for cohort = cohorts
    for session = sessions

        sublist_csv = fullfile(config.repo_root, "data_pipeline", "data_cohort", sprintf("cohort_%s_session_%s.csv", cohort, session));
        subjects = readtable(sublist_csv).Subject;

        if read_data_flag
            cross_subject_FC_cell = cell(numel(tasks), 1);
            cross_subject_FC_cell(:) = {NaN(num_notions, 4950, numel(subjects))}; %4950 = the number of distinct pairs for 100 regions
            for subject_idx = 1:numel(subjects)
                subject = subjects(subject_idx);
                fprintf("%d (%d  out of %d)\n", subject, subject_idx, numel(subjects))
                input_filename = sprintf("high_amplitude_functional_connectivity_%d_%s_%s_%s_data.mat", subject, session, simplex, parcellation);
                high_amplitude_functional_connectivity_data = matfile(fullfile(input_directory, input_filename));
                fieldnames = ["subject_functional_connectivity_cell", "tasks", "row_names", "col_names"];
                no_data_flag = 0;
                for field_idx = 1:numel(fieldnames)
                    fieldname = fieldnames(field_idx);
                    try
                        assignin("base", fieldname, high_amplitude_functional_connectivity_data.(fieldname));
                    catch
                        no_data_flag = 1;
                        continue;
                    end
                end

                for task_idx = 1:numel(tasks)
                    [m,n] = size(subject_functional_connectivity_cell{task_idx});
                    cross_subject_FC_cell{task_idx}(1:m, 1:n, subject_idx) = subject_functional_connectivity_cell{task_idx};
                end
            end
        end

        mean_FC_cell = cell(numel(tasks), 1);
        for task_idx = 1:numel(tasks)
            mean_FC_cell{task_idx} = mean(cross_subject_FC_cell{task_idx}, 3, "omitnan");
        end

        if subtract_rest_flag
            rest_id = find(strcmp(tasks, "REST"));
            mean_rest_FC = mean_FC_cell{rest_id};
            for task_idx = 1:numel(tasks)
                mean_FC_cell{task_idx} = mean_FC_cell{task_idx} - mean_rest_FC;
            end
        end

        color_lim = [-3, 3];

        for FC_type_idx = 1:numel(row_names)

            for task_idx = 1:numel(tasks)
                fig = figure("Position", [0, 0, 500, 500]);
                mean_task_FC_given_type_squareform = fcn_utils_convert_flattenedFC_to_squareformFC(mean_FC_cell{task_idx}(FC_type_idx, :), col_names);
                filename = sprintf("data_high_amp_FC_%s_%s_%s_%s_%d.csv", tasks(task_idx), cohort, session, row_names(FC_type_idx), subtract_rest_flag);
                writematrix(mean_task_FC_given_type_squareform, fullfile(output_directory, filename));
                %mean_task_FC_given_type_squareform = readmatrix(fullfile(output_directory, filename));
                imagesc(mean_task_FC_given_type_squareform)
                clim(color_lim);
                colormap(redblue);
                xline(schaefer100x7_xticks-0.5);
                yline(schaefer100x7_xticks-0.5);
                xticks(schaefer100x7_xticks-0.5);
                yticks(schaefer100x7_xticks-0.5);
                if text_flag
                    title(tasks{task_idx});
                    xticklabels(schaefer100x7_xticklabels);
                    yticklabels(schaefer100x7_xticklabels);
                    hax = findobj(gcf,'type','axes');
                    set(hax, 'FontSize', 8);
                else
                    set(gca, 'XTick', []);
                    set(gca, 'YTick', []);
                end
                filename = sprintf("plot_high_amp_FC_%s_%s_%s_%s_rest_contrast_%d_text_flag_%d.png", tasks(task_idx), cohort, session, row_names(FC_type_idx), subtract_rest_flag, text_flag);
                exportgraphics(fig,fullfile(output_directory, filename));%, ...
                filename = sprintf("plot_high_amp_FC_%s_%s_%s_%s_rest_contrast_%d_text_flag_%d.pdf", tasks(task_idx), cohort, session, row_names(FC_type_idx), subtract_rest_flag, text_flag);
                exportgraphics(fig,fullfile(output_directory, filename));%, ...

            end
            close all
        end

    end

end
