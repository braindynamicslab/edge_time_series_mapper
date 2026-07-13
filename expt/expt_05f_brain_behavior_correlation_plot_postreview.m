%% Brain-Behavior Correlation - Confidence-Interval Plots (postreview)
% Companion to expt_05c_brain_behavior_correlation_stat_postreview.m.
%
% Produces ONE plot per covariate condition (rather than overlaying covariates
% on a single panel), because the postreview design selects a different feature
% set per covariate, so the conditions no longer share an x-axis.
%
% Panels:
%   Discovery  - cohort one, all responses, two-tailed, one plot per covariate
%                ("none", "headMotion").
%   Confirm    - cohorts one, two, all, covariate-specific selected responses,
%                one plot per covariate x tail. Cohort all uses
%                "headMotion_family" and reuses the "headMotion" selection.
%
% Reads:
%   - selected_features_postreview.mat  (from expt_05c postreview)
%   - per-model coefficient files in brain_behavior_correlation_raw/ (from expt_05b)

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
significance_alpha = 0.05;          % nominal 95% CI
confidence_interval_bound = 3;      % cap infinite one-tailed bounds for internal safety
y_lim = [-0.35 0.35];               % fixed y-scale for all panels

%% All responses (discovery): Big Five (5) | ASR (2) | PMAT (1)
response_codes_all = [...
    "NEOFAC_C", "NEOFAC_N", "NEOFAC_A", "NEOFAC_O", "NEOFAC_E", ...
    "ASR_Extn_T", "ASR_Intn_T", "PMAT24_A_CR"];
response_labels_all = arrayfun(@(code) get_display_name(var_dict, "response", code), ...
    response_codes_all);
bounds_all = compute_partition_bounds(response_codes_all);

%% Load covariate-specific feature selection produced by the stat script
selection_file = fullfile(config.repo_root, "data_pipeline", "brain_behavior_correlation", ...
    "selected_features_postreview.mat");
if ~isfile(selection_file)
    error("Feature selection not found:\n%s\nRun expt_05c (postreview) first.", selection_file);
end
loaded_selection = load(selection_file);
selected_features = loaded_selection.selected_features;

%% Discovery panels: cohort one, all responses, per covariate (2-tailed)
discovery_cohort = "one";
discovery_controls = ["none", "headMotion"];

for control = discovery_controls
    for simplex = simplices
        [beta, lower, upper] = load_ci_two_tailed_single(...
            data_dir, parcellation, simplex, discovery_cohort, session, response_codes_all, control);

        fig = new_ci_figure();
        ax = new_ci_axes(fig);
        plot_ci_single(ax, beta, lower, upper, response_labels_all, bounds_all, y_lim);

        ylabel(ax, sprintf("Linear Coefficient of %s Modularity", capitalize(simplex)));
        title(ax, sprintf("%s, cohort %s (2-tailed), control: %s (ALL responses)", ...
            simplex, discovery_cohort, get_display_name(var_dict, "control", control)), ...
            'FontWeight', 'normal');

        export_ci_figure(fig, output_dir, simplex, discovery_cohort, session, parcellation, ...
            2, "all", control);
    end
end

%% Confirmation panels: cohorts one/two/all, selected responses, per covariate x tail
% Each row: cohort, fitted covariate, selection key (discovery covariate whose
% surviving feature set is reused).
confirmation_cohorts    = ["one", "one",        "two", "two",        "all", "all"];
confirmation_controls   = ["none", "headMotion", "none", "headMotion", "none", "headMotion_family"];
confirmation_selections = ["none", "headMotion", "none", "headMotion", "none", "headMotion"];
tails = [1, 2];

