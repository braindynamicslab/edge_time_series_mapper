function average_values_per_mapper_node = fcn_mapper_average_at_each_mapper_node(mapper_nodeTpMat_assignment_matrix, values_per_data_point)

% mapper_nodeTpMat_assignment_matrix (num of mapper nodes x num of data points)
% values_per_data_point (num of data points x dimension of the relevant features of the data points)
% values_per_mapper_node (num of mapper nodes x dimension of the relevant
% features of the data points)

num_data_points_at_each_mapper_node = sum(mapper_nodeTpMat_assignment_matrix, 2);
sum_of_values_at_each_mapper_node = mapper_nodeTpMat_assignment_matrix * values_per_data_point;
average_values_per_mapper_node = sum_of_values_at_each_mapper_node./num_data_points_at_each_mapper_node;

end