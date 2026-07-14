%% Brain-Behavior Correlation - Confidence-Interval Plots (postreview)
% Companion to expt_05c_brain_behavior_correlation_stat_postreview.m.
%
% Overlay design (back toward the original): a single no-covariate feature
% selection means all covariates share one x-axis, so the covariate conditions
% are overlaid within each panel as offset markers (not separate plots).
%
% Panels (two-tailed only):
%   Discovery  - cohort one, all responses, control "none", one plot per simplex.
%   Confirm    - one figure per cohort x simplex, overlaying the cohort's two
%                covariates on the selected responses:
%                  cohort one : none, headMotion
%                  cohort two : none, headMotion
%                  cohort all : none, headMotion_family
%
% The head-motion marker is kept consistent with the original figures (square),
% skipping the now-unused demographics marker slot; cohort all's head-motion
% condition additionally carries a (1 | Family_ID) random intercept.
%
% Reads:
%   - selected_features_postreview.mat  (from expt_05c postreview)
%   - per-model coefficient files in brain_behavior_correlation_raw/

clear; clc; close all;

%% Paths
config = fcn_utils_get_config();
data_dir = fullfile(config.repo_root, "data_pipeline", "brain_behavior_correlation_raw");
output_dir = fullfile(config.repo_root, "data_pipeline", "plot_brain_behavior_correlation_postreview");
if ~isfolder(output_dir)
    mkdir(output_dir);
end
var_dict = config.var_dict;

%% Global settings
parcellation = "schaefer100x7";
session = "both";
simplices = ["node", "edge", "triangle"];
y_lim = [-0.35 0.35];

% Covariate marker styling (consistent with the original: none = circle,
% head motion = square; the demographics '^' slot is intentionally skipped).
control_marker_map = struct('none', 'o', 'headMotion', 's', 'headMotion_family', 's');
control_face_map = struct('none', 'k', 'headMotion', 'k', 'headMotion_family', 'k');

%% All responses (discovery): Big Five (5) | ASR (2) | PMAT (1)
response_codes_all = [...
    "NEOFAC_C", "NEOFAC_N", "NEOFAC_A", "NEOFAC_O", "NEOFAC_E", ...
    "ASR_Extn_T", "ASR_Intn_T", "PMAT24_A_CR"];
response_labels_all = arrayfun(@(code) get_display_name(var_dict, "response", code), response_codes_all);
bounds_all = compute_partition_bounds(response_codes_all);

%% Load the single feature selection from the stat script
selection_file = fullfile(config.repo_root, "data_pipeline", "brain_behavior_correlation", ...
    "selected_features_postreview.mat");
if ~isfile(selection_file)
    error("Feature selection not found:\n%s\nRun expt_05c (postreview) first.", selection_file);
end
loaded_selection = load(selection_file);
selected_features = loaded_selection.selected_features;

%% Shared covariate legend (none, head motion)
legend_labels = {'none', 'Mean head motion'};
legend_markers = {'o', 's'};
legend_faces = {'k', 'k'};
fig_legend = create_control_legend(legend_labels, legend_markers, legend_faces);

%% Discovery panels: cohort one, all responses, control none (2-tailed)
discovery_cohort = "one";
discovery_control = "none";

for simplex = simplices
    [beta, lower, upper] = load_ci_two_tailed_single(...
        data_dir, parcellation, simplex, discovery_cohort, session, response_codes_all, discovery_control);

    fig = new_ci_figure();
    ax = new_ci_axes(fig);
    plot_ci_single(ax, beta, lower, upper, response_labels_all, bounds_all, y_lim);

    ylabel(ax, sprintf("Linear Coefficient of %s Modularity", capitalize(simplex)));
    title(ax, sprintf("%s, cohort %s (2-tailed), control: none (ALL responses)", simplex, discovery_cohort), ...
        'FontWeight', 'normal');

    export_ci_figure(fig, output_dir, simplex, discovery_cohort, session, parcellation, 2, "all", discovery_control);
end

%% Confirmation panels: one figure per cohort x simplex, covariates overlaid
confirmation_cohorts = ["one", "two", "all"];
confirmation_controls_by_cohort = {...
    ["none", "headMotion"]; ...        % one
    ["none", "headMotion"]; ...        % two
    ["none", "headMotion_family"]};    % all

