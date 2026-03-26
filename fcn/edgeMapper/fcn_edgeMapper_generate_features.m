function [data_higher_features, feature_indices] = ...
    fcn_edgeMapper_generate_features(data, simplex, varargin)
    % Generate higher-order features from BOLD timeseries
    %
    % Computes element-wise products of node activities to create edge or
    % triangle features. Optionally applies coherence-based signing and
    % activity masking.
    %
    % Feature generation:
    %   - Node: Returns original data (identity operation)
    %   - Edge: Pairwise products x_i(t) * x_j(t) for all pairs i < j
    %   - Triangle: Triple products x_i(t) * x_j(t) * x_k(t) for all triples i < j < k
    %
    % Inputs:
    %   data - [timepoints x nodes] BOLD timeseries matrix
    %   simplex - Feature type: "node", "edge", or "triangle"
    %
    % Optional Parameters (name-value pairs):
    %   'zscore_flag' - Z-score input data: 1=yes, 0=no (default: 1)
    %   'sign_by_coherence_flag' - Apply coherence-based signing: 1=yes, 0=no (default: 0)
    %                              Node: Take absolute value
    %                              Triangle: Negative if vertices have mixed signs
    %   'activity_mask_flag' - Mask low activity: 1=yes, 0=no (default: 0)
    %                          Set activity to 0 if |activity| < 1 (after z-scoring)
    %
    % Outputs:
    %   data_higher_features - [timepoints x features] Higher-order feature matrix
    %                          Number of features:
    %                          - Node: n
    %                          - Edge: n*(n-1)/2
    %                          - Triangle: n*(n-1)*(n-2)/6
    %   feature_indices - [num_features x order] Index matrix
    %                     Each row contains node indices forming the feature
    %                     Example for edges: [1,2; 1,3; 2,3] means features are
    %                     x_1*x_2, x_1*x_3, x_2*x_3
    %
    % Example:
    %   data = randn(200, 100);  % 200 timepoints, 100 nodes
    %   
    %   % Generate edge features
    %   [edges, idx] = fcn_edgeMapper_generate_features(data, "edge");
    %   % edges: [200 x 4950], idx: [4950 x 2]
    %   
    %   % Generate triangle features with coherence signing
    %   [triangles, idx] = fcn_edgeMapper_generate_features(data, "triangle", ...
    %                          'sign_by_coherence_flag', 1);
    %
    % Reference:
    %   Edge time series approach from:
    %   https://github.com/brain-networks/edge-centric_demo
    %
    % See also: fcn_edgeMapper_preprocess_data, fcn_edgeMapper_get_processed_edge_time_series_data
    
    %% Parse and validate inputs
    
    p = inputParser;
    addRequired(p, 'data', @isnumeric);
    addRequired(p, 'simplex', @(x) isStringScalar(x) || ischar(x));
    addParameter(p, 'zscore_flag', 1, @isnumeric);
    addParameter(p, 'sign_by_coherence_flag', 0, @isnumeric);
    addParameter(p, 'activity_mask_flag', 0, @isnumeric);
    parse(p, data, simplex, varargin{:});
    
    % Extract parameters
    simplex = string(p.Results.simplex);
    zscore_flag = p.Results.zscore_flag;
    sign_by_coherence_flag = p.Results.sign_by_coherence_flag;
    activity_mask_flag = p.Results.activity_mask_flag;
    
    % Validate data dimensions
    assert(ismatrix(data), 'data must be a 2D matrix, got %dD array', ndims(data));
    
    % Determine simplex order
    if ismember(simplex, ["node", "vertex", "nodes", "vertices"])
        simplex_order = 1;
    elseif ismember(simplex, ["edge", "edges"])
        simplex_order = 2;
    elseif ismember(simplex, ["triangle", "triangles"])
        simplex_order = 3;
    else
        error('simplex must be one of: node, edge, triangle\nGot: "%s"', simplex);
    end
    
    %% Z-score normalization
    
    if zscore_flag
        data_normalized = normalize(data);
    else
        data_normalized = data;
    end
    
    %% Apply activity mask if requested
    
    if activity_mask_flag
        % Mask out low activity (|z-score| < 1)
        % Implements "violating triangle" concept: only keep simplices where
        % product exceeds products of lower-dimensional faces
        data_normalized(abs(data_normalized) < 1) = 0;
    end
    
    %% Generate higher-order features via products
    
    [data_higher_features, feature_indices] = compute_product_features(data_normalized, simplex_order);
    
    %% Apply coherence-based signing if requested
    
    if sign_by_coherence_flag
        if simplex_order == 1
            % Node features: take absolute value
            data_higher_features = abs(data_higher_features);
            
        elseif simplex_order == 3
            % Triangle features: negative if vertices have mixed signs
            % Coherence = all three vertices have same sign (all positive or all non-positive)
            
            num_timepoints = size(data_higher_features, 1);
            data_sign = data_normalized > 0;  % [timepoints x nodes] logical
            
            for time_idx = 1:num_timepoints
                % Get signs of all triangle vertices at this timepoint
                triangle_signs = data_sign(time_idx, feature_indices);
                
                % Check coherence: all positive OR all non-positive
                is_coherent = all(triangle_signs, 2) | all(~triangle_signs, 2);
                
                % Apply sign: coherent triangles positive, incoherent negative
                sign_multiplier = (-1) .^ (1 + is_coherent);
                data_higher_features(time_idx, :) = sign_multiplier .* data_higher_features(time_idx, :);
            end
        end
        
        % Edge features (simplex_order == 2): no coherence signing applied
    end
    
end


%% Local helper function

function [product_features, feature_indices] = compute_product_features(data, simplex_order)
    % Compute element-wise products of node activities
    %
    % For simplex_order = k, computes all k-way products of node activities:
    %   product(t, s) = x_i1(t) * x_i2(t) * ... * x_ik(t)
    % where s indexes all k-combinations of nodes
    %
    % Inputs:
    %   data - [timepoints x nodes] timeseries matrix (should be z-scored)
    %   simplex_order - Order of simplex (1=node, 2=edge, 3=triangle)
    %
    % Outputs:
    %   product_features - [timepoints x num_features] product timeseries
    %   feature_indices - [num_features x simplex_order] node indices per feature
    
    num_nodes = size(data, 2);
    
    % Generate all k-combinations of node indices
    feature_indices = nchoosek(1:num_nodes, simplex_order);
    
    % Compute products iteratively
    product_features = data(:, feature_indices(:, 1));
    for order_idx = 2:simplex_order
        product_features = product_features .* data(:, feature_indices(:, order_idx));
    end
end