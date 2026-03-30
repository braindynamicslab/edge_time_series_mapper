function task_specific_centrality = fcn_edgeMapper_compute_task_specific_centrality(...
    mapper_nodeBynode, mapper_stat_task_count_per_node, mapper_stat_mode_task_indices, varargin)
    % Compute task-specific closeness centrality for Mapper nodes
    %
    % Calculates a modified closeness centrality that weights distances by
    % the proportion of each node's data points belonging to the mode task.
    % This metric quantifies how central each node is with respect to its
    % dominant task label.
    %
    % Algorithm:
    %   1. Compute shortest path distances between all node pairs
    %   2. Normalize task counts to get proportions per node
    %   3. Weight distances by mode task proportion
    %   4. Apply scaling factor based on graph connectivity
    %   5. Compute centrality as inverse of weighted average distance
    %
    % Inputs:
    %   mapper_nodeBynode - [num_nodes x num_nodes] Binary adjacency matrix
    %                       Symmetric matrix where 1 indicates edge between nodes
    %   mapper_stat_task_count_per_node - [num_nodes x num_tasks] Count matrix
    %                                      Number of data points per task in each node
    %   mapper_stat_mode_task_indices - [num_nodes x 1] Mode task index per node
    %                                    Which task is most represented in each node
    %
    % Optional Parameters (name-value pairs):
    %   'unreachable_distance' - Value to use for infinite/NaN distances (default: 0)
    %                           0 = unreachable nodes don't contribute to centrality
    %                           Large value = penalize nodes with unreachable neighbors
    %
    % Outputs:
    %   task_specific_centrality - [1 x num_nodes] Row vector of centrality values
    %                              Higher values indicate more central nodes
    %                              Range: [0, Inf), typical values near 1
    %
    % Example:
    %   % After running Mapper analysis:
    %   centrality = fcn_edgeMapper_compute_task_specific_centrality(...
    %       mapper_nodeBynode, ...
    %       mapper_stat_task_count_per_node, ...
    %       mapper_stat_mode_task_indices);
    %   
    %   % With custom unreachable distance penalty:
    %   centrality = fcn_edgeMapper_compute_task_specific_centrality(...
    %       mapper_nodeBynode, ...
    %       mapper_stat_task_count_per_node, ...
    %       mapper_stat_mode_task_indices, ...
    %       'unreachable_distance', 100);
    %   
    %   % Find most central nodes
    %   [sorted_centrality, sort_idx] = sort(centrality, 'descend');
    %   most_central_nodes = sort_idx(1:10);
    %
    % See also: fcn_edgeMapper_compute_and_analyze_simplex_mapper
    
    %% Parse inputs
    
    p = inputParser;
    addRequired(p, 'mapper_nodeBynode');
    addRequired(p, 'mapper_stat_task_count_per_node');
    addRequired(p, 'mapper_stat_mode_task_indices');
    addParameter(p, 'unreachable_distance', 0, @isnumeric);
    parse(p, mapper_nodeBynode, mapper_stat_task_count_per_node, mapper_stat_mode_task_indices, varargin{:});
    
    unreachable_distance = p.Results.unreachable_distance;
    
    %% Validate inputs
    
    assert(ismatrix(mapper_nodeBynode) && size(mapper_nodeBynode, 1) == size(mapper_nodeBynode, 2), ...
        'mapper_nodeBynode must be square matrix, got [%d x %d]', ...
        size(mapper_nodeBynode, 1), size(mapper_nodeBynode, 2));
    
    num_nodes = size(mapper_nodeBynode, 1);
    
    assert(size(mapper_stat_task_count_per_node, 1) == num_nodes, ...
        'mapper_stat_task_count_per_node must have %d rows (num_nodes), got %d', ...
        num_nodes, size(mapper_stat_task_count_per_node, 1));
    
    assert(numel(mapper_stat_mode_task_indices) == num_nodes, ...
        'mapper_stat_mode_task_indices must have %d elements (num_nodes), got %d', ...
        num_nodes, numel(mapper_stat_mode_task_indices));
    
    assert(unreachable_distance >= 0, ...
        'unreachable_distance must be non-negative, got %.2f', unreachable_distance);
    
    %% Original computation code
    
    % Compute pairwise distances using binary adjacency matrix
    % Use graph shortest path algorithm
    G = graph(mapper_nodeBynode, 'upper');
    distance_matrix = distances(G, 'Method', 'unweighted');
    
    % Convert distances to full matrix if sparse
    distance_matrix = full(distance_matrix);
    
    % Compute number of reachable nodes for each node
    % A node is reachable if distance is finite
    num_reachable_nodes = sum(isfinite(distance_matrix), 2)';  % Row vector
    
    % Replace inf and nan in distances with specified value
    distance_matrix(isinf(distance_matrix) | isnan(distance_matrix)) = unreachable_distance;
    
    % Normalize each row of taskCountPerNode
    row_sums = sum(mapper_stat_task_count_per_node, 2);
    
    % Check for division by zero
    if any(row_sums == 0)
        error('Division by zero: mapper_stat_task_count_per_node contains rows that sum to zero');
    end
    
    normalized_taskCountPerNode = mapper_stat_task_count_per_node ./ row_sums;
    
    % Extract proportion with respect to mode
    proportion_with_respect_to_mode = normalized_taskCountPerNode(:, mapper_stat_mode_task_indices);
    
    % Compute unscaled_inverse_centrality using dot product
    % dot product of corresponding columns - results in row vector
    unscaled_inverse_centrality = dot(distance_matrix, proportion_with_respect_to_mode);
    
    % Compute scaling factor
    scaling_factor = (num_reachable_nodes - 1) / (num_nodes - 1)^2;
    
    % Compute task_specific_closeness_centrality
    task_specific_centrality = scaling_factor .* sum(proportion_with_respect_to_mode) ./ unscaled_inverse_centrality;
    
end