for cohort_idx = 1:numel(confirmation_cohorts)
    cohort = confirmation_cohorts(cohort_idx);
    controls = confirmation_controls_by_cohort{cohort_idx};

    control_labels = arrayfun(@(control) get_display_name(var_dict, "control", control), controls);
    markers = arrayfun(@(control) string(control_marker_map.(control)), controls);
    face_colors = arrayfun(@(control) string(control_face_map.(control)), controls);

    for simplex = simplices
        response_codes = selected_features.(simplex);
        if isempty(response_codes)
            warning("No selected features for simplex '%s'. Skipping.", simplex);
            continue;
        end
        response_codes = reshape(string(response_codes), 1, []);
        response_labels = arrayfun(@(code) get_display_name(var_dict, "response", code), response_codes);
        bounds = compute_partition_bounds(response_codes);

        [beta, lower, upper] = load_ci_two_tailed_multi(...
            data_dir, parcellation, simplex, cohort, session, response_codes, controls);

        fig = new_ci_figure();
        ax = new_ci_axes(fig);
        plot_ci_multi(ax, beta, lower, upper, response_labels, control_labels, bounds, y_lim, markers, face_colors);

        ylabel(ax, sprintf("Linear Coefficient of %s Modularity", capitalize(simplex)));
        title(ax, sprintf("%s, cohort %s (2-tailed), covariates overlaid (SELECT responses)", simplex, cohort), ...
            'FontWeight', 'normal');

        export_ci_figure(fig, output_dir, simplex, cohort, session, parcellation, 2, "select", "all");
    end
end

%% Export legend
set(fig_legend, 'PaperPositionMode', 'auto');
exportgraphics(fig_legend, fullfile(output_dir, "plot_brain_behavior_correlation_legend_controls.pdf"), ...
    'ContentType', 'vector', 'Resolution', 300);
close(fig_legend);

fprintf("Plots saved to: %s\n", output_dir);

%% ============================ FUNCTIONS =================================

function fig = new_ci_figure()
% Invisible so a full run does not accumulate on-screen figures; closed after export.
fig = figure('Units', 'centimeters', 'Position', [2 2 12 14], 'Color', 'w', 'Visible', 'off');
set(fig, 'DefaultAxesFontName', 'Helvetica', ...
    'DefaultAxesFontSize', 10, ...
    'DefaultAxesLineWidth', 1, ...
    'DefaultLineLineWidth', 1.4, ...
    'DefaultLineMarkerSize', 6);
end

function ax = new_ci_axes(fig)
ax = axes('Parent', fig);
ax.Position = [0.12 0.20 0.84 0.74];
end

function export_ci_figure(fig, output_dir, simplex, cohort, session, parcellation, tail, response, control)
set(fig, 'PaperPositionMode', 'auto');
filename = sprintf('plot_brain_behavior_correlation_%s_cohort_%s_session_%s_parcellation_%s_tail_%d_response_%s_control_%s.pdf', ...
    simplex, cohort, session, parcellation, tail, response, control);
exportgraphics(fig, fullfile(output_dir, filename), 'ContentType', 'vector', 'Resolution', 300);
filename_png = strrep(filename, '.pdf', '.png');
exportgraphics(fig, fullfile(output_dir, filename_png), 'Resolution', 300);
close(fig);
end

function name = capitalize(word)
word = char(word);
name = [upper(word(1)), word(2:end)];
end

function fname = build_stats_fname(data_dir, cohort, session, parcellation, simplex, feature, control)
fname = fullfile(data_dir, sprintf( ...
    'stats_raw_features_%s_%s_%s_%s_predicts_%s_controlledby_%s.mat', ...
    cohort, session, parcellation, simplex, feature, control));
end

function row_idx = find_coef_row(stats, coef_name, fname)
names = string(stats.Name);
row_idx = find(names == coef_name, 1);
if isempty(row_idx)
    error('Row "%s" not found in %s', coef_name, fname);
end
end

function [beta, lower, upper] = load_ci_two_tailed_single(data_dir, parcellation, simplex, cohort, session, feats, control)
% Estimate and stored 2-tailed CI for a single covariate condition
[beta_m, lower_m, upper_m] = load_ci_two_tailed_multi(data_dir, parcellation, simplex, cohort, session, feats, control);
beta = beta_m(:, 1);
lower = lower_m(:, 1);
upper = upper_m(:, 1);
end

function [beta, lower, upper] = load_ci_two_tailed_multi(data_dir, parcellation, simplex, cohort, session, feats, controls)
% Estimate and stored 2-tailed CI for one or more covariate conditions
feats = reshape(string(feats), 1, []);
controls = reshape(string(controls), 1, []);
num_features = numel(feats);
num_controls = numel(controls);

beta = nan(num_features, num_controls);
lower = nan(num_features, num_controls);
upper = nan(num_features, num_controls);

coef_name = sprintf("%s_%s_modularity", session, simplex);

for control_idx = 1:num_controls
    for feature_idx = 1:num_features
        fname = build_stats_fname(data_dir, cohort, session, parcellation, simplex, ...
            feats(feature_idx), controls(control_idx));
        if ~isfile(fname)
            error('File not found:\n%s', fname);
        end
        loaded = load(fname);
        if ~isfield(loaded, 'stats')
            error('Variable "stats" not found in %s', fname);
        end
        stats = loaded.stats;
        row_idx = find_coef_row(stats, coef_name, fname);

        beta(feature_idx, control_idx) = stats.Estimate(row_idx);
        lower(feature_idx, control_idx) = stats.Lower(row_idx);
        upper(feature_idx, control_idx) = stats.Upper(row_idx);
    end
