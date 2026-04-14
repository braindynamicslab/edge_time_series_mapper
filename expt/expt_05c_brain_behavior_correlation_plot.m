%% plot_node_edge_triangle_nature_complete.m

clear; clc; close all;

%% --------------------------- USER PATHS ---------------------------------
% Folder with all the stats_raw_features_*.mat files
config = fcn_utils_get_config();
dataDir = fullfile(config.repo_root, "data_pipeline/brain_behavior_correlation_raw");

% Output directory for plots
outputDir = fullfile(config.repo_root, "data_pipeline", "plot_brain_behavior_correlation");
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Folder that contains fcn_utils_construct_confidence_interval.m (no longer
% needed)
% ciDir   = '/Users/saadpirzada/Downloads/brain_behavior_correlation';
% addpath(ciDir);

%% --------------------------- GLOBAL SETTINGS ----------------------------
parcellation = "schaefer100x7";
session = "both";
simplex_list = {'node','edge','triangle'};
significance_alpha = 0.05;      % nominal 95% CI
confidence_interval_bound = 3;         % cap infinite one-tailed bounds for internal safety
y_lim = [-0.35 0.35];  % fixed y-scale for all panels (edit if desired)
include_demo_plus_head_motion_flag = 0;
var_dict = config.var_dict;

if ~include_demo_plus_head_motion_flag
    % Controls / covariates (file suffixes)
    controls      = {'none','demographics','headMotion'};
    controlLabels = {'none','demographics','Mean head motion'};

    % Marker styling for multi-control plots (B/W, Nature-ish)
    markers    = {'o','^','s'};   % none, demo, motion
    faceColors = {'k','k','k'};
else
    controls      = {'none','demographics','headMotion','demographics_headMotion'};
    controlLabels = {'none','demographics','Mean head motion', ...
        'demographics, Mean head motion'};

    % Marker styling for multi-control plots (B/W, Nature-ish)
    markers    = {'o','^','s','d'};   % none, demo, motion, demo+motion
    faceColors = {'k','k','k','w'};   % last one = white diamond
end

% Create ONE legend figure you can export and reuse for all multi-control plots
figLeg_controls = create_control_legend(controlLabels, markers, faceColors);

%% --------------------------- RESPONSES ----------------------------------
% "All responses" set (EXCLUDING TASK ACCURACY MEASURES per request)
featCodes_all = { ...
    'NEOFAC_C','NEOFAC_N','NEOFAC_A','NEOFAC_O','NEOFAC_E', ...
    'ASR_Extn_T','ASR_Intn_T', ...
    'PMAT24_A_CR'};

featLabels_all = { ...
    'Conscientiousness','Neuroticism','Agreeableness','Openness','Extraversion', ...
    'Externalizing','Internalizing', ...
    'Fluid intelligence'};

% Partition bounds for ALL responses:
% Big Five (5) | ASR (2) | PMAT (1)
bounds_all = [0.5, 5.5, 7.5, numel(featCodes_all)+0.5];

% Selected responses (must include Agreeableness)
% featCodes_sel = {'NEOFAC_C','NEOFAC_N','NEOFAC_A','ASR_Extn_T','ASR_Intn_T','PMAT24_A_CR'};
% featLabels_sel = {'Conscientiousness','Neuroticism','Agreeableness', ...
%     'Externalizing','Internalizing','Fluid intelligence (PMAT)'};
% % Partition bounds for SELECTED responses:
% % Personality (C,N,A) | Psychopathology (ASR) | PMAT
% bounds_sel = [0.5, 3.5, 5.5, numel(featCodes_sel)+0.5];

