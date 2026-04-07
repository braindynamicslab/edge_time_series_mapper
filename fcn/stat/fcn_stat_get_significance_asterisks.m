function sig_code = fcn_stat_get_significance_asterisks(p_value)
    % Convert p-value to significance code
    %
    % Inputs:
    %   p_value - P-value (scalar)
    %
    % Outputs:
    %   sig_code - Significance code: "0", "*", "**", or "***"
    %              Returns missing for NaN p-values
    
    if ismissing(p_value) || isnan(p_value)
        sig_code = missing;
    elseif p_value >= 0.05
        sig_code = "0";
    elseif p_value < 0.001
        sig_code = "***";
    elseif p_value < 0.01
        sig_code = "**";
    else
        sig_code = "*";
    end
end