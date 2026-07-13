%% Brain-Behavior Correlation Analysis - Table Generation (postreview)
% Generates statistical tables for brain modularity predicting behavioral
% outcomes, using per-covariate feature selection.
%
% Postreview design (differs from expt_05c_brain_behavior_correlation_stat.m):
%   1. Discovery is run in cohort one over ALL responses under TWO covariate
%      conditions: "none" and "headMotion".
%   2. BH-FDR is applied SEPARATELY for each covariate, so the surviving
%      feature set is covariate-specific (S_none may differ from S_headMotion).
%   3. Confirmation is run in cohorts one, two, and all, using each covariate's
%      OWN surviving feature set. Cohort all swaps plain "headMotion" for
%      "headMotion_family" (adds a (1 | Family_ID) random intercept) while
%      reusing the "headMotion" selection.
%
% Inputs are the per-model coefficient files written by expt_05b (postreview),
% stored in data_pipeline/brain_behavior_correlation_raw/.
%
% Outputs (data_pipeline/brain_behavior_correlation/):
%   - brain_behavior_corr_stats_postreview_cohort_one_all_features_discovery.csv
%   - brain_behavior_corr_stats_postreview_cohort_<cohort>_select_features.csv
%   - selected_features_postreview.mat  (feature selection consumed by expt_05f)

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

% Covariate conditions used at the discovery stage (cohort one, all features)
discovery_cohort = "one";
discovery_controls = ["none", "headMotion"];

% Confirmation stage: one row per (cohort, fitted covariate). selection_key
% names the discovery covariate whose surviving feature set is reused here.
confirmation_cohorts    = ["one", "one",        "two", "two",        "all", "all"];
confirmation_controls   = ["none", "headMotion", "none", "headMotion", "none", "headMotion_family"];
confirmation_selections = ["none", "headMotion", "none", "headMotion", "none", "headMotion"];

%% Discovery: cohort one, all features, per-covariate FDR
fprintf("\n%s\n", repmat('=', 1, 70));
fprintf("Discovery: cohort %s, all responses, controls [%s]\n", ...
    discovery_cohort, strjoin(discovery_controls, ", "));
fprintf("%s\n\n", repmat('=', 1, 70));

get_all_responses = @(simplex, control) response_variables;
discovery_results = build_results_table(input_directory, discovery_cohort, ...
    discovery_controls, simplices, get_all_responses, feature_processing, ...
    session, parcellation, var_dict);
discovery_results = apply_fdr_correction(discovery_results);

discovery_file = fullfile(output_directory, ...
    "brain_behavior_corr_stats_postreview_cohort_one_all_features_discovery.csv");
writetable(discovery_results, discovery_file);
fprintf("Discovery table saved to: %s (%d rows)\n\n", discovery_file, height(discovery_results));

%% Extract covariate-specific selected features (Twist 1)
% selected_features.<control>.<simplex> holds the surviving response codes.
selected_features = struct();
for control = discovery_controls
    control_display = get_display_name(var_dict, "control", control);
    control_rows = discovery_results(strcmp(string(discovery_results.("Control Type")), control_display), :);

    [node_vars, edge_vars, triangle_vars] = fcn_stat_extract_significant_variables(control_rows, var_dict);
    selected_features.(control).node = node_vars;
    selected_features.(control).edge = edge_vars;
    selected_features.(control).triangle = triangle_vars;

    fprintf("Selected features under control '%s':\n", control);
    fprintf("  Node: %s\n", strjoin(node_vars, ", "));
    fprintf("  Edge: %s\n", strjoin(edge_vars, ", "));
    fprintf("  Triangle: %s\n\n", strjoin(triangle_vars, ", "));
end

selection_file = fullfile(output_directory, "selected_features_postreview.mat");
save(selection_file, "selected_features", "-v7.3");
fprintf("Feature selection saved to: %s\n\n", selection_file);

%% Confirmation: cohorts one, two, all, using covariate-specific selections
confirmation_cohorts_unique = unique(confirmation_cohorts, "stable");

for cohort = confirmation_cohorts_unique
    fprintf("\n%s\n", repmat('=', 1, 70));
    fprintf("Confirmation: cohort %s\n", cohort);
    fprintf("%s\n\n", repmat('=', 1, 70));

    % Covariates fitted for this cohort (in confirmation order)
    cohort_mask = strcmp(confirmation_cohorts, cohort);
    cohort_controls = confirmation_controls(cohort_mask);
    cohort_selections = confirmation_selections(cohort_mask);

    % Closure: response set depends on simplex AND the covariate's selection key
    get_selected_responses = @(simplex, control) ...
        selected_features.(selection_key_for(control, cohort_controls, cohort_selections)).(simplex);

    confirmation_results = build_results_table(input_directory, cohort, ...
        cohort_controls, simplices, get_selected_responses, feature_processing, ...
        session, parcellation, var_dict);
    confirmation_results = apply_fdr_correction(confirmation_results);

    confirmation_file = fullfile(output_directory, ...
        sprintf("brain_behavior_corr_stats_postreview_cohort_%s_select_features.csv", cohort));
    writetable(confirmation_results, confirmation_file);
    fprintf("Confirmation table saved to: %s (%d rows)\n", confirmation_file, height(confirmation_results));
end

fprintf("\n%s\nTABLE GENERATION COMPLETE\n%s\n\n", repmat('=', 1, 70), repmat('=', 1, 70));

%% Helper Functions

