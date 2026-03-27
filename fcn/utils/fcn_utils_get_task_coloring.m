function cmap = fcn_utils_get_task_coloring(tasks_string)

cmap = [128, 128, 128; % rest
        244, 220, 109; % emotion
        235,  83, 159; % gambling
        197, 223, 235; % language
        121, 181, 210; % motor
         95, 158, 241; % relational
        228, 155,  76; % social
        221, 117,  95; % wm
        ]./255;

task_index_list = ["REST", "EMOTION", "GAMBLING", "LANGUAGE", "MOTOR", "RELATIONAL", "SOCIAL", "WM"];
[~, indices] = ismember(tasks_string, task_index_list);

cmap = cmap(indices, :);

end