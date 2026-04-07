function test_fcn_io_parse_simplex_mapper_directory_name_pca()
    % Test script for fcn_utils_parse_simplex_mapper_dirname
    %
    % Tests both valid and invalid directory name patterns to ensure
    % the regex correctly parses valid names and rejects invalid ones.
    
    fprintf('\n');
    fprintf('================================================================================\n');
    fprintf('TESTING: fcn_utils_parse_simplex_mapper_dirname\n');
    fprintf('================================================================================\n\n');
    
    % Track test results
    num_tests = 0;
    num_passed = 0;
    num_failed = 0;
    
    %% Valid Test Cases
    
    fprintf('VALID CASES (should parse successfully):\n');
    fprintf('--------------------------------------------------------------------------------\n\n');
    
    % Test 1: Basic case
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    expected = struct('cohort', "one", 'session', "LR", 'simplex', "edge", ...
                      'parcellation', "schaefer100x7", ...
                      'feature_processing', "pca_variance_threshold", ...
                      'target', "explained_variance", 'value', "0_95");
    if run_test(num_tests, "Basic case: cohort='one'", dirname, expected, true)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 2: Cohort with underscores
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_all_but_one_LR_edge_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    expected = struct('cohort', "all_but_one", 'session', "LR", 'simplex', "edge", ...
                      'parcellation', "schaefer100x7", ...
                      'feature_processing', "pca_variance_threshold", ...
                      'target', "explained_variance", 'value', "0_95");
    if run_test(num_tests, "Cohort with underscores: 'all_but_one'", dirname, expected, true)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 3: Session RL
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_RL_edge_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    expected = struct('cohort', "one", 'session', "RL", 'simplex', "edge", ...
                      'parcellation', "schaefer100x7", ...
                      'feature_processing', "pca_variance_threshold", ...
                      'target', "explained_variance", 'value', "0_95");
    if run_test(num_tests, "Session RL", dirname, expected, true)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 4: Simplex node
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_node_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    expected = struct('cohort', "one", 'session', "LR", 'simplex', "node", ...
                      'parcellation', "schaefer100x7", ...
                      'feature_processing', "pca_variance_threshold", ...
                      'target', "explained_variance", 'value', "0_95");
    if run_test(num_tests, "Simplex: node", dirname, expected, true)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 5: Simplex triangle
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_triangle_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    expected = struct('cohort', "one", 'session', "LR", 'simplex', "triangle", ...
                      'parcellation', "schaefer100x7", ...
                      'feature_processing', "pca_variance_threshold", ...
                      'target', "explained_variance", 'value', "0_95");
    if run_test(num_tests, "Simplex: triangle", dirname, expected, true)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 6: Different parcellation
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer200x17||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    expected = struct('cohort', "one", 'session', "LR", 'simplex', "edge", ...
                      'parcellation', "schaefer200x17", ...
                      'feature_processing', "pca_variance_threshold", ...
                      'target', "explained_variance", 'value', "0_95");
    if run_test(num_tests, "Parcellation: schaefer200x17", dirname, expected, true)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 7: Another parcellation
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer400x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    expected = struct('cohort', "one", 'session', "LR", 'simplex', "edge", ...
                      'parcellation', "schaefer400x7", ...
                      'feature_processing', "pca_variance_threshold", ...
                      'target', "explained_variance", 'value', "0_95");
    if run_test(num_tests, "Parcellation: schaefer400x7", dirname, expected, true)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 8: Feature processing fixed_component
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7||_dim_reduction_type_pca_fixed_component_target_num_features_20";
    expected = struct('cohort', "one", 'session', "LR", 'simplex', "edge", ...
                      'parcellation', "schaefer100x7", ...
                      'feature_processing', "pca_fixed_component", ...
                      'target', "num_features", 'value', "20");
    if run_test(num_tests, "Feature processing: pca_fixed_component", dirname, expected, true)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 9: Target num_features
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_num_features_50";
    expected = struct('cohort', "one", 'session', "LR", 'simplex', "edge", ...
                      'parcellation', "schaefer100x7", ...
                      'feature_processing', "pca_variance_threshold", ...
                      'target', "num_features", 'value', "50");
    if run_test(num_tests, "Target: num_features", dirname, expected, true)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 10: Value without underscore
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7||_dim_reduction_type_pca_fixed_component_target_num_features_30";
    expected = struct('cohort', "one", 'session', "LR", 'simplex', "edge", ...
                      'parcellation', "schaefer100x7", ...
                      'feature_processing', "pca_fixed_component", ...
                      'target', "num_features", 'value', "30");
    if run_test(num_tests, "Value format: '30' (no underscore)", dirname, expected, true)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 11: Value with single decimal
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_9";
    expected = struct('cohort', "one", 'session', "LR", 'simplex', "edge", ...
                      'parcellation', "schaefer100x7", ...
                      'feature_processing', "pca_variance_threshold", ...
                      'target', "explained_variance", 'value', "0_9");
    if run_test(num_tests, "Value format: '0_9'", dirname, expected, true)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 12: All different combinations
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_all_but_one_RL_triangle_schaefer200x17||_dim_reduction_type_pca_fixed_component_target_num_features_40";
    expected = struct('cohort', "all_but_one", 'session', "RL", 'simplex', "triangle", ...
                      'parcellation', "schaefer200x17", ...
                      'feature_processing', "pca_fixed_component", ...
                      'target', "num_features", 'value', "40");
    if run_test(num_tests, "All combinations valid", dirname, expected, true)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    %% Invalid Test Cases
    
    fprintf('\n');
    fprintf('INVALID CASES (should fail to parse):\n');
    fprintf('--------------------------------------------------------------------------------\n\n');
    
    % Test 13: Missing || marker
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    expected = struct();  % Empty - should fail
    if run_test(num_tests, "Missing || marker", dirname, expected, false)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 14: Invalid session
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_INVALID_edge_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    expected = struct();
    if run_test(num_tests, "Invalid session (not LR or RL)", dirname, expected, false)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 15: Invalid simplex
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_invalid_simplex_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    expected = struct();
    if run_test(num_tests, "Invalid simplex", dirname, expected, false)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 16: Invalid feature_processing
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7||_dim_reduction_type_pca_invalid_method_target_explained_variance_0_95";
    expected = struct();
    if run_test(num_tests, "Invalid feature_processing", dirname, expected, false)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 17: Invalid target
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_invalid_target_0_95";
    expected = struct();
    if run_test(num_tests, "Invalid target", dirname, expected, false)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 18: Invalid value (contains letters)
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_abc";
    expected = struct();
    if run_test(num_tests, "Invalid value (contains letters)", dirname, expected, false)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 19: Wrong prefix
    num_tests = num_tests + 1;
    dirname = "wrong_prefix_cohort_one_LR_edge_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    expected = struct();
    if run_test(num_tests, "Wrong prefix", dirname, expected, false)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 20: Missing field (incomplete pattern)
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    expected = struct();
    if run_test(num_tests, "Missing field (no simplex)", dirname, expected, false)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