function selection_key = selection_key_for(control, cohort_controls, cohort_selections)
    % Map a fitted covariate to the discovery covariate providing its features
    idx = find(strcmp(cohort_controls, control), 1);
    selection_key = cohort_selections(idx);
end

function results_table = build_results_table(input_directory, cohort, controls, ...
        simplices, get_responses, feature_processing, session, parcellation, var_dict)
    % Read per-model coefficient files and assemble a results table.
    %
    % get_responses is a handle @(simplex, control) -> string array of response
    % codes to include for that simplex/covariate combination.

    simplex_display_list = strings(0, 1);
    response_display_list = strings(0, 1);
    control_display_list = strings(0, 1);
    estimate_list = [];
    standard_error_list = [];
    df_list = [];
    t_statistic_list = [];
    p_value_two_tail_list = [];
    p_value_one_tail_list = [];
    significant_two_tail_list = {};
    significant_one_tail_list = {};

    for simplex = simplices
        predictor = sprintf("%s_%s_modularity", session, simplex);
        featureMassaging = get_featureMassaging_from_modularity_prefix(simplex, feature_processing);

        for control = controls
            response_codes = get_responses(simplex, control);
            if isempty(response_codes)
                warning("No response variables selected for simplex '%s', control '%s'. Skipping.", ...
                    simplex, control);
                continue;
            end
            % Force a row vector so the loop iterates per response (extractor
            % returns a column, over which `for` would iterate only once).
            response_codes = reshape(string(response_codes), 1, []);

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
                p_value_one_tail = p_value_two_tail / 2;

                simplex_display_list = [simplex_display_list; get_display_name(var_dict, "modularity", simplex)];
                response_display_list = [response_display_list; get_display_name(var_dict, "response", response_variable)];
                control_display_list = [control_display_list; get_display_name(var_dict, "control", control)];
                estimate_list = [estimate_list; stats.Estimate(row_idx)];
                standard_error_list = [standard_error_list; stats.SE(row_idx)];
                df_list = [df_list; stats.DF(row_idx)];
                t_statistic_list = [t_statistic_list; stats.tStat(row_idx)];
                p_value_two_tail_list = [p_value_two_tail_list; p_value_two_tail];
                p_value_one_tail_list = [p_value_one_tail_list; p_value_one_tail];
                significant_two_tail_list = [significant_two_tail_list; {fcn_stat_get_significance_asterisks(p_value_two_tail)}];
                significant_one_tail_list = [significant_one_tail_list; {fcn_stat_get_significance_asterisks(p_value_one_tail)}];
            end
        end
    end

    results_table = table(...
        simplex_display_list, response_display_list, control_display_list, ...
        estimate_list, standard_error_list, df_list, t_statistic_list, ...
        'VariableNames', {'Simplex', 'Response Variable', 'Control Type', ...
            'Estimate', 'Standard Error', 'DF', 't-statistic'});

    % Both tails are always emitted; discovery uses the two-tailed columns for
    % selection, confirmation reports both.
    results_table.("p-value (two-tail)") = p_value_two_tail_list;
    results_table.("Significance (two-tail)") = significant_two_tail_list;
    results_table.("p-value (one-tail)") = p_value_one_tail_list;
    results_table.("Significance (one-tail)") = significant_one_tail_list;

    results_table = format_numeric_columns(results_table);
end

function tbl = format_numeric_columns(tbl)
    numeric_cols = {'Estimate', 'Standard Error', 'DF', 't-statistic', ...
        'p-value (two-tail)', 'p-value (one-tail)'};

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
    % Apply BH-FDR correction within simplex x control x tail families

    unique_simplices = unique(results_table.Simplex);
    unique_controls = unique(results_table.("Control Type"));

    has_two_tail = ismember("p-value (two-tail)", results_table.Properties.VariableNames);
    has_one_tail = ismember("p-value (one-tail)", results_table.Properties.VariableNames);

    if has_two_tail
        results_table.("p-value (two-tail, BH corrected)") = nan(height(results_table), 1);
        results_table.("Significance (two-tail, BH corrected)") = cell(height(results_table), 1);
    end

    if has_one_tail
        results_table.("p-value (one-tail, BH corrected)") = nan(height(results_table), 1);
        results_table.("Significance (one-tail, BH corrected)") = cell(height(results_table), 1);
    end

    for s = 1:numel(unique_simplices)
        for c = 1:numel(unique_controls)
            idx = strcmp(results_table.Simplex, unique_simplices(s)) & ...
                  strcmp(results_table.("Control Type"), unique_controls(c));

            if ~any(idx)
                continue;
            end

            if has_two_tail
                p_values = results_table.("p-value (two-tail)")(idx);
                p_adjusted = mafdr(p_values, 'BHFDR', true);
                results_table.("p-value (two-tail, BH corrected)")(idx) = p_adjusted;
                results_table.("Significance (two-tail, BH corrected)")(idx) = ...
                    cellfun(@fcn_stat_get_significance_asterisks, num2cell(p_adjusted), 'UniformOutput', false);
            end

            if has_one_tail
                p_values = results_table.("p-value (one-tail)")(idx);
                p_adjusted = mafdr(p_values, 'BHFDR', true);
                results_table.("p-value (one-tail, BH corrected)")(idx) = p_adjusted;
                results_table.("Significance (one-tail, BH corrected)")(idx) = ...
                    cellfun(@fcn_stat_get_significance_asterisks, num2cell(p_adjusted), 'UniformOutput', false);
            end
        end
    end
end
