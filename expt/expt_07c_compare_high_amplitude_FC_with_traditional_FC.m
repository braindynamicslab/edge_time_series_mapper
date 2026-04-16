config = fcn_utils_get_config();

input_directory = fullfile(config.scratch_dir, "data_pipeline", "high_amplitude_functional_connectivity");
output_directory = fullfile(config.repo_root, "data_pipeline/high_amplitude_functional_connectivity");
if ~isfolder(output_directory)
    mkdir(output_directory);
end

tasks = ["REST", ...
    "EMOTION", ...
    "GAMBLING", ...
    "LANGUAGE", ...
    "MOTOR", ...
    "RELATIONAL", ...
    "SOCIAL", ...
    "WM"];

parcellation = "schaefer100x7";
simplex = "edge";

selected_rows = [1 3 2];
pretty_row_names = ["Traditional", "Peak Frame", "Peak-Dense-Pure-Node"]; % This corresponds to the original ordering

peak_density_threshold = 0.9;

selection_flag = 1;
read_data_flag = 1;
show_numbers_flag = 1;

save_flag = 1;

% for cohort = ["one"]
%     for session = ["LR"]
for cohort = ["two", "one"]
    for session = ["LR"] %["LR", "RL"]

        sublist_csv = fullfile(config.repo_root, "data_pipeline", "data_cohort", sprintf("cohort_%s_session_%s.csv", cohort, session));
        subjects = readtable(sublist_csv).Subject;

        % subjects = [102311];
        if read_data_flag
            corrs_between_measures_across_tasks = cell(numel(tasks), 1);
            corrs_between_measures_across_tasks(:) = {NaN(numel(pretty_row_names), numel(pretty_row_names), numel(subjects))};
            for subject_idx = 1:numel(subjects)
                subject = subjects(subject_idx);
                fprintf("%d (%d  out of %d)\n", subject, subject_idx, numel(subjects))
                input_data_filename = sprintf("high_amplitude_functional_connectivity_%d_%s_%s_%s_data.mat", subject, session, simplex, parcellation);
                high_amplitude_functional_connectivity_data = matfile(fullfile(input_directory, input_data_filename));
                fieldnames = ["subject_functional_connectivity_cell", "tasks", "row_names", "col_names"];
                no_data_flag = 0;
                for field_id = 1:numel(fieldnames)
                    fieldname = fieldnames(field_id);
                    try
                        assignin("base", fieldname, high_amplitude_functional_connectivity_data.(fieldname));
                    catch
                        no_data_flag = 1;
                        continue;
                    end
                end
                if no_data_flag
                    fprintf("  no data\n");
                    continue;
                end

                for task_id = 1:numel(tasks)
                    task = tasks(task_id);
                    task_corr_mat = corr(subject_functional_connectivity_cell{task_id}');
                    % task_fcs
                    corrs_between_measures_across_tasks{task_id}(1:size(task_corr_mat, 1), 1:size(task_corr_mat, 2), subject_idx) = task_corr_mat;
                end

            end
        end

        mean_corrs_between_measures_across_tasks = cell(numel(tasks), 1);
%         fig_all_info = figure;
        corr_with_FC = nan(numel(pretty_row_names), numel(tasks));
        for task_id = 1:numel(tasks)
            mean_corrs_between_measures_across_tasks{task_id} = mean(corrs_between_measures_across_tasks{task_id}, 3, "omitnan");
            corr_with_FC(:, task_id) = mean_corrs_between_measures_across_tasks{task_id}(:, 1);
            %             subplot(2, 4, task_id);
            %             if selection_flag
            %                 mat = mean_corrs_between_measures_across_tasks{task_id};
            %                 mat = mat(selected_rows, :);
            %                 mat = mat(:, selected_rows);
            %                 imagesc(mat);
            %             else
            %                 imagesc(mean_corrs_between_measures_across_tasks{task_id});
            %             end
            %             clim([0, 1]);
            %             %             colormap(flipud(gray));
            %             colormap("parula");
            %             colorbar;
            %             %             yticks(1:numel(row_names));
            %             %             yticklabels(pretty_row_names);
            %             %             yticks(1:numel(row_names));
            %             %             yticklabels(row_names);
            %
            %             title(sprintf("%s-%s, %s", cohort, session, tasks{task_id}));
            %             filename_all_info = sprintf("cross_measure_corr_%s_%s_selected_rows_%d.png", cohort, session, selection_flag);
            %             if save_flag
            %                 saveas(fig_all_info, fullfile(output_data_directory, filename_all_info));
            %             end
        end

        fig_FC_only = figure;

        if selection_flag
            data_to_plot = corr_with_FC(selected_rows, :);
            %imagesc(corr_with_FC(selected_rows, :));
        else
            data_to_plot = corr_with_FC
            %imagesc(corr_with_FC);
        end
        if show_numbers_flag
            h = heatmap(data_to_plot);
            h.CellLabelFormat = '%.3g';
        else
            imagesc(data_to_plot);
        end
        clim([0, 1]);
        colormap("parula");

        colorbar;
        if show_numbers_flag
            if selection_flag
                h.YDisplayLabels = pretty_row_names(selected_rows);
            else
                h.YDisplayLabels = pretty_row_names;
            end
            h.XDisplayLabels = tasks;
        else
            if selection_flag
                yticks(1:numel(selected_rows));
                yticklabels(pretty_row_names(selected_rows));
            else
                yticks(1:numel(row_names));
                yticklabels(pretty_row_names);
            end
            xticks(1:numel(tasks));
            xticklabels(tasks);
        end
        title(sprintf("%s-%s", cohort, session))
        filename_FC_only = sprintf("plot_cross_measure_corr_with_FC_%s_%s.png", cohort, session);
        if save_flag
            saveas(fig_FC_only, fullfile(output_directory, filename_FC_only));
        end
% 
%         fig_high_amplitude_proportion = figure;
%         mean_high_amp_prop = mean(high_amplitude_proportion, 3, 'omitnan');
%         if selection_flag
%             bar(mean_high_amp_prop(:, 2));
%             xticks(1:numel(tasks));
%             xticklabels(tasks);
%             ylim([0, 0.6]);
%             yline(0.1);
%         else
% 
%             imagesc(mean_high_amp_prop);
%             max(mean_high_amp_prop)
%             clim([0, 1]);
%             %         colormap(flipud(gray));
%             colormap("parula");
%             colorbar;
%             xticks(1:2)
%             xticklabels(proportion_col_names);
%             yticks(1:numel(tasks))
%             yticklabels(tasks);
%         end
%         title(sprintf("%s-%s", cohort, session))
%         filename_high_amplitdue_proprotion = sprintf("prop_timeframes_in_high_amplitude_nodes_%s_%s_selected_rows_%d.png", cohort, session, selection_flag);
%         if save_flag
%             saveas(fig_high_amplitude_proportion, fullfile(output_data_directory, filename_high_amplitdue_proprotion));
%         end

        %         fig_high_amplitude_prop_proportion = figure;

    end
end
