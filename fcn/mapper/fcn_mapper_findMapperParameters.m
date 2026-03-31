function [num_k, res_val, gain_val, num_bin_clusters] = fcn_mapper_findMapperParameters(data, metricType, ndim, conn_perct, varargin)

p = inputParser;
addParameter(p, 'distMat', []);
parse(p, varargin{:});

    % acf=[];
    % for p=1:1:size(data,2)
    %     acf(:,p)= autocorr(double(data(:,p)),'NumLags',100); 
    % end
    %[~,locs]=findpeaks(-sum(acf'>0)); %inverting the acf function to find lowest value/peak of acf
    %locs = find(mean(acf')<0); % instead trying a mean acf and finding when it reaches zero

    %num_k = locs(1);
    num_k = floor(sqrt(size(data,1))); %sqrt of number of time points; from this paper - https://link.springer.com/article/10.1007/s10462-017-9593-z

    opt = statset('display','iter');
    if isempty(p.Results.distMat)
        distMat = fcn_mapper_estimateDistance(data, metricType);
    else
        distMat = p.Results.distMat;
        if size(distMat, 1) ~= size(distMat, 2)
            distMat = squareform(distMat);
        end
    end
    % distMat = estimateDistance(data, metricType);
    [~, ~, ~, ~, knnGraph_dense_wtd_conn]= fcn_mapper_createPKNNG_bdl(distMat, num_k);
    knnGraph_dense_wtd_conn(isnan(knnGraph_dense_wtd_conn)) = 0;
    knn_g_wtd = graph(knnGraph_dense_wtd_conn);
    dist_geo_wtd    = distances(knn_g_wtd);
    
    if sum(sum(isinf(dist_geo_wtd))) > 0
        fprintf(2,'Error geodesic distances have an infinite value, fixing it by adding a large value instead of Inf\n');
        dist_geo_wtd(find(isinf(dist_geo_wtd))) = max(dist_geo_wtd(~isinf(dist_geo_wtd)))+10;        
%        [y, stress] = mdscale(dist_geo_wtd, ndim, 'Options', opt, 'Start', 'cmdscale', 'Criterion', 'sammon');
%    else        
%        [y, stress] = mdscale(dist_geo_wtd, ndim, 'Options', opt, 'Start', 'cmdscale', 'Criterion', 'sammon');
    end
    
    try
        [y, stress] = mdscale(dist_geo_wtd, ndim, 'Options', opt, 'Start', 'cmdscale', 'Criterion', 'sammon');
    catch
        warning("initalization with cmdscale failed, use a random initialization instead")
        [y, stress] = mdscale(dist_geo_wtd, ndim, 'Options', opt, 'Start', 'random', 'Criterion', 'sammon');
    end

    % only available in Matlab 2024a, thus trying KDE2F function downloaded
    % from mathworks
    %[~,~,bw1]=kde(y(:,1), Bandwidth='plug-in');
    %[~,~,bw2]=kde(y(:,2), Bandwidth='plug-in');
    [~,bw,~,~]=fcn_mapper_KDE2_eff(y(:,1), y(:,2));

    %res_val = ceil(max(max(y)-min(y))./(2*max(bw1,bw2))); % (2)x bw -> overlapping next point too by 50%.
    %res_val = ceil(max(max(y)-min(y))./(2*min(bw1,bw2))); % (2)x bw -> overlapping next point too by 50%.
    res_val = ceil(max(max(y)-min(y))./(2*mean(bw))); % (2)x bw -> mean instead of min or max

    num_bin_clusters = 10; % todo optimize these too someday
    max_conn_comp = [];
    gain_vals = 50:1:90;
    for gain = gain_vals
        gain
        [~, nodeBynode, ~, ~] = fcn_mapper_mapper2d_bdl_hex_binning(distMat, y, [res_val res_val], gain, num_bin_clusters, 6);
        G = graph(nodeBynode);
        [bins, binsizes] = conncomp(G);
        max_conn_comp = [max_conn_comp; max(binsizes)./size(nodeBynode,1)];
    end

    gain_val = find(max_conn_comp>=conn_perct); %dropped to 75 from 90%
    gain_val = gain_vals(gain_val(1)); % first value to reach 90% connectedness


end