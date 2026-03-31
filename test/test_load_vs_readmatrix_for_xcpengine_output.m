subjects = [
    100206, ...
    236130 ...
    ];

sessions = ["LR", "RL"];

parcellations = ["schaefer100x7", "schaefer200x7"];

% tasks = ["REST", "WM"];
tasks = ["EMOTION"];

config = fcn_utils_get_config();

for subject = subjects
    for parcellation = parcellations
        for session = sessions
            rest_session = strcat(session, "_run-1");
            
            data_readmatrix = fcn_io_load_fmri_data_for_subject(subject, tasks, session, rest_session, parcellation, config, "verbose_flag", 0, "load_method", "readmatrix");

            try
                data_load = fcn_io_load_fmri_data_for_subject(subject, tasks, session, rest_session, parcellation, config, "verbose_flag", 0, "load_method", "load");
            catch
                fprintf("load failed for %d, %s, %s\n", subject, parcellation, session);
                continue;
            end

            for task_idx = 1:numel(tasks)
                task = tasks(task_idx);
                max_error = max(max(data_load{task_idx} - data_readmatrix{task_idx}));
                fprintf("Subject %d, %s, %s, %s, max error: %.3g\n", subject, parcellation, session, task, max_error);
            end
        end
    end
end