%% ========================================================================
% (A) Cohort ONE (cohort 1), 2-tailed, NO CONTROL, ALL responses
%     -> node, edge, triangle
% ========================================================================
cohortA  = 'one';
controlA = 'none'; % no control
for s = 1:numel(simplex_list)
    simplex = simplex_list{s};

    [betaA, loA, upA] = load_ci_two_tailed_singleControl( ...
        dataDir, parcellation, simplex, cohortA, session, featCodes_all, controlA);

    fig = figure('Units','centimeters','Position',[2 2 12 14],'Color','w');
    apply_figure_defaults(fig);

    ax = axes('Parent',fig);
    ax.Position = [0.12 0.20 0.84 0.74];

    plot_ci_single(ax, betaA, loA, upA, featLabels_all, bounds_all, y_lim);

    ylabel(ax, sprintf('Linear Coefficient of %s Modularity', [upper(simplex(1)), simplex(2:end)]));
    title(ax, sprintf('%s, cohort one (2-tailed), control: none (ALL responses)', simplex), ...
        'FontWeight','normal');

    set(fig, 'PaperPositionMode','auto');

    % Export
    filename = sprintf('plot_brain_behavior_correlation_%s_cohort_%s_session_%s_parcellation_%s_tail_%d_response_%s_control_%s.pdf', ...
        simplex, cohortA, session, parcellation, 2, 'all', 'none');
    exportgraphics(fig, fullfile(outputDir, filename), ...
        'ContentType', 'vector', ...
        'Resolution', 300);
    filename_png = strrep(filename, '.pdf', '.png');
    exportgraphics(fig, fullfile(outputDir, filename_png), ...
        'Resolution', 300);
end

%% Load simplex-specific selected variables from Table 1
table1_file = fullfile(config.repo_root, "data_pipeline", "brain_behavior_correlation", ...
    "brain_behavior_corr_stats_cohort_one_all_features_no_control.csv");

if exist(table1_file, 'file')
    table1_results = readtable(table1_file, 'PreserveVariableNames', true);
    [node_selected, edge_selected, triangle_selected] = fcn_stat_extract_significant_variables(table1_results, var_dict);
    
    fprintf('Simplex-specific selected variables:\n');
    fprintf('  Node: %s\n', strjoin(node_selected, ', '));
    fprintf('  Edge: %s\n', strjoin(edge_selected, ', '));
    fprintf('  Triangle: %s\n', strjoin(triangle_selected, ', '));
else
    error('Table 1 not found. Run table generation script first.');
end

% Convert codes to human-readable labels using var_dict
node_featLabels_selected = cellfun(@(code) get_display_name(var_dict, "response", code), ...
                                   node_selected, 'UniformOutput', false);
edge_featLabels_selected = cellfun(@(code) get_display_name(var_dict, "response", code), ...
                                   edge_selected, 'UniformOutput', false);
triangle_featLabels_selected = cellfun(@(code) get_display_name(var_dict, "response", code), ...
                                       triangle_selected, 'UniformOutput', false);

% Compute partition bounds for background shading
node_bounds_selected = compute_partition_bounds(node_selected);
edge_bounds_selected = compute_partition_bounds(edge_selected);
triangle_bounds_selected = compute_partition_bounds(triangle_selected);

%% ========================================================================
% (B1) Cohort ONE (cohort 1), SELECT responses, ALL controls/covariates
%     -> 2-tailed (stored CI): node, edge, triangle
% ========================================================================
cohortB = 'one';
for s = 1:numel(simplex_list)
    simplex = simplex_list{s};

    switch simplex
        case 'node'
            current_featCodes = node_selected;
            current_featLabels = node_featLabels_selected;
            current_bounds = node_bounds_selected;
        case 'edge'
            current_featCodes = edge_selected;
            current_featLabels = edge_featLabels_selected;
            current_bounds = edge_bounds_selected;
        case 'triangle'
            current_featCodes = triangle_selected;
            current_featLabels = triangle_featLabels_selected;
            current_bounds = triangle_bounds_selected;
    end
    % CHANGED: use current_featCodes instead of featCodes_sel
    [betaB2, loB2, upB2] = load_ci_two_tailed_multiControls( ...
        dataDir, parcellation, simplex, cohortB, session, current_featCodes, controls);

    fig = figure('Units','centimeters','Position',[2 2 12 14],'Color','w');
    apply_figure_defaults(fig);

    ax = axes('Parent',fig);
    ax.Position = [0.12 0.20 0.84 0.74];

    % CHANGED: use current_featLabels and current_bounds
    plot_ci_multi(ax, betaB2, loB2, upB2, current_featLabels, controlLabels, ...
        current_bounds, y_lim, markers, faceColors);

    ylabel(ax, sprintf('Linear Coefficient of %s Modularity', [upper(simplex(1)), simplex(2:end)]));
    title(ax, sprintf('%s, cohort one (2-tailed), ALL controls (SELECT responses)', simplex), ...
        'FontWeight','normal');

    set(fig, 'PaperPositionMode','auto');

    % Export
    filename = sprintf('plot_brain_behavior_correlation_%s_cohort_%s_session_%s_parcellation_%s_tail_%d_response_%s_control_%s.pdf', ...
        simplex, cohortB, session, parcellation, 2, 'select', 'all');
    exportgraphics(fig, fullfile(outputDir, filename), ...
        'ContentType', 'vector', ...
        'Resolution', 300);
    filename_png = strrep(filename, '.pdf', '.png');
    exportgraphics(fig, fullfile(outputDir, filename_png), ...
        'Resolution', 300);
