function peak_density = fcn_edgeMapper_compute_peak_density(nodeTpMat, amplitude_framewise, amplitude_quantile_threshold)
    % Compute peak density for each node based on frame amplitude
    %
    % Peak density is the proportion of frames in each node that exceed a 
    % specified amplitude quantile threshold. This metric identifies nodes
    % that preferentially contain high-amplitude activity frames.
    %
    % Inputs:
    %   nodeTpMat - [num_nodes x num_frames] logical matrix
    %               Binary frame assignment to nodes. Each row represents a node,
    %               each column a frame. Value is 1 if frame belongs to node.
    %               Frames may belong to multiple nodes; nodes may contain 
    %               multiple frames.
    %
    %   amplitude_framewise - [num_frames x 1] numeric vector
    %                         Amplitude value for each frame (e.g., BOLD signal
    %                         magnitude, co-activation intensity)
    %
    %   amplitude_quantile_threshold - Scalar in [0, 1]
    %                                  Quantile threshold for defining peak frames.
    %                                  Frames at or above this quantile are 
    %                                  considered peaks (e.g., 0.9 = top 10%)
    %
    % Outputs:
    %   peak_density - [num_nodes x 1] numeric vector
    %                  Proportion of frames in each node that are peaks.
    %                  Range: [0, 1]. Returns NaN for nodes with zero frames.
    %
    % Example:
    %   % Create random node assignments and amplitudes
    %   nodeTpMat = logical(randi([0 1], 100, 500));  % 100 nodes, 500 frames
    %   amplitude = randn(500, 1);
    %   
    %   % Compute density of top 20% amplitude frames
    %   density = fcn_edgeMapper_compute_peak_density(nodeTpMat, amplitude, 0.8);
    %   
    %   % Find nodes enriched for high-amplitude frames
    %   enriched_nodes = find(density > 0.3);  % >30% peak frames
    %
    % See also: fcn_edgeMapper_compute_node_statistics, quantile

    % Compute amplitude threshold from quantile
        
    amplitude_threshold = quantile(amplitude_framewise, amplitude_quantile_threshold);
    
    % Compute binary peak indicator (ensure column vector)
    is_peak = amplitude_framewise >= amplitude_threshold;
    
    % Compute number of frames per node (row sum)
    num_frames_per_node = sum(nodeTpMat, 2);
    
    % Compute number of peaks per node (matrix-vector multiplication)
    num_peaks_per_node = nodeTpMat * is_peak;
    
    % Compute peak density (handle division by zero)
    peak_density = num_peaks_per_node ./ num_frames_per_node;

end