config = fcn_utils_get_config();

tasks = ["REST", "EMOTION", "GAMBLING", "LANGUAGE", "MOTOR", "RELATIONAL", "SOCIAL", "WM"];

output_directory = fullfile(config.repo_root, "data_pipeline", "individual_mapper_graphs");
if ~isfolder(output_directory)
    mkdir(output_directory);
end

subjects = [
    100206, ...
    125525, ...
    144832, ...
    192641, ...
    725751
    ];
session = "LR";
parcellation = "schaefer100x7";
simplex = "edge";

purity_threshold = 0.75;
peak_density_threshold = 0.9;

edge_alpha = 0.6;

for subject = subjects

    input_filename = sprintf("simplexMapper_%s_%d_%s_%s_data.mat", simplex, subject, session, parcellation);
    mapper_data = load(fullfile(config.scratch_dir, "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7", input_filename));

    color_data = mapper_data.amplitude_peak_density_peak_threshold_95;
    min_color_data = 0;
    max_color_data = 1;
    for colorbar_flag = [0, 1]
        fig = fcn_mapper_color_mapper_with_data(mapper_data, color_data, ...
            "min_color_data", min_color_data, ...
            "max_color_data", max_color_data, ...
            "colorbar_flag", colorbar_flag, ...
            "edge_alpha", 0.6);
        output_filename = sprintf("simplexMapper_%s_%d_%s_%s_peak_density_colorbar_%d.pdf", simplex, subject, session, parcellation, colorbar_flag);
        exportgraphics(fig, fullfile(output_directory, output_filename), ...
            'ContentType','vector');
    end
    close all;
    
    peak_density = mapper_data.amplitude_peak_density_peak_threshold_95;
    is_pure_node = mapper_data.mapper_stat_node_purity > purity_threshold;
    peak_density_quantile = quantile(peak_density(is_pure_node), peak_density_threshold);
    highlighted_nodes = and(...
        is_pure_node, ...
        peak_density > peak_density_quantile);
    output_filename = sprintf("simplexMapper_%s_%d_%s_%s_peak_dense_pure_nodes_purity_%d_peak_density_%d_edgeAlpha_%d.pdf", simplex, subject, session, parcellation, purity_threshold * 100, peak_density_threshold * 100, edge_alpha * 100);
    fcn_mapper_drawd3graph(...
        mapper_data.mapper_nodeBynode, ...
        mapper_data.mapper_stat_mode_task_indices, ...
        fcn_utils_get_task_coloring(tasks), ...
        fullfile(output_directory, output_filename), ...
        mapper_data.mapper_stat_task_count_per_node, ...
        "highlighted_nodes", highlighted_nodes, ...
        "edge_alpha", edge_alpha);
    close all;

    color_data = mapper_data.mapper_stat_within_task_centrallity;
    min_color_data = 0;
    max_color_data = 1.6e-3;
    for colorbar_flag = [0, 1]
        fig = fcn_mapper_color_mapper_with_data(mapper_data, color_data, ...
            "min_color_data", min_color_data, ...
            "max_color_data", max_color_data, ...
            "colorbar_flag", colorbar_flag, ...
            "edge_alpha", edge_alpha);
        output_filename = sprintf("simplexMapper_%s_%d_%s_%s_centrality_colorbar_%d_edgeAlpha_%d.pdf", simplex, subject, session, parcellation, colorbar_flag, edge_alpha * 100);
        exportgraphics(fig, fullfile(output_directory, output_filename), ...
            'ContentType','vector');
    end

    close all;
end