function distMat = fcn_mapper_estimateDistance(X, metricType)
    distMat = squareform(pdist(X, metricType));
end