for row = 1:numel(confirmation_cohorts)
    cohort = confirmation_cohorts(row);
    control = confirmation_controls(row);
    selection_key = confirmation_selections(row);

    for simplex = simplices
        response_codes = selected_features.(selection_key).(simplex);
        if isempty(response_codes)
            warning("No selected features for simplex '%s', selection '%s'. Skipping.", ...
                simplex, selection_key);
            continue;
        end
        response_codes = reshape(string(response_codes), 1, []);
        response_labels = arrayfun(@(code) get_display_name(var_dict, "response", code), response_codes);
        bounds = compute_partition_bounds(response_codes);

        for tail = tails
            if tail == 2
                [beta, lower, upper] = load_ci_two_tailed_single(...
                    data_dir, parcellation, simplex, cohort, session, response_codes, control);
                inf_lower = [];
                inf_upper = [];
            else
                [beta, lower, upper, inf_lower, inf_upper] = load_ci_one_tailed_single(...
                    data_dir, parcellation, simplex, cohort, session, response_codes, control, ...
                    significance_alpha, confidence_interval_bound);
            end

            fig = new_ci_figure();
            ax = new_ci_axes(fig);
            plot_ci_single(ax, beta, lower, upper, response_labels, bounds, y_lim, inf_lower, inf_upper);

            ylabel(ax, sprintf("Linear Coefficient of %s Modularity", capitalize(simplex)));
            title(ax, sprintf("%s, cohort %s (%d-tailed), control: %s (SELECT responses)", ...
                simplex, cohort, tail, get_display_name(var_dict, "control", control)), ...
                'FontWeight', 'normal');

            export_ci_figure(fig, output_dir, simplex, cohort, session, parcellation, ...
                tail, "select", control);
        end
    end
end

fprintf("Plots saved to: %s\n", output_dir);

%% ============================ FUNCTIONS =================================

function fig = new_ci_figure()
fig = figure('Units', 'centimeters', 'Position', [2 2 12 14], 'Color', 'w');
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
feats = reshape(string(feats), 1, []);
num_features = numel(feats);

beta = nan(num_features, 1);
lower = nan(num_features, 1);
upper = nan(num_features, 1);

coef_name = sprintf("%s_%s_modularity", session, simplex);

for feature_idx = 1:num_features
    fname = build_stats_fname(data_dir, cohort, session, parcellation, simplex, feats(feature_idx), control);
    if ~isfile(fname)
        error('File not found:\n%s', fname);
    end
    loaded = load(fname);
    if ~isfield(loaded, 'stats')
        error('Variable "stats" not found in %s', fname);
    end
    stats = loaded.stats;
    row_idx = find_coef_row(stats, coef_name, fname);

    beta(feature_idx) = stats.Estimate(row_idx);
    lower(feature_idx) = stats.Lower(row_idx);
    upper(feature_idx) = stats.Upper(row_idx);
end
end

function [beta, lower, upper, inf_lower, inf_upper] = load_ci_one_tailed_single( ...
    data_dir, parcellation, simplex, cohort, session, feats, control, alpha, big_ci)
% Estimate and computed 1-tailed CI for a single covariate condition.
% inf_lower / inf_upper mark which bound was +/-Inf before capping (for ellipses).
feats = reshape(string(feats), 1, []);
num_features = numel(feats);

beta = nan(num_features, 1);
lower = nan(num_features, 1);
upper = nan(num_features, 1);
inf_lower = false(num_features, 1);
inf_upper = false(num_features, 1);

coef_name = sprintf("%s_%s_modularity", session, simplex);

for feature_idx = 1:num_features
    fname = build_stats_fname(data_dir, cohort, session, parcellation, simplex, feats(feature_idx), control);
    if ~isfile(fname)
        error('File not found:\n%s', fname);
    end
    loaded = load(fname);
    if ~isfield(loaded, 'stats')
        error('Variable "stats" not found in %s', fname);
    end
    stats = loaded.stats;
    row_idx = find_coef_row(stats, coef_name, fname);

    est = stats.Estimate(row_idx);
    se = stats.SE(row_idx);
    df = stats.DF(row_idx);

    [lo, up] = fcn_stat_construct_confidence_interval(est, se, df, alpha, 1);

    inf_lower(feature_idx) = isinf(lo);
    inf_upper(feature_idx) = isinf(up);
    if isinf(lo), lo = -big_ci; end
    if isinf(up), up = big_ci; end

    beta(feature_idx) = est;
    lower(feature_idx) = lo;
    upper(feature_idx) = up;
end
end

