%% Brain-Behavior Correlation Analysis - Table Generation Script
% Generates statistical tables for brain modularity predicting behavioral outcomes

%% Setup
config = fcn_utils_get_config();
input_directory = fullfile(config.repo_root, "data_pipeline", "brain_behavior_correlation_raw");
output_directory = fullfile(config.repo_root, "data_pipeline", "brain_behavior_correlation");

if ~isfolder(output_directory)
    mkdir(output_directory);
end

%% Output Filenames - Centralized Location
output_file_table1 = fullfile(output_directory, "brain_behavior_corr_stats_cohort_one_all_features_no_control.csv");
output_file_table2 = fullfile(output_directory, "brain_behavior_corr_stats_cohort_one_select_features_all_controls.csv");
output_file_table3 = fullfile(output_directory, "brain_behavior_corr_stats_cohort_all_select_features_all_controls.csv");

%% Variable Dictionary for Human-Readable Names
var_dict = struct();

% Response variables
var_dict.response_NEOFAC_C = "Conscientiousness";
var_dict.response_NEOFAC_N = "Neuroticism";
var_dict.response_NEOFAC_A = "Agreeableness";
var_dict.response_NEOFAC_O = "Openness";
var_dict.response_NEOFAC_E = "Extraversion";
var_dict.response_ASR_Extn_T = "Externalizing";
var_dict.response_ASR_Intn_T = "Internalizing";
var_dict.response_PMAT24_A_CR = "Fluid Intelligence (PMAT24)";

% Control types
var_dict.control_none = "None";
var_dict.control_demographics = "Demographics";
var_dict.control_headMotion = "Head Motion";
var_dict.control_headMotion_family = "Head Motion + Family";
var_dict.control_demographics_headMotion = "Demographics + Head Motion";

% Modularity levels
var_dict.modularity_node = "Node";
var_dict.modularity_edge = "Edge";
var_dict.modularity_triangle = "Triangle";

% Cohorts
var_dict.cohort_one = "Exploration";
var_dict.cohort_two = "Replication";
var_dict.cohort_all = "Total";

%% Table 1: Cohort One, All Features, No Control
fprintf("\n" + repmat('=', 1, 70) + "\n");
fprintf("Generating Table 1: Cohort One, All NEOFAC + Psychopathology + PMAT, No Control\n");
fprintf(repmat('=', 1, 70) + "\n\n");

table1_config = struct();
table1_config.cohort = "one";
table1_config.session = "both";
table1_config.parcellation = "schaefer100x7";
table1_config.feature_processing = "raw_features";
table1_config.modularity_prefixes = ["node", "edge", "triangle"];
table1_config.control_types = ["none"];
table1_config.tails = [2];
table1_config.response_variables = ["NEOFAC_C", "NEOFAC_N", "NEOFAC_A", "NEOFAC_O", "NEOFAC_E", ...
                                     "ASR_Extn_T", "ASR_Intn_T", "PMAT24_A_CR"];

table1_results = generate_results_table(table1_config, input_directory, var_dict);

% Save Table 1
writetable(table1_results, output_file_table1);
fprintf("Table 1 saved to: %s\n", output_file_table1);
fprintf("Total rows: %d\n\n", height(table1_results));

%% Table 2: Cohort One, Select Features, All Controls, 1-tail and 2-tail
fprintf("\n" + repmat('=', 1, 70) + "\n");
fprintf("Generating Table 2: Cohort One, Select Features, All Controls, 1-tail and 2-tail\n");
fprintf(repmat('=', 1, 70) + "\n\n");

table2_config = struct();
table2_config.cohort = "one";
table2_config.session = "both";
table2_config.parcellation = "schaefer100x7";
table2_config.feature_processing = "raw_features";
table2_config.modularity_prefixes = ["node", "edge", "triangle"];
table2_config.control_types = ["none", "demographics", "headMotion", "headMotion_family", "demographics_headMotion"];
table2_config.tails = [1, 2];
table2_config.response_variables = ["NEOFAC_C", "NEOFAC_N", "NEOFAC_A", "ASR_Extn_T", "ASR_Intn_T", "PMAT24_A_CR"];

table2_results = generate_results_table(table2_config, input_directory, var_dict);

% Save Table 2
writetable(table2_results, output_file_table2);
fprintf("Table 2 saved to: %s\n", output_file_table2);
fprintf("Total rows: %d\n\n", height(table2_results));

%% Table 3: Cohort All, Select Features, All Controls, 1-tail and 2-tail
fprintf("\n" + repmat('=', 1, 70) + "\n");
fprintf("Generating Table 3: Cohort All, Select Features, All Controls, 1-tail and 2-tail\n");
fprintf(repmat('=', 1, 70) + "\n\n");

table3_config = struct();
table3_config.cohort = "all";
table3_config.session = "both";
table3_config.parcellation = "schaefer100x7";
table3_config.feature_processing = "raw_features";
table3_config.modularity_prefixes = ["node", "edge", "triangle"];
table3_config.control_types = ["none", "demographics", "headMotion", "headMotion_family", "demographics_headMotion"];
table3_config.tails = [1, 2];
table3_config.response_variables = ["NEOFAC_C", "NEOFAC_N", "NEOFAC_A", "ASR_Extn_T", "ASR_Intn_T", "PMAT24_A_CR"];

table3_results = generate_results_table(table3_config, input_directory, var_dict);

% Save Table 3
writetable(table3_results, output_file_table3);
fprintf("Table 3 saved to: %s\n", output_file_table3);
fprintf("Total rows: %d\n\n", height(table3_results));