end

%% ========================================================================
% (B2) Cohort ONE (cohort 1), SELECT responses, ALL controls/covariates
%     -> 1-tailed (computed CI): node, edge, triangle
%     (NOW includes ellipses at infinite CI ends; NO cap right before dots)
% ========================================================================
cohortB = 'one';
for s = 1:numel(simplex_list)
    simplex = simplex_list{s};

    switch simplex
        case 'node'
            current_featCodes = node_selected;
            current_featLabels = node_featLabels_selected;
            current_bounds = node_bounds_selected;
        case 'edge'
            current_featCodes = edge_selected;
            current_featLabels = edge_featLabels_selected;
            current_bounds = edge_bounds_selected;
        case 'triangle'
            current_featCodes = triangle_selected;
            current_featLabels = triangle_featLabels_selected;
            current_bounds = triangle_bounds_selected;
    end

    [betaB1, loB1, upB1, infLoB1, infUpB1] = load_ci_one_tailed_multiControls( ...
        dataDir, parcellation, simplex, cohortB, session, current_featCodes, controls, significance_alpha, confidence_interval_bound);

    fig = figure('Units','centimeters','Position',[2 2 12 14],'Color','w');
    apply_figure_defaults(fig);

    ax = axes('Parent',fig);
    ax.Position = [0.12 0.20 0.84 0.74];

    plot_ci_multi(ax, betaB1, loB1, upB1, current_featLabels, controlLabels, ...
        current_bounds, y_lim, markers, faceColors, infLoB1, infUpB1);

    ylabel(ax, sprintf('Linear Coefficient of %s Modularity', [upper(simplex(1)), simplex(2:end)]));
    title(ax, sprintf('%s, cohort one (1-tailed), ALL controls (SELECT responses)', simplex), ...
        'FontWeight','normal');

    set(fig, 'PaperPositionMode','auto');

    % Export
    filename = sprintf('plot_brain_behavior_correlation_%s_cohort_%s_session_%s_parcellation_%s_tail_%d_response_%s_control_%s.pdf', ...
        simplex, cohortB, session, parcellation, 1, 'select', 'all');
    exportgraphics(fig, fullfile(outputDir, filename), ...
        'ContentType', 'vector', ...
        'Resolution', 300);
    filename_png = strrep(filename, '.pdf', '.png');
    exportgraphics(fig, fullfile(outputDir, filename_png), ...
        'Resolution', 300);
end

%% ========================================================================
% (C1) Cohort ALL (everyone), SELECT responses, ALL controls/covariates
%     -> 2-tailed (stored CI): node, edge, triangle
% ========================================================================
cohortC = 'all';
for s = 1:numel(simplex_list)
    simplex = simplex_list{s};

    switch simplex
        case 'node'
            current_featCodes = node_selected;
            current_featLabels = node_featLabels_selected;
            current_bounds = node_bounds_selected;
        case 'edge'
            current_featCodes = edge_selected;
            current_featLabels = edge_featLabels_selected;
            current_bounds = edge_bounds_selected;
        case 'triangle'
            current_featCodes = triangle_selected;
            current_featLabels = triangle_featLabels_selected;
            current_bounds = triangle_bounds_selected;
    end

    [betaC2, loC2, upC2] = load_ci_two_tailed_multiControls( ...
        dataDir, parcellation, simplex, cohortC, session, current_featCodes, controls);

    fig = figure('Units','centimeters','Position',[2 2 12 14],'Color','w');
    apply_figure_defaults(fig);

    ax = axes('Parent',fig);
    ax.Position = [0.12 0.20 0.84 0.74];

    plot_ci_multi(ax, betaC2, loC2, upC2, current_featLabels, controlLabels, ...
        current_bounds, y_lim, markers, faceColors);

    ylabel(ax, sprintf('Linear Coefficient of %s Modularity', [upper(simplex(1)), simplex(2:end)]));
    title(ax, sprintf('%s, cohort all (2-tailed), ALL controls (SELECT responses)', simplex), ...
        'FontWeight','normal');

    set(fig, 'PaperPositionMode','auto');

    % Export
    filename = sprintf('plot_brain_behavior_correlation_%s_cohort_%s_session_%s_parcellation_%s_tail_%d_response_%s_control_%s.pdf', ...
        simplex, cohortC, session, parcellation, 2, 'select', 'all');
    exportgraphics(fig, fullfile(outputDir, filename), ...
        'ContentType', 'vector', ...
        'Resolution', 300);
    filename_png = strrep(filename, '.pdf', '.png');
    exportgraphics(fig, fullfile(outputDir, filename_png), ...
        'Resolution', 300);