function plot_ci_single(ax, beta, lower, upper, labels, bounds, y_lim, varargin)
% Single-covariate error bars. Optional inf_lower/inf_upper (nF x 1 logical)
% switch on one-tailed rendering: no cap on the infinite side, vertical
% ellipsis at the axis edge instead.

num_features = numel(beta);
x = (1:num_features)';

use_ellipses = false;
inf_lower = false(num_features, 1);
inf_upper = false(num_features, 1);
if numel(varargin) >= 2 && ~isempty(varargin{1})
    use_ellipses = true;
    inf_lower = logical(varargin{1});
    inf_upper = logical(varargin{2});
end

xlim(ax, [0.5 num_features + 0.5]);
ylim(ax, y_lim);
hold(ax, 'on');

apply_partition_shading(ax, bounds);

% Ellipsis geometry (data units)
y_min = y_lim(1);
y_max = y_lim(2);
y_range = y_max - y_min;
dot_spacing = 0.015 * y_range;
dot_margin = 0.010 * y_range;
y_cap_upper = y_max - (dot_margin + 3 * dot_spacing);
y_cap_lower = y_min + (dot_margin + 3 * dot_spacing);
dot_ys_upper = y_max - dot_margin - dot_spacing * (0:2);
dot_ys_lower = y_min + dot_margin + dot_spacing * (0:2);
ellipsis_marker_size = 8;

lower_plot = lower;
upper_plot = upper;
if use_ellipses
    upper_plot(inf_upper) = y_cap_upper;
    lower_plot(inf_lower) = y_cap_lower;
    cap_size = 0;   % remove caps; finite-side caps drawn manually below
else
    cap_size = 3;
end

err_low = beta - lower_plot;
err_high = upper_plot - beta;

errorbar(ax, x, beta, err_low, err_high, ...
    'LineStyle', 'none', 'Marker', 'o', ...
    'Color', 'k', 'MarkerFaceColor', 'k', ...
    'CapSize', cap_size, 'LineWidth', 1.2);

if use_ellipses
    cap_half_width = cap_half_width_data(ax, 3);
    for k = 1:num_features
        if ~inf_upper(k)
            line(ax, [x(k) - cap_half_width, x(k) + cap_half_width], ...
                [upper_plot(k), upper_plot(k)], 'Color', 'k', 'LineWidth', 1.2);
        end
        if ~inf_lower(k)
            line(ax, [x(k) - cap_half_width, x(k) + cap_half_width], ...
                [lower_plot(k), lower_plot(k)], 'Color', 'k', 'LineWidth', 1.2);
        end
    end

    if any(inf_upper)
        x_up = x(inf_upper);
        for j = 1:numel(dot_ys_upper)
            plot(ax, x_up, dot_ys_upper(j) * ones(size(x_up)), 'k.', ...
                'MarkerSize', ellipsis_marker_size, 'LineStyle', 'none');
        end
    end
    if any(inf_lower)
        x_lo = x(inf_lower);
        for j = 1:numel(dot_ys_lower)
            plot(ax, x_lo, dot_ys_lower(j) * ones(size(x_lo)), 'k.', ...
                'MarkerSize', ellipsis_marker_size, 'LineStyle', 'none');
        end
    end
end

yline(ax, 0, 'k-', 'LineWidth', 0.75);

set(ax, 'XTick', x, 'XTickLabel', labels, ...
    'XTickLabelRotation', 45, 'TickDir', 'out', 'Box', 'off');
end

function half_width = cap_half_width_data(ax, cap_size_points)
% Convert an errorbar CapSize (points) into x-data half-width for this axes
fig = ancestor(ax, 'figure');

old_fig_units = fig.Units;
fig.Units = 'points';
fig_pos_pts = fig.Position;
fig.Units = old_fig_units;

old_ax_units = ax.Units;
ax.Units = 'normalized';
ax_pos_norm = ax.Position;
ax.Units = old_ax_units;

axis_width_pts = fig_pos_pts(3) * ax_pos_norm(3);
x_range = diff(xlim(ax));
half_width = (cap_size_points / 2) * (x_range / axis_width_pts);
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
