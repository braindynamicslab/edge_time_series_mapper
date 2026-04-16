
function squareformFC = fcn_utils_convert_flattenedFC_to_squareformFC(flattenedFC, idx, varargin)

% Assuming you have:
% idx - an n x 2 matrix of indices
% linearFC - a length-n vector of values

% Get the size of the output matrix

p = inputParser;
addParameter(p, "diagonal_entry", 1);
parse(p, varargin{:});

% n = length(flattenedFC);
max_row = max(idx(:, 1));
max_col = max(idx(:, 2));
n = max(max_row, max_col);

% Initialize the matrix with ones
squareformFC = p.Results.diagonal_entry * ones(n, n);

% Fill in the values using linear indexing
linear_idx = sub2ind(size(squareformFC), idx(:, 1), idx(:, 2));
linear_idx_transposed = sub2ind(size(squareformFC), idx(:, 2), idx(:, 1));
squareformFC(linear_idx) = flattenedFC;
squareformFC(linear_idx_transposed) = flattenedFC;
end