end
end

function plot_ci_single(ax, beta, lower, upper, labels, bounds, y_lim)
% Single-covariate error bars (two-tailed)
num_features = numel(beta);
x = (1:num_features)';

xlim(ax, [0.5 num_features + 0.5]);
ylim(ax, y_lim);
hold(ax, 'on');

apply_partition_shading(ax, bounds);

errorbar(ax, x, beta, beta - lower, upper - beta, ...
    'LineStyle', 'none', 'Marker', 'o', 'Color', 'k', 'MarkerFaceColor', 'k', ...
    'CapSize', 3, 'LineWidth', 1.2);

yline(ax, 0, 'k-', 'LineWidth', 0.75);

set(ax, 'XTick', x, 'XTickLabel', labels, ...
    'XTickLabelRotation', 45, 'TickDir', 'out', 'Box', 'off');
end

function plot_ci_multi(ax, beta, lower, upper, labels, control_labels, bounds, y_lim, markers, face_colors)
% Multiple covariate conditions overlaid with horizontal jitter (two-tailed)
[num_features, num_controls] = size(beta);
x0 = (1:num_features)';
offsets = linspace(-0.25, 0.25, num_controls);

xlim(ax, [0.5 num_features + 0.5]);
ylim(ax, y_lim);
hold(ax, 'on');

apply_partition_shading(ax, bounds);

for control_idx = 1:num_controls
    x = x0 + offsets(control_idx);
    beta_c = beta(:, control_idx);
    errorbar(ax, x, beta_c, beta_c - lower(:, control_idx), upper(:, control_idx) - beta_c, ...
        'LineStyle', 'none', ...
        'Marker', char(markers(control_idx)), ...
        'Color', 'k', ...
        'MarkerFaceColor', char(face_colors(control_idx)), ...
        'CapSize', 3, 'LineWidth', 1.0);
end

yline(ax, 0, 'k-', 'LineWidth', 0.75);

set(ax, 'XTick', x0, 'XTickLabel', labels, ...
    'XTickLabelRotation', 45, 'TickDir', 'out', 'Box', 'off');

% No inline legend; use the separate legend figure exported at the end.
end

function apply_partition_shading(ax, bounds)
% Subtle background shading per partition: white -> light gray -> darker gray
yl = ylim(ax);

shade_colors = [1.00 1.00 1.00; 0.96 0.96 0.96; 0.90 0.90 0.90];

for i = 1:(numel(bounds) - 1)
    x1 = bounds(i);
    x2 = bounds(i + 1);
    fc = shade_colors(mod(i - 1, size(shade_colors, 1)) + 1, :);
    p = patch(ax, [x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], fc, ...
        'EdgeColor', 'none', 'FaceAlpha', 1);
    uistack(p, 'bottom');
end

for i = 2:(numel(bounds) - 1)
    x_boundary = bounds(i);
    line(ax, [x_boundary x_boundary], yl, ...
        'Color', [0.75 0.75 0.75], 'LineStyle', '-', 'LineWidth', 0.6);
end
end

function fig_legend = create_control_legend(control_labels, markers, face_colors)
% Separate legend-only figure for the overlaid covariate markers
fig_legend = figure('Units', 'centimeters', 'Position', [2 2 7 5], 'Color', 'w', 'Visible', 'off');
ax_legend = axes('Position', [0 0 1 1], 'Visible', 'off');
hold(ax_legend, 'on');

num_controls = numel(control_labels);
handles = gobjects(1, num_controls);
for control_idx = 1:num_controls
    handles(control_idx) = plot(ax_legend, NaN, NaN, ...
        'LineStyle', 'none', 'Marker', markers{control_idx}, ...
        'Color', 'k', 'MarkerFaceColor', face_colors{control_idx}, 'MarkerSize', 6);
end

legend(ax_legend, handles, control_labels, 'Location', 'west', 'Box', 'off', 'FontSize', 10);
end

function display_name = get_display_name(var_dict, category, raw_value)
field_name = sprintf("%s_%s", category, raw_value);
field_name = strrep(field_name, "-", "_");
if isfield(var_dict, field_name)
    display_name = string(var_dict.(field_name));
else
    display_name = string(raw_value);
end
end

function bounds = compute_partition_bounds(feature_codes)
% Partition bounds by variable type: Personality (NEOFAC_*) | ASR_* | PMAT*
feature_codes = string(feature_codes);
num_personality = sum(startsWith(feature_codes, "NEOFAC"));
num_psychopath = sum(startsWith(feature_codes, "ASR"));
bounds = [0.5, num_personality + 0.5, num_personality + num_psychopath + 0.5, numel(feature_codes) + 0.5];
end
