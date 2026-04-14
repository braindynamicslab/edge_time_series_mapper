function [lower, upper] = routine_construct_confidence_interval(estimate, standard_error, degree_freedom, significance, tail)
% Compute confidence interval for a sample mean
% Inputs:
%   estimate - sample mean estimate
%   standard_error - standard error of the estimate - sample standard
%   deviation divided by sqrt(degree_freedom)
%   degree_freedom - degree of freedom
%   significance - significance level (e.g., 0.05 for 95% confidence)
%   tail - 1 for one-tailed, 2 for two-tailed
% Outputs:
%   lower - lower bound of confidence interval
%   upper - upper bound of confidence interval

% Input validation
if tail ~= 1 && tail ~= 2
    error('tail must be 1 (one-tailed) or 2 (two-tailed)');
end

if tail == 2
    % Two-tailed confidence interval
    % Use significance/2 for each tail
    t_critical = tinv(1 - significance/2, degree_freedom);
    margin_of_error = t_critical * standard_error;
    
    lower = estimate - margin_of_error;
    upper = estimate + margin_of_error;
    
elseif tail == 1
    % One-tailed confidence interval
    % Include infinity on the side with same sign as estimate
    t_critical = tinv(1 - significance, degree_freedom);
    margin_of_error = t_critical * standard_error;
    
    if estimate >= 0
        % Positive estimate: interval extends to +infinity
        lower = estimate - margin_of_error;
        upper = Inf;
    else
        % Negative estimate: interval extends to -infinity
        lower = -Inf;
        upper = estimate + margin_of_error;
    end
end

end