% Read the CSV file
file_path = '/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/simplex_mappers_raw/simplex_mapper_pca_fixed_components_40_cohort_one_LR_triangle_schaefer100x7/summary_raw.csv';
data = readtable(file_path, 'VariableNamingRule', 'preserve');

% Find duplicates in the 'subject' column
[unique_subjects, first_idx] = unique(data.subject, 'first');
all_idx = (1:height(data))';

% Find indices that are NOT the first occurrence
duplicate_idx = setdiff(all_idx, first_idx);

% Display results
if isempty(duplicate_idx)
    disp('No duplicate subjects found.');
else
    fprintf('Found %d duplicate entries (non-first occurrences):\n\n', length(duplicate_idx));
    fprintf('Row Index\tSubject\n');
    fprintf('----------\t-------\n');
    for i = 1:length(duplicate_idx)
        row_idx = duplicate_idx(i);
        fprintf('%d\t\t%s\n', row_idx, data.subject(row_idx));
    end
    
    % Optional: Create a table for easier viewing
    duplicate_table = table(duplicate_idx, data.subject(duplicate_idx), ...
        'VariableNames', {'RowIndex', 'Subject'});
    disp(' ');
    disp('Duplicate entries table:');
    disp(duplicate_table);
end