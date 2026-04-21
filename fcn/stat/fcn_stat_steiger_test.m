function [z_stat, p_value, f] = fcn_stat_steiger_test(r_jk, r_hm, r_jh, r_jm, r_kh, r_km, n)
    % Steiger's test for comparing two dependent correlations
    %
    % Tests H0: cor(j,k) = cor(h,m) where all variables from same sample
    %
    % Parameters:
    % -----------
    % r_jk : correlation between j and k (e.g., node_LR vs node_RL)
    % r_hm : correlation between h and m (e.g., edge_LR vs edge_RL)
    % r_jh : correlation between j and h (e.g., node_LR vs edge_LR)
    % r_jm : correlation between j and m (e.g., node_LR vs edge_RL)
    % r_kh : correlation between k and h (e.g., node_RL vs edge_LR)
    % r_km : correlation between k and m (e.g., node_RL vs edge_RL)
    % n    : effective sample size
    %
    % Returns:
    % --------
% z_stat  : test statistic (asymptotically N(0,1) under H0)
    % p_value : two-tailed p-value
    % f       : dependence parameter
    
    % Fisher Z-transformations
    z_jk = 0.500 * log((1 + r_jk) / (1 - r_jk));
    z_hm = 0.500 * log((1 + r_hm) / (1 - r_hm));
    
    % Calculate f parameter (measures dependence between correlations)
    term1 = (r_jh - r_jk * r_kh) * (r_km - r_jk * r_jm);
    term2 = (r_jm - r_jk * r_km) * (r_kh - r_jk * r_jh);
    term3 = (r_jh - r_jm * r_hm) * (r_km - r_hm * r_kh);
    term4 = (r_jm - r_jh * r_hm) * (r_kh - r_hm * r_km);
    
    numerator = term1 + term2 + term3 + term4;
    denominator = 2 * (1 - r_jk^2) * (1 - r_hm^2);
    
    f = numerator / denominator;
    
    % Standard error (accounts for dependence)
    se_squared = (1 / (n - 3)) * (2 * (1 - f^2) / (1 - r_jk^2)^2);
    se = sqrt(se_squared);
    
    % Test statistic
    z_stat = (z_jk - z_hm) / se;
    
    % Two-tailed p-value
    p_value = 2 * normcdf(-abs(z_stat));
end