% Test 21: Extra text at end (should fail due to $ anchor)
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_schaefer100x7||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95_extra_text";
    expected = struct();
    if run_test(num_tests, "Extra text at end ($ anchor should prevent)", dirname, expected, false)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    % Test 22: Wrong parcellation format
    num_tests = num_tests + 1;
    dirname = "simplex_mapper_raw_features_cohort_one_LR_edge_invalid_parcellation||_dim_reduction_type_pca_variance_threshold_target_explained_variance_0_95";
    expected = struct();
    if run_test(num_tests, "Wrong parcellation format", dirname, expected, false)
        num_passed = num_passed + 1;
    else
        num_failed = num_failed + 1;
    end
    
    %% Summary
    
    fprintf('\n');
    fprintf('================================================================================\n');
    fprintf('SUMMARY:\n');
    fprintf('  Total tests: %d\n', num_tests);
    fprintf('  Passed:      %d\n', num_passed);
    fprintf('  Failed:      %d\n', num_failed);
    if num_failed == 0
        fprintf('  Status:      ALL TESTS PASSED ✓✓✓\n');
    else
        fprintf('  Status:      SOME TESTS FAILED\n');
    end
    fprintf('================================================================================\n\n');
end

function passed = run_test(test_num, description, dirname, expected, should_succeed)
    % Helper function to run a single test
    %
    % Inputs:
    %   test_num - Test number
    %   description - Test description
    %   dirname - Directory name to parse
    %   expected - Expected output struct (empty if should fail)
    %   should_succeed - true if parsing should succeed, false otherwise
    %
    % Outputs:
    %   passed - true if test passed, false otherwise
    
    fprintf('Test %d: %s\n', test_num, description);
    fprintf('  Input: %s\n', dirname);
    
    % Suppress warnings for cleaner output
    warning('off', 'all');
    
    % Call the function
    [is_match, cohort, session, simplex, parcellation, feature_processing, target, value] = ...
        fcn_io_parse_simplex_mapper_directory_name_pca(dirname);
    
    % Re-enable warnings
    warning('on', 'all');
    
    % Check if parsing succeeded
    parse_succeeded = (cohort ~= "");
    
    if should_succeed
        % Test expects success
        if ~parse_succeeded
            fprintf('  Expected: SUCCESS\n');
            fprintf('  Got:      FAILED TO PARSE\n');
            fprintf('  Result:   FAIL ✗\n\n');
            passed = false;
            return;
        end
        
        % Check each field matches expected
        actual = struct('cohort', cohort, 'session', session, 'simplex', simplex, ...
                       'parcellation', parcellation, ...
                       'feature_processing', feature_processing, ...
                       'target', target, 'value', value);
        
        fields_match = true;
        field_names = fieldnames(expected);
        
        for field_idx = 1:numel(field_names)
            field = field_names{field_idx};
            if ~strcmp(actual.(field), expected.(field))
                fprintf('  Field "%s" mismatch:\n', field);
                fprintf('    Expected: "%s"\n', expected.(field));
                fprintf('    Got:      "%s"\n', actual.(field));
                fields_match = false;
            end
        end
        
        if fields_match
            fprintf('  Expected: cohort="%s", session="%s", simplex="%s, value=%s"\n', ...
                    expected.cohort, expected.session, expected.simplex);
            fprintf('  Got:      MATCH ✓\n');
            fprintf('  Result:   PASS ✓\n\n');
            passed = true;
        else
            fprintf('  Result:   FAIL ✗\n\n');
            passed = false;
        end
        
    else
        % Test expects failure
        if parse_succeeded
            fprintf('  Expected: SHOULD FAIL\n');
            fprintf('  Got:      Parsed successfully (cohort="%s")\n', cohort);
            fprintf('  Result:   FAIL ✗\n\n');
            passed = false;
        else
            fprintf('  Expected: SHOULD FAIL\n');
            fprintf('  Got:      Failed to parse ✓\n');
            fprintf('  Result:   PASS ✓\n\n');
            passed = true;
        end
    end
end