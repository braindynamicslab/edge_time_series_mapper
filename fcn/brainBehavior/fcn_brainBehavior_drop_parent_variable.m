function control_variables_random_without_nesting = fcn_brainBehavior_drop_parent_variable(control_variables_random)
control_variables_random_without_nesting = control_variables_random;

% for i = 1:numel(control_variables_random)
%     raw_features = control_variables_random{i};
%     for j = 1:numel(control_variables_random{i})
%         parts = split(raw_features(i), ":");
%         raw_features(j) = parts(end);
%     end
%     control_variables_random_without_nesting{i} = raw_features;
% end

for j = 1:numel(control_variables_random)
    parts = split(control_variables_random(j), ":");
    control_variables_random_without_nesting(j) = parts(end);
end

end