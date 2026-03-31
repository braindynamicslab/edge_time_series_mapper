function test_compare_cohort_subject_lists()
    % Compare cohort subject lists before and after NA filtering
    %
    % Compares files with _noNAcheck suffix (old, no NA filtering) against
    % files without suffix (new, with NA filtering). Reports differences
    % and identifies subjects removed due to NA contamination.
    %
    % For each removed subject, checks if it's in the known problematic list.
    %
    % Example:
    %   fcn_io_compare_cohort_subject_lists();
    
    %% Configuration
    config = fcn_utils_get_config();
    
    cohort_dir_old = fullfile(config.repo_root, "data_pipeline", "data_cohort_old");
    cohort_dir = fullfile(config.repo_root, "data_pipeline", "data_cohort");
    
    % Define cohort and session combinations
    cohorts = ["one", "two", "all", "all_but_one", "all_but_one_two"];
    sessions = ["LR", "RL", "both"];
    
    % Known problematic subjects list
    known_problematic = [186545, 150524, 173738, 251833, 249947, 236130, 541640];
    
    %% Compare each cohort-session combination
    fprintf('\n=== Comparing Cohort Subject Lists ===\n\n');
    
    total_removed = 0;
    total_old = 0;
    
    for cohort = cohorts
        for session = sessions
            
            % Construct filenames
            base_filename = sprintf("cohort_%s_session_%s", cohort, session);
            old_filename = fullfile(cohort_dir, sprintf("%s_noNAcheck.csv", base_filename));
            new_filename = fullfile(cohort_dir, sprintf("%s.csv", base_filename));
            
            % Read files
            old_table = readtable(old_filename, "VariableNamingRule", "preserve");
            new_table = readtable(new_filename, "VariableNamingRule", "preserve");
            
            old_subjects = old_table.Subject;
            new_subjects = new_table.Subject;
            
            % Compute differences
            old_count = numel(old_subjects);
            new_count = numel(new_subjects);
            removed_subjects = setdiff(old_subjects, new_subjects);
            added_subjects = setdiff(new_subjects, old_subjects);
            removed_count = numel(removed_subjects);
            added_count = numel(added_subjects);
            percent_removed = 100 * removed_count / old_count;
            
            total_old = total_old + old_count;
            total_removed = total_removed + removed_count;
            
            % Print header
            fprintf('========================================\n');
            fprintf('Cohort: %-15s Session: %-4s\n', cohort, session);
            fprintf('Old: %4d | New: %4d | Removed: %3d (%.1f%%)\n', ...
                old_count, new_count, removed_count, percent_removed);
            
            % Print subjects in old but not in new (removed subjects)
            if removed_count > 0
                fprintf('\n  Subjects in OLD but NOT in NEW (removed due to NA):\n');
                for i = 1:removed_count
                    subject = removed_subjects(i);
                    in_known_list = ismember(subject, known_problematic);
                    if in_known_list
                        fprintf('    %d  [IN KNOWN PROBLEMATIC LIST]\n', subject);
                    else
                        fprintf('    %d\n', subject);
                    end
                end
            else
                fprintf('  No subjects removed\n');
            end
            
            % Print subjects in new but not in old (should not happen)
            if added_count > 0
                fprintf('\n  WARNING: Subjects in NEW but NOT in OLD (unexpected):\n');
                for i = 1:added_count
                    fprintf('    %d\n', added_subjects(i));
                end
            end
            
            % Sanity check: new should have fewer or equal subjects
            if new_count > old_count
                warning('Unexpected: New file has MORE subjects than old file for %s, %s', ...
                    cohort, session);
            end
            
            fprintf('\n');
        end
    end
    
    %% Overall statistics
    overall_percent = 100 * total_removed / total_old;
    
    fprintf('========================================\n');
    fprintf('=== Overall Statistics ===\n');
    fprintf('Total subjects (old): %d\n', total_old);
    fprintf('Total subjects (new): %d\n', total_old - total_removed);
    fprintf('Total removed: %d (%.2f%%)\n', total_removed, overall_percent);
    
    fprintf('\nComparison complete.\n');
end