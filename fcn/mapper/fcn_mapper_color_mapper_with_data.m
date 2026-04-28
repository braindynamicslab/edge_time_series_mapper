function fig = fcn_mapper_color_mapper_with_data(mapper_data, color_data, varargin)
    % Color mapper nodes based on data values
    %
    % Visualizes mapper graph with nodes colored according to data values.
    % Node sizes represent the proportion of data points at each node.
    %
    % Inputs:
    %   mapper_data - Struct containing mapper graph structure with fields:
    %                 .mapper_nodeTpMat - [nodes x frames] binary matrix
    %                 .mapper_nodes_positions - [nodes x 2] node coordinates
    %                 .mapper_nodeBynode - [nodes x nodes] adjacency matrix
    %   color_data - [frames x 1] or [nodes x 1] values for coloring nodes
    %
    % Optional Parameters (name-value pairs):
    %   'cmap' - Colormap name (default: "turbo")
    %   'edge_color' - RGB or RGBA color for edges (default: [0.6, 0.6, 0.6])
    %                  If 4 elements, alpha is included; if 3, use edge_alpha
    %   'edge_alpha' - Alpha transparency for edges (default: 0.3)
    %                  Ignored if edge_color has 4 elements
    %   'min_color_data' - Minimum value for color scale (default: min(color_data))
    %   'max_color_data' - Maximum value for color scale (default: max(color_data))
    %   'minimal_radius' - Minimum node radius (default: 0.1)
    %   'radius_scaling_factor' - Scaling factor for node sizes (default: 2)
    %   'colorbar_flag' - Show colorbar: 1=yes, 0=no (default: 1)
    %
    % Outputs:
    %   fig - Figure handle
    %
    % Example:
    %   fig = fcn_mapper_color_mapper_with_data(mapper_data, betweenness, ...
    %                                           'cmap', "viridis", ...
    %                                           'colorbar_flag', 1);
    %
    % See also: fcn_viz_draw_circles, fcn_mapper_average_at_each_mapper_node
    
    % Parse inputs
    p = inputParser;
    addRequired(p, 'mapper_data', @isstruct);
    addRequired(p, 'color_data', @isnumeric);
    addParameter(p, 'cmap', "parula", @ischar);
    addParameter(p, 'edge_color', [0.6, 0.6, 0.6], @isnumeric);
    addParameter(p, 'edge_alpha', 0.3, @isnumeric);
    addParameter(p, 'min_color_data', [], @isnumeric);
    addParameter(p, 'max_color_data', [], @isnumeric);
    addParameter(p, 'minimal_radius', 0.1, @isnumeric);
    addParameter(p, 'radius_scaling_factor', 2, @isnumeric);
    addParameter(p, 'colorbar_flag', 1, @isnumeric);
    parse(p, mapper_data, color_data, varargin{:});
    
    % Extract parameters
    cmap = string(p.Results.cmap);
    edge_color = p.Results.edge_color;
    edge_alpha = p.Results.edge_alpha;
    min_color_data = p.Results.min_color_data;
    max_color_data = p.Results.max_color_data;
    minimal_radius = p.Results.minimal_radius;
    radius_scaling_factor = p.Results.radius_scaling_factor;
    colorbar_flag = p.Results.colorbar_flag;
    
    % Construct edge color with alpha
    if numel(edge_color) == 4
        edge_color_with_alpha = edge_color;
    else
        edge_color_with_alpha = [edge_color(:)', edge_alpha];
    end
    
    % Get dimensions
    num_nodes = size(mapper_data.mapper_nodeTpMat, 1);
    num_frames = size(mapper_data.mapper_nodeTpMat, 2);
    assert(numel(color_data) == num_nodes || numel(color_data) == num_frames, ...
        'color_data must have %d elements (num_frames) or %d elements (num_nodes), got %d', ...
        num_frames, num_nodes, numel(color_data));
    
    % Get node positions
    x_data = mapper_data.mapper_nodes_positions(:, 1);
    y_data = mapper_data.mapper_nodes_positions(:, 2);
    
    % Get edge list
    [v1, v2, ~] = find(mapper_data.mapper_nodeBynode);
    edge_list = [v1(v1 <= v2), v2(v1 <= v2)];
    
    % Calculate node radii based on data point density
    num_data_points_at_each_mapper_node = sum(mapper_data.mapper_nodeTpMat, 2);
    prop_data_points_at_each_mapper_node = num_data_points_at_each_mapper_node / sum(num_data_points_at_each_mapper_node);
    radii = minimal_radius + radius_scaling_factor * sqrt(prop_data_points_at_each_mapper_node);
    
    % Process color data
    if numel(color_data) == num_frames
        color_data = fcn_mapper_average_at_each_mapper_node(mapper_data.mapper_nodeTpMat, color_data);
    end
    
    % Set color scale limits
    if isempty(min_color_data)
        min_color_data = min(color_data);
    end
    if isempty(max_color_data)
        max_color_data = max(color_data);
    end
    
    % Map data values to colormap indices
    cmap_matrix = colormap(char(cmap));
    num_colors = size(cmap_matrix, 1);
    
    scaled_color_data = (color_data - min_color_data) / (max_color_data - min_color_data);
    scaled_color_data = 1 + (num_colors - 1) * scaled_color_data;
    colors = reshape(ind2rgb(round(scaled_color_data), cmap_matrix), [], 3);
    
    % Create figure and plot
    fig = figure;
    
    % Plot edges
    plot(x_data(edge_list)', y_data(edge_list)', 'Color', edge_color_with_alpha);
    hold on;
    
    % Plot nodes as colored circles
    fcn_viz_draw_circles([x_data, y_data], radii, colors, fig);
    
    % Add colorbar if requested
    if colorbar_flag
        c = colorbar;
        clim([min_color_data, max_color_data]);
    end
    
    % Format figure
    set(fig, 'Color', 'White');
    box off;
    axis off;
end