%% Summary
fprintf("\n" + repmat('=', 1, 70) + "\n");
fprintf("=== TABLE GENERATION COMPLETE ===\n");
fprintf(repmat('=', 1, 70) + "\n");
fprintf("Table 1: %d rows\n", height(table1_results));
fprintf("Table 2: %d rows\n", height(table2_results));
fprintf("Table 3: %d rows\n", height(table3_results));
fprintf("Total: %d rows\n", height(table1_results) + height(table2_results) + height(table3_results));
fprintf("\nFiles saved:\n");
fprintf("  %s\n", output_file_table1);
fprintf("  %s\n", output_file_table2);
fprintf("  %s\n", output_file_table3);
fprintf(repmat('=', 1, 70) + "\n\n");

%% Helper Functions

function results_table = generate_results_table(expt_config, input_directory, var_dict)
    % Initialize storage arrays
    simplex_list = [];
    response_variable_list = [];
    control_type_list = [];
    standard_error_list = [];
    estimate_list = [];
    df_list = [];
    t_statistic_list = [];
    p_value_two_tail_list = [];
    p_value_one_tail_list = [];
    significant_two_tail_list = {};
    significant_one_tail_list = {};
    
    % Iterate through all combinations

        for modularity_idx = 1:numel(expt_config.modularity_prefixes)
            modularity_prefix = expt_config.modularity_prefixes(modularity_idx);
            
            for control_idx = 1:numel(expt_config.control_types)
                control_type = expt_config.control_types(control_idx);
                
                for response_idx = 1:numel(expt_config.response_variables)
                    response_variable = expt_config.response_variables(response_idx);
                    
                    % Construct filename
                    featureMassaging = get_featureMassaging_from_modularity_prefix(modularity_prefix, expt_config.feature_processing);
                    data_input_filename = sprintf("stats_%s_%s_%s_%s_%s_predicts_%s_controlledby_%s", ...
                        featureMassaging, expt_config.cohort, expt_config.session, expt_config.parcellation, ...
                        modularity_prefix, response_variable, control_type);
                    
                    % Load statistics
                    try
                        stats = matfile(fullfile(input_directory, data_input_filename)).stats;
                        
                        % Extract statistics (row 2 is the predictor, row 1 is intercept)
                        estimate = stats.Estimate(2);
                        standard_error = stats.SE(2);
                        degree_freedom = stats.DF(2);
                        t_stat = stats.tStat(2);
                        p_value_two_tail = stats.pValue(2);
                        p_value_one_tail = stats.pValue(2) / 2;
                        
                        % Store results with human-readable labels
                        simplex_list = [simplex_list; get_display_name(var_dict, "modularity", modularity_prefix)];
                        response_variable_list = [response_variable_list; get_display_name(var_dict, "response", response_variable)];
                        control_type_list = [control_type_list; get_display_name(var_dict, "control", control_type)];
                        estimate_list = [estimate_list; estimate];
                        standard_error_list = [standard_error_list; standard_error];
                        df_list = [df_list; degree_freedom];
                        t_statistic_list = [t_statistic_list; t_stat];
                        p_value_one_tail_list = [p_value_one_tail_list; p_value_one_tail];
                        p_value_two_tail_list = [p_value_two_tail_list; p_value_two_tail];
                        significant_two_tail_list = [significant_two_tail_list; {fcn_stat_get_significance_asterisks(p_value_two_tail)}];
                        significant_one_tail_list = [significant_one_tail_list; {fcn_stat_get_significance_asterisks(p_value_one_tail)}];
                        
                    catch ME
                        warning("Could not load file: %s\nError: %s", data_input_filename, ME.message);
                        continue;
                    end
                end
            end
        end
    
    % Create table with human-readable column names (spaces instead of underscores)
    results_table = table(...
        simplex_list, ...
        response_variable_list, ...
        control_type_list, ...
        estimate_list, ...
        standard_error_list, ...
        df_list, ...
        t_statistic_list, ...
        'VariableNames', {...
            'Simplex', ...
            'Response Variable', ...
            'Control Type', ...
            'Estimate', ...
            'Standard Error', ...
            'DF', ...
            't-statistic', ...
        });

        if ismember(2, expt_config.tails)
            p_string = "p-value (two-tail)";
            sign_string = "Significance (two-tail)";
            results_table.(p_string) = p_value_two_tail_list;
            results_table.(sign_string) = significant_two_tail_list;
        end

        if ismember(1, expt_config.tails)
            p_string = "p-value (one-tail)";
            sign_string = "Significance (one-tail)";
            results_table.(p_string) = p_value_one_tail_list;
            results_table.(sign_string) = significant_one_tail_list;
        end

        % Format numeric columns
    results_table = format_numeric_columns(results_table);
end

function tbl = format_numeric_columns(tbl)
    numeric_cols = {'Estimate', 'Standard Error', 'DF', 't-statistic', 'p-value (two-tail)', 'p-value (one-tail)'};
    
    for col = numeric_cols
        if ismember(col, tbl.Properties.VariableNames)
            tbl.(col{1}) = round(tbl.(col{1}), 3, 'significant');
        end
    end
end

function display_name = get_display_name(var_dict, category, raw_value)
    field_name = sprintf("%s_%s", category, raw_value);
    field_name = strrep(field_name, "-", "_");
    
    if isfield(var_dict, field_name)
        display_name = var_dict.(field_name);
    else
        display_name = raw_value;
    end
end

function feature_processing = get_featureMassaging_from_modularity_prefix(modularity_prefix, feature_processing)
    if strcmp(feature_processing, "auto")
        if ismember(modularity_prefix, ["node", "edge", "triangle"])
            feature_processing = "raw_features";
        elseif ismember(modularity_prefix, ["linear_hat", "quadratic_naive"])
            feature_processing = "metricTransformed";
        end
    end
end