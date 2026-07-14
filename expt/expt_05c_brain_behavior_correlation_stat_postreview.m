%% Brain-Behavior Correlation Analysis - Table Generation (postreview)
% Generates statistical tables for brain modularity predicting behavioral
% outcomes, using a single no-covariate feature selection.
%
% Postreview design:
%   1. Selection (discovery) is run once in cohort one over ALL responses with
%      NO covariate ("none"), like the original analysis. BH-FDR gives a single
%      surviving feature set S per simplex.
%   2. That same set S is then confirmed across cohorts and covariates:
%        (cohort one, none), (cohort one, headMotion),
%        (cohort two, none), (cohort two, headMotion),
%        (cohort all, none), (cohort all, headMotion_family).
%      Cohort all swaps plain headMotion for headMotion_family (adds a
%      (1 | Family_ID) random intercept). All reporting is two-tailed.
%
% Inputs are the per-model coefficient files (data_pipeline/brain_behavior_correlation_raw/).
%
% Outputs (data_pipeline/brain_behavior_correlation/):
%   - brain_behavior_corr_stats_postreview_cohort_one_all_features_discovery.csv
%   - brain_behavior_corr_stats_postreview_cohort_<cohort>_select_features.csv
%   - selected_features_postreview.mat  (feature selection consumed by expt_05d)

%% Setup
config = fcn_utils_get_config();
input_directory = fullfile(config.repo_root, "data_pipeline", "brain_behavior_correlation_raw");
output_directory = fullfile(config.repo_root, "data_pipeline", "brain_behavior_correlation");

if ~isfolder(output_directory)
    mkdir(output_directory);
end

var_dict = config.var_dict;

%% Shared settings
session = "both";
parcellation = "schaefer100x7";
feature_processing = "raw_features";
simplices = ["node", "edge", "triangle"];

response_variables = [...
    "NEOFAC_C", "NEOFAC_N", "NEOFAC_A", "NEOFAC_O", "NEOFAC_E", ...
    "ASR_Extn_T", "ASR_Intn_T", "PMAT24_A_CR"];

% Selection stage: cohort one, no covariate
discovery_cohort = "one";
discovery_control = "none";

% Confirmation stage: same selection tested across cohorts and covariates.
confirmation_cohorts = ["one", "two", "all"];
confirmation_controls_by_cohort = {...
    ["none", "headMotion"]; ...        % one
    ["none", "headMotion"]; ...        % two
    ["none", "headMotion_family"]};    % all

%% Discovery: cohort one, all features, no covariate -> single selection
fprintf("\n%s\n", repmat('=', 1, 70));
fprintf("Discovery: cohort %s, all responses, control %s\n", discovery_cohort, discovery_control);
fprintf("%s\n\n", repmat('=', 1, 70));

get_all_responses = @(simplex) response_variables;
discovery_results = build_results_table(input_directory, discovery_cohort, ...
    discovery_control, simplices, get_all_responses, feature_processing, ...
    session, parcellation, var_dict);
discovery_results = apply_fdr_correction(discovery_results);

discovery_file = fullfile(output_directory, ...
    "brain_behavior_corr_stats_postreview_cohort_one_all_features_discovery.csv");
writetable(discovery_results, discovery_file);
fprintf("Discovery table saved to: %s (%d rows)\n\n", discovery_file, height(discovery_results));

%% Extract the single surviving feature set S (per simplex)
[node_vars, edge_vars, triangle_vars] = fcn_stat_extract_significant_variables(discovery_results, var_dict);
selected_features = struct();
selected_features.node = node_vars;
selected_features.edge = edge_vars;
selected_features.triangle = triangle_vars;

fprintf("Selected features (no-covariate FDR):\n");
fprintf("  Node: %s\n", strjoin(node_vars, ", "));
fprintf("  Edge: %s\n", strjoin(edge_vars, ", "));
fprintf("  Triangle: %s\n\n", strjoin(triangle_vars, ", "));

selection_file = fullfile(output_directory, "selected_features_postreview.mat");
save(selection_file, "selected_features", "-v7.3");
fprintf("Feature selection saved to: %s\n\n", selection_file);

%% Confirmation: same S across cohorts and covariates
get_selected_responses = @(simplex) selected_features.(simplex);

for cohort_idx = 1:numel(confirmation_cohorts)
    cohort = confirmation_cohorts(cohort_idx);
    controls = confirmation_controls_by_cohort{cohort_idx};

    fprintf("\n%s\n", repmat('=', 1, 70));
    fprintf("Confirmation: cohort %s, controls [%s]\n", cohort, strjoin(controls, ", "));
    fprintf("%s\n\n", repmat('=', 1, 70));

    confirmation_results = build_results_table(input_directory, cohort, ...
        controls, simplices, get_selected_responses, feature_processing, ...
        session, parcellation, var_dict);
    confirmation_results = apply_fdr_correction(confirmation_results);

    confirmation_file = fullfile(output_directory, ...
        sprintf("brain_behavior_corr_stats_postreview_cohort_%s_select_features.csv", cohort));
    writetable(confirmation_results, confirmation_file);
    fprintf("Confirmation table saved to: %s (%d rows)\n", confirmation_file, height(confirmation_results));
