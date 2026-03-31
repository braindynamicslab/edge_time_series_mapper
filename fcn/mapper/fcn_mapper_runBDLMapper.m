function [nodeTpMat, nodeBynode, tpMat, filter, stress] = fcn_mapper_runBDLMapper(data, metricType, res_val, gain_val, num_k, num_bin_clusters,  ndim, varargin)

p = inputParser;
addParameter(p, 'distMat', []);
parse(p, varargin{:});

    % we use hexagon bins!

    X = data;
    opt = statset('display','iter');
    
    resolution = [res_val res_val];
    gain = gain_val;
    
    fprintf(1,'Estimating distance matrix\n');
    tic
    if isempty(p.Results.distMat)
        distMat = estimateDistance(X, metricType);
    else
        distMat = p.Results.distMat;
        if size(distMat, 1) ~= size(distMat, 2)
            distMat = squareform(distMat);
        end
    end
    toc
    
    %--Manish Version--%
    fprintf(1,'Estimating knn graph\n');
    tic
    % create knn graph, estimate geodesic distances, embed using cmdscale and apply mapper
    [~, ~, ~, ~, knnGraph_dense_wtd_conn]= fcn_mapper_createPKNNG_bdl(distMat, num_k);
    knnGraph_dense_wtd_conn(isnan(knnGraph_dense_wtd_conn)) = 0;

    % date: Mar 19, 2024
    % making a change here using knnGraph_dense_wtd_conn instead of
    % binarized
    % knn_g_wtd = graph(knnGraph_dense_bin_conn);
    knn_g_wtd = graph(knnGraph_dense_wtd_conn);

    % estimate geodesic distances
    % date: Mar 19, 2024
    % making a change here using auto method instead of positive; also
    % removing rounding.
    % dist_geo_wtd = round(distances(knn_g_wtd,'Method','positive'));
    dist_geo_wtd = distances(knn_g_wtd);
    toc
    
    fprintf(1,'Estimating embedding\n');
    tic
    
    % embed using cmdscale
    if sum(sum(isinf(dist_geo_wtd))) > 0
        fprintf(2,'Error geodesic distances have an infinite value, fixing it by adding a large value instead of Inf\n');
        dist_geo_wtd(find(isinf(dist_geo_wtd))) = max(dist_geo_wtd(~isinf(dist_geo_wtd)))+10;
        
        % date: Mar 19, 2024
        % making a change to metric MDS from classic MDS and saving stress
        % values to determine the quality or goodness of fit. Also using
        % Sammon as a stress measure to better preserve smaller distances.
%        %[y,e] = cmdscale(dist_geo_wtd);
%        [y, stress] = mdscale(dist_geo_wtd, ndim, 'Options', opt, 'Start', 'cmdscale', 'Criterion', 'sammon');
%    else        
%        %[y,e] = cmdscale(dist_geo_wtd);
%        [y, stress] = mdscale(dist_geo_wtd, ndim, 'Options', opt, 'Start', 'cmdscale', 'Criterion', 'sammon');
    end
    
    try
        [y, stress] = mdscale(dist_geo_wtd, ndim, 'Options', opt, 'Start', 'cmdscale', 'Criterion', 'sammon');
    catch
        warning("initalization with cmdscale failed, use a random initialization instead")
        [y, stress] = mdscale(dist_geo_wtd, ndim, 'Options', opt, 'Start', 'random', 'Criterion', 'sammon');
    end

    
    filter = [y(:,1), y(:,2)];
    % modifying filter by taking a zscore and then log transform Updated
    % Nov 12, 2022
    %filter = real([log(zscore(filter(:,1))) log(zscore(filter(:,2)))]);
    toc
    
    fprintf(1,'Running mapper\n');
    tic
    
    
    %[adja, adja_pruned, pts_in_vertex, pts_in_vertex_pruned] = mapper2d_bdl_nonmetric(distMat, filter, resolution, gain, num_bin_clusters);
    [~, adja_pruned, ~, pts_in_vertex_pruned] = fcn_mapper_mapper2d_bdl_hex_binning(distMat, filter, resolution, gain, num_bin_clusters, 6); 
       %using triangulation, as higher values induce too many connections
    %--End Manish Version--%
    toc
    
    fprintf(1,'Creating final output\n');
    tic
    % creating matrices for d3 visualization
    numNodes = length(pts_in_vertex_pruned);
    numTp = size(X,1);
    nodeTpMat = zeros(numNodes, numTp);
    for node = 1:1:numNodes
        tmp = pts_in_vertex_pruned{node};
        nodeTpMat(node, tmp) = 1;
    end

    nodeBynode = adja_pruned;
    tpMat = getMatTp_wtd(nodeBynode, nodeTpMat);
    fprintf(1,'Done\n');
    toc

end

function tpmat = getMatTp_wtd(mat, nodeTpMat)
    tpmat = zeros(size(nodeTpMat,2),size(nodeTpMat,2)); 
    for node1 = 1:1:size(mat,1)
        for node2 = 1:1:size(mat,1)
            if mat(node1,node2) 
                trs_node1 = find(nodeTpMat(node1,:));
                trs_node2 = find(nodeTpMat(node2,:));
                for tr1 = 1:1:length(trs_node1)
                    for tr2 = 1:1:length(trs_node2)
                        tpmat(trs_node1(tr1), trs_node2(tr2)) = tpmat(trs_node1(tr1), trs_node2(tr2)) + 1;
                        tpmat(trs_node2(tr2), trs_node1(tr1)) = tpmat(trs_node2(tr2), trs_node1(tr1)) + 1;
                    end
                end

            end
        end
    end
    tpmat(1:size(tpmat,1)+1:end) = 0;
end

function distMat = estimateDistance(X, metricType)
    distMat = squareform(pdist(X, metricType));
end