end

%% ========================================================================
% (C2) Cohort ALL (everyone), SELECT responses, ALL controls/covariates
%     -> 1-tailed (computed CI): node, edge, triangle
%     (NOW includes ellipses at infinite CI ends; NO cap right before dots)
% ========================================================================
cohortC = 'all';
for s = 1:numel(simplex_list)
    simplex = simplex_list{s};

    switch simplex
        case 'node'
            current_featCodes = node_selected;
            current_featLabels = node_featLabels_selected;
            current_bounds = node_bounds_selected;
        case 'edge'
            current_featCodes = edge_selected;
            current_featLabels = edge_featLabels_selected;
            current_bounds = edge_bounds_selected;
        case 'triangle'
            current_featCodes = triangle_selected;
            current_featLabels = triangle_featLabels_selected;
            current_bounds = triangle_bounds_selected;
    end

    [betaC1, loC1, upC1, infLoC1, infUpC1] = load_ci_one_tailed_multiControls( ...
        dataDir, parcellation, simplex, cohortC, session, current_featCodes, controls, significance_alpha, confidence_interval_bound);

    fig = figure('Units','centimeters','Position',[2 2 12 14],'Color','w');
    apply_figure_defaults(fig);

    ax = axes('Parent',fig);
    ax.Position = [0.12 0.20 0.84 0.74];

    plot_ci_multi(ax, betaC1, loC1, upC1, current_featLabels, controlLabels, ...
        current_bounds, y_lim, markers, faceColors, infLoC1, infUpC1);

    ylabel(ax, sprintf('Linear Coefficient of %s Modularity', [upper(simplex(1)), simplex(2:end)]));
    title(ax, sprintf('%s, cohort all (1-tailed), ALL controls (SELECT responses)', simplex), ...
        'FontWeight','normal');

    set(fig, 'PaperPositionMode','auto');

    % Export
    filename = sprintf('plot_brain_behavior_correlation_%s_cohort_%s_session_%s_parcellation_%s_tail_%d_response_%s_control_%s.pdf', ...
        simplex, cohortC, session, parcellation, 1, 'select', 'all');
    exportgraphics(fig, fullfile(outputDir, filename), ...
        'ContentType', 'vector', ...
        'Resolution', 300);
    filename_png = strrep(filename, '.pdf', '.png');
    exportgraphics(fig, fullfile(outputDir, filename_png), ...
        'Resolution', 300);

end

%% Export legend:
filename = 'plot_brain_behavior_correlation_legend_controls.pdf';
exportgraphics(figLeg_controls, fullfile(outputDir, filename), ...
    'ContentType', 'vector', ...
    'Resolution', 300);

%% ============================ FUNCTIONS =================================

function apply_figure_defaults(fig)
set(fig, 'DefaultAxesFontName','Helvetica', ...
    'DefaultAxesFontSize',10, ...
    'DefaultAxesLineWidth',1, ...
    'DefaultLineLineWidth',1.4, ...
    'DefaultLineMarkerSize',6);
end

function fname = build_stats_fname(dataDir, cohort, session, parcellation, simplex, feature, control)
fname = fullfile(dataDir, sprintf( ...
    'stats_raw_features_%s_%s_%s_%s_predicts_%s_controlledby_%s.mat', ...
    cohort, session, parcellation, simplex, feature, control));
end

function rowIdx = find_coef_row(stats, coefName, fname)
names = stats.Name;
if isstring(names), names = cellstr(names); end
if ischar(names),   names = cellstr(names); end

rowIdx = find(strcmp(names, coefName), 1);
if isempty(rowIdx)
    error('Row "%s" not found in %s', coefName, fname);
end
end

