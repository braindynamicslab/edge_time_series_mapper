config = fcn_utils_get_config();

output_directory = fullfile(config.repo_root, "data_pipeline", "brain_behavior_correlation_raw");
output_gitignore_directory = fullfile(config.repo_root, "data_pipeline_gitignore", "brain_behavior_correlation_raw");
if ~isfolder(output_directory)
    mkdir(output_directory);
end
if ~isfolder(output_gitignore_directory)
    mkdir(output_gitignore_directory);
end

cohorts = ["one", "all"];
session = "both";
modularity_prefixes = ["node", "edge", "triangle"];
parcellation = "schaefer100x7";
feature_processing = "raw_features";

response_variables = [...
    "NEOFAC_A", ...
    "NEOFAC_O", ...
    "NEOFAC_C", ...
    "NEOFAC_N", ...
    "NEOFAC_E", ...
    "ASR_Intn_T", ...
    "ASR_Extn_T", ...
    "PMAT24_A_CR"
    ];

control_types = ["none", "demographics", "headMotion", "demographics_headMotion", "headMotion_family"];

control_variables_fixed_cell = {...
    []; ...
    ["Age_in_Yrs", "is_female"]; ...
    ["MeanHeadMotion"]; ...
    ["Age_in_Yrs", "is_female", "MeanHeadMotion"];
    };

verbose_flag = 1;
for cohort = cohorts
    for modularity_prefix = modularity_prefixes
        for response_variable = response_variables
            for control_type_idx = 1:numel(control_types)
                control_type = control_types(control_type_idx);
                control_variables_fixed = get_control_variables_fixed(control_type);
                control_variables_random = get_control_variables_random(control_type, cohort);
                [stats, data_table] = fcn_brainBehavior_lme_modularity_predicts_behavior(feature_processing, cohort, session, parcellation, modularity_prefix, response_variable, control_variables_fixed, control_variables_random, config, verbose_flag);
                output_filename = sprintf("stats_%s_%s_%s_%s_%s_predicts_%s_controlledby_%s", feature_processing, cohort, session, parcellation, modularity_prefix, response_variable, control_type);
                save(fullfile(output_directory, output_filename), "stats");
                writetable(data_table, fullfile(output_directory, strcat(output_filename, ".csv")));
            end
        end
    end
end


function control_variables_fixed = get_control_variables_fixed(control_type)
    if strcmp(control_type, "none")
        control_variables_fixed = [];
    elseif strcmp(control_type, "demographics")
        control_variables_fixed = ["Age_in_Yrs", "is_female"];
    elseif strcmp(control_type, "headMotion") || strcmp(control_type, "headMotion_family")
        control_variables_fixed = ["MeanHeadMotion"];
    elseif strcmp(control_type, "demographics_headMotion")
        control_variables_fixed = ["Age_in_Yrs", "is_female", "MeanHeadMotion"];
    end

end

function control_variables_random = get_control_variables_random(control_type, cohort)
    if ismember(control_type, ["demographics", "demographics_headMotion", "headMotion_family"]) && strcmp(cohort, "all")
        control_variables_random = ["Family_ID"];
    else
        control_variables_random = [];
    end

end

fprintf("Data saved. Run expt_05c.")