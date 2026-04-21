function [confidence_interval_lower, confidence_interval_upper] = fcn_stat_correlation_confidence_interval(r, n, conf_level)
    % Compute confidence interval for a correlation using Fisher Z-transform
    % df for correlation is n - 2, but Fisher Z uses n - 3 for the standard error
    z = 0.500 * log((1 + r) / (1 - r));
    se_z = 1 / sqrt(n - 3);
    alpha = 1 - conf_level;
    z_crit = norminv(1 - alpha/2);
    z_lower = z - z_crit * se_z;
    z_upper = z + z_crit * se_z;
    confidence_interval_lower = (exp(2*z_lower) - 1) / (exp(2*z_lower) + 1);
    confidence_interval_upper = (exp(2*z_upper) - 1) / (exp(2*z_upper) + 1);
end