function [beta, lower, upper] = load_ci_two_tailed_singleControl(dataDir, parcellation, simplex, cohort, session, feats, control)
% Load estimate and stored 2-tailed CI for a single control condition
[betaM, lowerM, upperM] = load_ci_two_tailed_multiControls(dataDir, parcellation, simplex, cohort, session, feats, {control});
beta  = betaM(:,1);
lower = lowerM(:,1);
upper = upperM(:,1);
end

function [beta, lower, upper] = load_ci_two_tailed_multiControls(dataDir, parcellation, simplex, cohort, session, feats, controls)
% Load estimate and stored 2-tailed CI for multiple control conditions
nF = numel(feats);
nC = numel(controls);

beta  = nan(nF,nC);
lower = nan(nF,nC);
upper = nan(nF,nC);

coefName = sprintf("%s_%s_modularity", session, simplex); % both_edge_modularity

for c = 1:nC
    control = controls{c};
    for k = 1:nF
        feature = feats{k};
        fname = build_stats_fname(dataDir, cohort, session, parcellation, simplex, feature, control);

        if ~exist(fname,'file')
            error('File not found:\n%s', fname);
        end

        L = load(fname);
        if ~isfield(L,'stats')
            error('Variable "stats" not found in %s', fname);
        end
        stats = L.stats;

        rowIdx = find_coef_row(stats, coefName, fname);

        beta(k,c)  = stats.Estimate(rowIdx);
        lower(k,c) = stats.Lower(rowIdx);
        upper(k,c) = stats.Upper(rowIdx);
    end
end
end

function [beta, lower, upper, infLower, infUpper] = load_ci_one_tailed_multiControls( ...
    dataDir, parcellation, simplex, cohort, session, feats, controls, alpha, bigCI)
% Compute 1-tailed CIs for all control conditions using fcn_stat_construct_confidence_interval
% Returns:
%   infLower / infUpper masks indicating which bounds were +/-Inf BEFORE capping.

nF = numel(feats);
nC = numel(controls);

beta     = nan(nF,nC);
lower    = nan(nF,nC);
upper    = nan(nF,nC);
infLower = false(nF,nC);
infUpper = false(nF,nC);

coefName = sprintf("%s_%s_modularity", session, simplex); % e.g. 'both_triangle_modularity'

for c = 1:nC
    control = controls{c};
    for k = 1:nF
        feature = feats{k};
        fname = build_stats_fname(dataDir, cohort, session, parcellation, simplex, feature, control);

        if ~exist(fname,'file')
            error('File not found:\n%s', fname);
        end

        L = load(fname);
        if ~isfield(L,'stats')
            error('Variable "stats" not found in %s', fname);
        end
        stats = L.stats;

        rowIdx = find_coef_row(stats, coefName, fname);

        est = stats.Estimate(rowIdx);
        se  = stats.SE(rowIdx);
        df  = stats.DF(rowIdx);

        % 1-tailed CI (routine should return one infinite bound)
        [lo, up] = fcn_stat_construct_confidence_interval(est, se, df, alpha, 1);

        % Track which side was infinite (for plotting ellipses)
        infLower(k,c) = isinf(lo);
        infUpper(k,c) = isinf(up);

        % Cap infinite bounds to a safe numeric value (we will plot with ellipses anyway)
        if isinf(lo), lo = -bigCI; end
        if isinf(up), up =  bigCI; end

        beta(k,c)  = est;
        lower(k,c) = lo;
        upper(k,c) = up;
    end
end
end

function plot_ci_single(ax, beta, lower, upper, labels, bounds, yLim)
% One set of error bars (single control)

x = 1:numel(beta);
errLow  = beta - lower;
errHigh = upper - beta;

xlim(ax, [0.5 numel(x)+0.5]);
ylim(ax, yLim);

hold(ax,'on');

% Background shading to emphasize partitions (white -> light gray -> darker gray)
apply_partition_shading(ax, bounds);

errorbar(ax, x, beta, errLow, errHigh, ...
    'LineStyle','none','Marker','o', ...
    'Color','k','MarkerFaceColor','k', ...
    'CapSize',3,'LineWidth',1.2);

yline(ax, 0, 'k-', 'LineWidth',0.75);

set(ax,'XTick',x,'XTickLabel',labels, ...
    'XTickLabelRotation',45, ...
    'TickDir','out', ...
    'Box','off');
end

function plot_ci_multi(ax, beta, lower, upper, labels, controlLabels, bounds, yLim, markers, faceColors, varargin)
% Multiple control conditions with horizontal jitter
% Optional:
%   plot_ci_multi(..., infLower, infUpper) to draw ellipses for one-tailed CIs.
%   In that one-tailed mode, we also REMOVE the end-cap right before the ellipses.