end

fprintf("\n%s\nTABLE GENERATION COMPLETE\n%s\n\n", repmat('=', 1, 70), repmat('=', 1, 70));

%% Helper Functions

function results_table = build_results_table(input_directory, cohort, controls, ...
        simplices, get_responses, feature_processing, session, parcellation, var_dict)
    % Read per-model coefficient files and assemble a two-tailed results table.
    % get_responses is a handle @(simplex) -> string array of response codes.

    simplex_display_list = strings(0, 1);
    response_display_list = strings(0, 1);
    control_display_list = strings(0, 1);
    estimate_list = [];
    standard_error_list = [];
    df_list = [];
    t_statistic_list = [];
    p_value_two_tail_list = [];
    significant_two_tail_list = {};

    for simplex = simplices
        predictor = sprintf("%s_%s_modularity", session, simplex);
        featureMassaging = get_featureMassaging_from_modularity_prefix(simplex, feature_processing);

        response_codes = get_responses(simplex);
        if isempty(response_codes)
            warning("No response variables for simplex '%s'. Skipping.", simplex);
            continue;
        end
        response_codes = reshape(string(response_codes), 1, []);

        for control = controls
            for response_variable = response_codes
                data_input_filename = sprintf("stats_%s_%s_%s_%s_%s_predicts_%s_controlledby_%s", ...
                    featureMassaging, cohort, session, parcellation, simplex, response_variable, control);

                try
                    stats = matfile(fullfile(input_directory, data_input_filename)).stats;
                catch ME
                    warning("Could not load file: %s\nError: %s", data_input_filename, ME.message);
                    continue;
                end

                % Locate the modularity predictor by name (robust to row order)
                row_idx = find(string(stats.Name) == predictor, 1);
                if isempty(row_idx)
                    warning("Predictor '%s' not found in %s. Skipping.", predictor, data_input_filename);
                    continue;
                end

                p_value_two_tail = stats.pValue(row_idx);

                simplex_display_list = [simplex_display_list; get_display_name(var_dict, "modularity", simplex)];
                response_display_list = [response_display_list; get_display_name(var_dict, "response", response_variable)];
                control_display_list = [control_display_list; get_display_name(var_dict, "control", control)];
                estimate_list = [estimate_list; stats.Estimate(row_idx)];
                standard_error_list = [standard_error_list; stats.SE(row_idx)];
                df_list = [df_list; stats.DF(row_idx)];
                t_statistic_list = [t_statistic_list; stats.tStat(row_idx)];
                p_value_two_tail_list = [p_value_two_tail_list; p_value_two_tail];
                significant_two_tail_list = [significant_two_tail_list; {fcn_stat_get_significance_asterisks(p_value_two_tail)}];
            end
        end
    end

    results_table = table(...
        simplex_display_list, response_display_list, control_display_list, ...
        estimate_list, standard_error_list, df_list, t_statistic_list, ...
        'VariableNames', {'Simplex', 'Response Variable', 'Control Type', ...
            'Estimate', 'Standard Error', 'DF', 't-statistic'});

    results_table.("p-value (two-tail)") = p_value_two_tail_list;
    results_table.("Significance (two-tail)") = significant_two_tail_list;

    results_table = format_numeric_columns(results_table);
end

function tbl = format_numeric_columns(tbl)
    numeric_cols = {'Estimate', 'Standard Error', 'DF', 't-statistic', 'p-value (two-tail)'};

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

function results_table = apply_fdr_correction(results_table)
    % Apply BH-FDR (two-tail) within simplex x control families

    unique_simplices = unique(results_table.Simplex);
    unique_controls = unique(results_table.("Control Type"));

    results_table.("p-value (two-tail, BH corrected)") = nan(height(results_table), 1);
    results_table.("Significance (two-tail, BH corrected)") = cell(height(results_table), 1);

    for s = 1:numel(unique_simplices)
        for c = 1:numel(unique_controls)
            idx = strcmp(results_table.Simplex, unique_simplices(s)) & ...
                  strcmp(results_table.("Control Type"), unique_controls(c));

            if ~any(idx)
                continue;
            end

            p_values = results_table.("p-value (two-tail)")(idx);
            p_adjusted = mafdr(p_values, 'BHFDR', true);
            results_table.("p-value (two-tail, BH corrected)")(idx) = p_adjusted;
            results_table.("Significance (two-tail, BH corrected)")(idx) = ...
                cellfun(@fcn_stat_get_significance_asterisks, num2cell(p_adjusted), 'UniformOutput', false);
        end
    end
end
