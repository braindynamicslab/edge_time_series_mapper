function output = fcn_edgeMapper_get_default_mapper_parameters(auto_tune_flag)

output.metric_type = "correlation";
output.ndim = 2;

if auto_tune_flag
    output.mass_biggest_component = 0.8;
else
    output.res_val = 20;
    output.gain_val = 70;
    output.num_bin_cluster = 10;
    output.num_k = 20;
end

end