[nF, nC] = size(beta);
x0 = 1:nF;
offsets = linspace(-0.25, 0.25, nC);

% Optional masks for infinite bounds (one-tailed)
useEllipses = false;
infLower = false(nF,nC);
infUpper = false(nF,nC);
if numel(varargin) >= 2
    useEllipses = true;
    infLower = varargin{1};
    infUpper = varargin{2};
    if isempty(infLower), infLower = false(nF,nC); end
    if isempty(infUpper), infUpper = false(nF,nC); end
end

xlim(ax, [0.5 nF+0.5]);
ylim(ax, yLim);

hold(ax,'on');

% Background shading to emphasize partitions (white -> light gray -> darker gray)
apply_partition_shading(ax, bounds);

% Ellipsis geometry (in data units), matched to your example
yMin   = yLim(1);
yMax   = yLim(2);
yRange = yMax - yMin;

dotSpacing = 0.015 * yRange;  % ~0.0105 when yRange=0.7
dotMargin  = 0.010 * yRange;  % ~0.0070 when yRange=0.7

% where the errorbar should STOP if it was infinite (leaves room for dots)
yCapUpper = yMax - (dotMargin + 3*dotSpacing);
yCapLower = yMin + (dotMargin + 3*dotSpacing);

% the 3 dot y-positions (vertical ellipsis)
dotYsUpper = yMax - dotMargin - dotSpacing*(0:2);
dotYsLower = yMin + dotMargin + dotSpacing*(0:2);

ellipsisMarkerSize = 8;

% For one-tailed mode: we draw errorbars with NO caps, and then add caps
% only on the FINITE side(s), so there is NO cap right before the ellipses.
capSizePoints = 3;  % match the look of your 2-tailed cap size
capHalfWidthData = NaN;
if useEllipses
    % Convert "capSizePoints" -> x-data units for this axes so caps look consistent.
    fig = ancestor(ax,'figure');

    oldFigUnits = fig.Units;
    fig.Units = 'points';
    figPosPts = fig.Position;
    fig.Units = oldFigUnits;

    oldAxUnits = ax.Units;
    ax.Units = 'normalized';
    axPosNorm = ax.Position;
    ax.Units = oldAxUnits;

    axisWidthPts = figPosPts(3) * axPosNorm(3);
    xRange = diff(xlim(ax));

    % CapSize is a total length in points; we use half-length for left/right.
    capHalfWidthData = (capSizePoints/2) * (xRange / axisWidthPts);
end

for c = 1:nC
    x = x0 + offsets(c);

    % Use "plot bounds" that stop inside the axis if the true CI was infinite
    lowerPlot = lower(:,c);
    upperPlot = upper(:,c);

    if any(infUpper(:,c))
        upperPlot(infUpper(:,c)) = yCapUpper;
    end
    if any(infLower(:,c))
        lowerPlot(infLower(:,c)) = yCapLower;
    end

    errLow  = beta(:,c) - lowerPlot;
    errHigh = upperPlot - beta(:,c);

    % Caps:
    % - 2-tailed mode: keep normal caps via errorbar (CapSize=3)
    % - 1-tailed mode: NO caps via errorbar (CapSize=0), then add finite-end caps manually
    if useEllipses
        capForErrorbar = 0;   % critical: removes the horizontal segment before the dots
    else
        capForErrorbar = 3;
    end

    errorbar(ax, x, beta(:,c), errLow, errHigh, ...
        'LineStyle','none', ...
        'Marker',markers{c}, ...
        'Color','k', ...
        'MarkerFaceColor',faceColors{c}, ...
        'CapSize',capForErrorbar, ...
        'LineWidth',1.0);

    % Manual caps ONLY for finite ends (one-tailed mode)
    if useEllipses
        for k = 1:nF
            % Upper cap only if the upper bound was finite
            if ~infUpper(k,c)
                line(ax, [x(k)-capHalfWidthData, x(k)+capHalfWidthData], ...
                    [upperPlot(k), upperPlot(k)], ...
                    'Color','k', 'LineWidth',1.0);
            end

            % Lower cap only if the lower bound was finite
            if ~infLower(k,c)
                line(ax, [x(k)-capHalfWidthData, x(k)+capHalfWidthData], ...
                    [lowerPlot(k), lowerPlot(k)], ...
                    'Color','k', 'LineWidth',1.0);
            end
        end
    end

    % Draw vertical ellipses ("...") at the infinite end(s), if provided
    if useEllipses
        if any(infUpper(:,c))
            xu = x(infUpper(:,c));
            for j = 1:numel(dotYsUpper)
                plot(ax, xu, dotYsUpper(j)*ones(size(xu)), 'k.', ...
                    'MarkerSize', ellipsisMarkerSize, 'LineStyle','none');
            end
        end

        if any(infLower(:,c))
            xl = x(infLower(:,c));
            for j = 1:numel(dotYsLower)
                plot(ax, xl, dotYsLower(j)*ones(size(xl)), 'k.', ...
                    'MarkerSize', ellipsisMarkerSize, 'LineStyle','none');
            end
        end
    end
