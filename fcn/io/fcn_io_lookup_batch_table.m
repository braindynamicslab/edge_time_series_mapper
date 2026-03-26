function batch = fcn_io_lookup_batch_table(batch_table, subject, task, session)
    % Look up batch identifier for a specific scan
    
    % Vectorized row matching
    is_match = (batch_table.subject == subject) & ...
               strcmp(batch_table.task, task) & ...
               strcmp(batch_table.session, session);
    
    match_idx = find(is_match, 1);  % Find first match
    
    if isempty(match_idx)
        batch = "";
    else
        batch = batch_table.batch(match_idx);
    end
end