end

yline(ax, 0, 'k-', 'LineWidth',0.75);

set(ax,'XTick',x0,'XTickLabel',labels, ...
    'XTickLabelRotation',45, ...
    'TickDir','out', ...
    'Box','off');

% No legend here – use the separate legend figure created at top.
end

function apply_partition_shading(ax, bounds)
% Subtle background shading per partition (Nature-ish).
% Cycles: white -> light gray -> darker gray

yl = ylim(ax);

shadeColors = [1.00 1.00 1.00;   % white
    0.96 0.96 0.96;   % light gray
    0.90 0.90 0.90];  % darker gray (still subtle)

for i = 1:(numel(bounds)-1)
    x1 = bounds(i);
    x2 = bounds(i+1);

    fc = shadeColors(mod(i-1, size(shadeColors,1)) + 1, :);

    p = patch(ax, [x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], fc, ...
        'EdgeColor','none', ...
        'FaceAlpha',1);

    % Ensure shading is behind everything
    uistack(p,'bottom');
end

% Thin vertical boundary lines at internal boundaries
for i = 2:(numel(bounds)-1)
    xB = bounds(i);
    line(ax, [xB xB], yl, ...
        'Color',[0.75 0.75 0.75], ...
        'LineStyle','-', ...
        'LineWidth',0.6);
end
end

function figLeg = create_control_legend(controlLabels, markers, faceColors)
% Separate legend-only figure for the multi-control plots

figLeg = figure('Units','centimeters','Position',[2 2 7 5],'Color','w');
axLeg = axes('Position',[0 0 1 1],'Visible','off');
hold(axLeg,'on');

legendFontSize = 10;

nC = numel(controlLabels);
hLeg = gobjects(1,nC);

for c = 1:nC
    hLeg(c) = plot(axLeg, NaN, NaN, ...
        'LineStyle','none', ...
        'Marker',markers{c}, ...
        'Color','k', ...
        'MarkerFaceColor',faceColors{c}, ...
        'MarkerSize',6);
end

legend(axLeg, hLeg, controlLabels, ...
    'Location','west', ...
    'Box','off', ...
    'FontSize',legendFontSize);

set(figLeg, 'PaperPositionMode','auto');
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

function var_code = get_variable_code_from_display_name(var_dict, display_name)
    % Reverse lookup: find variable code from display name
    fields = fieldnames(var_dict);
    
    for i = 1:length(fields)
        field = fields{i};
        if startsWith(field, 'response_') && strcmp(var_dict.(field), display_name)
            var_code = strrep(field, 'response_', '');
            return;
        end
    end
    
    % If not found, return the display name (shouldn't happen)
    var_code = display_name;
end

function var_codes = convert_display_names_to_codes(display_names, var_dict)
    % Convert display names back to variable codes using var_dict
    var_codes = cell(size(display_names));
    for i = 1:length(display_names)
        var_codes{i} = get_variable_code_from_display_name(var_dict, display_names(i));
    end
end

function bounds = compute_partition_bounds(featCodes)
    % Determine partition bounds based on variable types
    % Personality (NEOFAC_*) | Psychopathology (ASR_*) | Cognitive (PMAT*)
    
    is_personality = cellfun(@(x) startsWith(x, 'NEOFAC'), featCodes);
    is_psychopath = cellfun(@(x) startsWith(x, 'ASR'), featCodes);
    
    n_personality = sum(is_personality);
    n_psychopath = sum(is_psychopath);
    
    bounds = [0.5, n_personality + 0.5, n_personality + n_psychopath + 0.5, numel(featCodes) + 0.5];
end