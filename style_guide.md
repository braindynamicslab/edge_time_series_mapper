# MATLAB Style Guide for Computational Neuroscience

This style guide establishes coding conventions for computational neuroscience projects
using MATLAB as the primary analysis language, with support for Python and R.

**Version:** 1.0 (Draft)  
**Last Updated:** 2024-03-26  
**Status:** Living document - will evolve with project needs

---

## Purpose and Philosophy

### Goals

- **Readability:** Code should be easy to understand
- **Maintainability:** Easy to modify and extend
- **Reproducibility:** Anyone should be able to reproduce results
- **Collaboration:** Consistent style across team members

### Guiding Principles

1. **Functional programming** - Prefer functions over scripts
2. **Self-documenting code** - Clear names and structure
3. **Explicit over implicit** - Be clear about intent
4. **Separation of concerns** - Keep computation and presentation separate
5. **Consistency** - Follow conventions throughout the project

**Note:** These are guidelines, not rigid rules. Use judgment and prioritize clarity.
When you deviate from guidelines, document why.

---

## Requirements

- **MATLAB:** R2019b or later (for string features and `VariableNamingRule`)
- **Operating System:** Cross-platform (Windows, macOS, Linux)
- **HPC:** Stanford Sherlock cluster with SLURM (for this project)

---

## Table of Contents

1. [File Organization](#file-organization)
2. [Naming Conventions](#naming-conventions)
3. [String Conventions](#string-conventions)
4. [Data Structures](#data-structures)
5. [Functions](#functions)
6. [Documentation](#documentation)
7. [Code Style](#code-style)
8. [Error Handling](#error-handling)
9. [Path Management](#path-management)
10. [Numerical Precision](#numerical-precision)
11. [Data Presentation](#data-presentation)
12. [Testing](#testing)
13. [Version Control](#version-control)

---

## File Organization

### Directory Structure

```
project/
├── config/                    # Configuration files
│   ├── config_sherlock.m
│   ├── config_local.m
│   └── config_local_template.m
│
├── expt/                      # Experiment/analysis scripts
│   ├── expt_01_preprocessing.m
│   ├── expt_02_main_analysis.m
│   └── expt_260315_exploratory.m  (private/dated)
│
├── fcn/                       # Reusable functions
│   ├── io/                    # Input/output (or ioLoad/ if descriptive needed)
│   ├── stats/                 # Statistical functions
│   ├── viz/                   # Visualization (or vizPlot/ if needed)
│   ├── tabViz/                # Table formatting (descriptive camelCase)
│   └── utils/                 # Utility functions
│
├── slurm_script/              # SLURM job scripts
│   ├── slurm_script_01_preprocessing.sbatch
│   └── slurm_script_02_analysis.sbatch
│
├── test/                      # Test files
│   ├── test_correlation.m
│   └── test_preprocessing.m
│
├── data_raw/                  # Raw data (version controlled)
│   └── examples/              # Small example datasets
│
├── data_raw_gitignore/        # Raw data (gitignored - large/sensitive)
│
├── data_pipeline/             # Processed data (version controlled)
│   ├── results/
│   │   ├── internal/          # Full precision, snake_case
│   │   └── publication/       # Formatted for papers
│   └── temp/
│
├── data_pipeline_gitignore/   # Pipeline outputs (gitignored)
│
├── note_and_report/           # Documentation and reports
│
├── .gitignore
├── README.md
├── STYLE_GUIDE.md
└── requirements.txt           # Python dependencies (if applicable)
```

### File Naming

**Module folders:** Short names preferred, camelCase when descriptive clarity needed

```
fcn/io/          # Short, clear
fcn/stats/       # Short, clear
fcn/tabViz/      # camelCase for clarity (table visualization)
fcn/utilsConfig/ # camelCase for clarity (config utilities)
```

**Functions:** Prefix with module name

```
fcn/<module>/fcn_<module>_<descriptive_name>.m

Examples:
fcn/io/fcn_io_load_subject.m
fcn/stats/fcn_stats_compute_correlation.m
fcn/tabViz/fcn_tabViz_format_for_publication.m
fcn/utilsConfig/fcn_utilsConfig_get_config.m
```

**Rationale:** camelCase in module name (e.g., `tabViz`) makes it easier to visually
separate module from function name: `fcn_tabViz_format_for_publication`
- Module: `tabViz`
- Function: `format_for_publication` (snake_case)

**Experiment scripts:**

```
Public/final:  expt_<number>_<descriptive_name>.m
Private/dated: expt_<YYMMDD>_<descriptive_name>.m

Examples:
expt/expt_01_preprocessing.m
expt/expt_02_main_analysis.m
expt/expt_260315_exploratory_analysis.m  (private)
```

**SLURM scripts:**

```
slurm_script_<number>_<descriptive_name>.sbatch

Examples:
slurm_script/slurm_script_01_preprocessing.sbatch
slurm_script/slurm_script_02_analysis.sbatch
```

**Test files:**

```
test_<descriptive_name>.m

Examples:
test/test_correlation.m
test/test_preprocessing.m
```

---

## Naming Conventions

### General Rule: snake_case

**Use snake_case for all names** (variables, functions, files, table columns).

```matlab
% Correct
num_subjects = 100;
subject_idx = 1;
mean_activation = mean(data);
is_valid = true;

% Avoid
numSubjects = 100;      % camelCase
SubjectIdx = 1;         % PascalCase
meanactivation = mean(data);  % no separation
```

**Exception:** Module folder names may use camelCase for visual clarity (see File Naming above).

### Variable Naming Patterns

**Counts:** `num_<items>`
```matlab
num_subjects = 50;
num_rois = 264;
num_timepoints = 1200;
```

**Indices:** `<item>_idx`
```matlab
subject_idx = 1;
roi_idx = 42;
time_idx = 100;
```

**Booleans:** `is_<condition>`
```matlab
is_valid = true;
is_processed = false;
is_significant = (p_value < 0.05);
```

**Descriptive names:** Avoid single letters (except in very limited scopes)
```matlab
% Good
for subject_idx = 1:num_subjects
    for roi_idx = 1:num_rois
        correlation_matrix(subject_idx, roi_idx) = ...;
    end
end

% Avoid
for i = 1:n
    for j = 1:m
        corr(i, j) = ...;  % What are i, j, n, m?
    end
end
```

### Constants

**Use UPPER_CASE for constants:**

```matlab
% At top of function or in config
NUM_PERMUTATIONS = 1000;
ALPHA = 0.05;
MAX_ITERATIONS = 100;
```

---

## String Conventions

### Use Double Quotes

**Use double quotes `"` for all string literals.**

```matlab
% Correct
filename = "subject_01.mat";
subject_ids = ["sub-01", "sub-02", "sub-03"];
roi_name = "DLPFC";

% Avoid
filename = 'subject_01.mat';  % Single quotes (old character arrays)
```

**Exception:** Single quotes `'` for MATLAB built-in parameter values

```matlab
% Correct - Mix appropriately
title("Mean Activation")           % Our string - use "
plot(x, y, 'r', 'LineWidth', 2)   % MATLAB parameters - use '
set(gca, 'FontSize', 14)           % MATLAB parameters - use '
fid = fopen(filename, 'r')         % File mode - use '
corr(data, 'Type', 'Spearman')    % Method name - use '
```

### String Arrays (Not Cell Arrays)

**Use string arrays for collections of strings.**

```matlab
% Correct - String array
subject_ids = ["sub-01", "sub-02", "sub-03"];
first_id = subject_ids(1);  % Parentheses

for subject_id = subject_ids
    process(subject_id);  % Already a string
end

% Avoid - Cell array of strings
subject_ids = {"sub-01", "sub-02", "sub-03"};
first_id = subject_ids{1};  % Curly braces (confusing)

for subject_id = subject_ids
    process(subject_id{1});  % Must extract from cell
end
```

### String Concatenation

**Use `strcat()` for string concatenation** (not `+` or `[]`).

```matlab
% Correct
filename = strcat(subject_id, "_data.mat");
label = strcat("L_", roi_name);
full_label = strcat(hemisphere, "_", region, "_", metric);

% Avoid - Operator overloading
filename = subject_id + "_data.mat";  % Confusing with arithmetic

% Avoid - Array concatenation
filename = [subject_id, "_data.mat"];  % Confusing with array creation
```

**For file paths, use `fullfile()`:**

```matlab
% Correct - Cross-platform
filepath = fullfile(config.data_dir, strcat(subject_id, ".mat"));
path = fullfile("data", "processed", subject_id, "results.mat");

% Avoid - Manual delimiters
filepath = config.data_dir + "/" + subject_id + ".mat";  % Breaks on Windows
```

**For formatted strings, use `sprintf()`:**

```matlab
% Correct
label = sprintf("Subject %02d, Session %d", subject_idx, session_num);
msg = sprintf("Correlation: %.3f, p = %.4f", r_value, p_value);

% Avoid - Complex strcat
label = strcat("Subject ", num2str(subject_idx), ", Session ", num2str(session_num));
```

### String Comparison

**Use `strcmp()` for string comparison** (not `==`).

```matlab
% Correct - Explicit string comparison
if strcmp(filename, "target.mat")
    process(data);
end

% For arrays
matches = strcmp(filenames, "target.mat");  % Element-wise comparison

% Avoid - Ambiguous
if filename == "target.mat"  % Could mean array equality
    process(data);
end
```

**Rationale:** `strcmp()` explicitly indicates string comparison and is less ambiguous
than `==`, especially when working with string arrays.

**Use `strcmpi()` for case-insensitive comparison:**

```matlab
if strcmpi(method, "PEARSON")  % Matches "pearson", "Pearson", "PEARSON"
    % ...
end
```

**Use string methods for pattern matching:**

```matlab
% Correct - String methods
if filename.contains("subject")
    % ...
end

if filename.startsWith("sub-")
    % ...
end

if filename.endsWith(".mat")
    % ...
end

% Extract substrings
prefix = filename.extractBefore("_");
suffix = filename.extractAfter("_");
parts = filename.split("_");
```

### Converting Between Types

**Convert character arrays to strings immediately:**

```matlab
% Many MATLAB functions return char - convert to string
files = dir("*.mat");
filenames = string({files.name});  % Convert to string array

user = string(getenv("USER"));  % Convert to string
```

### Empty and Missing Strings

```matlab
% Empty string (zero length)
empty_str = "";
if strlength(str) == 0
    % Handle empty
end

// Missing value (like NaN for strings)
missing_str = missing;
if ismissing(str)
    % Handle missing
end
```

---

## Data Structures

### When to Use Each Type

| Type | Use Case | Example |
|------|----------|---------|
| **String array** | Collections of text | Subject IDs, filenames, ROI names |
| **Numeric array** | Homogeneous numbers | Timeseries, correlation matrices |
| **Table** | Tabular data with columns | Demographics, results |
| **Struct** | Hierarchical/related fields | Subject data with metadata |
| **Cell array** | Mixed types or ragged arrays | Trial data with varying lengths |

### Tables

**Reading tables: Always use `"VariableNamingRule", "preserve"`**

```matlab
% Correct - Preserve column names exactly as in file
data = readtable("participants.tsv", "FileType", "text", ...
                 "TextType", "string", ...
                 "VariableNamingRule", "preserve");

% Access columns (assuming snake_case headers in file)
subject_ids = data.subject_id;
ages = data.age;
```

**Creating tables: Use snake_case for variable names**

```matlab
% Correct
results = table(subject_ids, mean_values, std_values, ...
                'VariableNames', {'subject_id', 'mean_value', 'std_value'});
```

**For external data without snake_case headers, rename if used extensively:**

```matlab
% External data with different naming
external = readtable("external.csv", "VariableNamingRule", "preserve");

% If used extensively in code, rename for consistency
external.Properties.VariableNames = {'subject_id', 'age', 'group'};
```

### File Format: CSV vs TSV

**Choose based on your data and workflow. Either is acceptable - be consistent within a project.**

**Use CSV when:**
- Simple data with no commas in values
- Maximum compatibility (universal format)
- No specific downstream tool requirements

**Use TSV when:**
- Data may contain commas (addresses, formatted numbers, lists)
- Working with neuroimaging tools (BIDS standard uses TSV)
- Interfacing with FSL, fMRIPrep, xcp-d outputs
- Avoiding the Excel semicolon problem*

**Excel semicolon problem:** In some locales, Excel saves CSV files with semicolons
as delimiters instead of commas, which can cause import errors. TSV avoids this issue.

**Recommendation:** For neuroimaging projects, TSV is often preferred due to BIDS
compliance and tool compatibility. Ask yourself: "Will this data interface with
neuroimaging software?" If yes, use TSV.

```matlab
% CSV
writetable(data, "output.csv");
data = readtable("input.csv");

// TSV
writetable(data, "output.tsv", "FileType", "text");
data = readtable("input.tsv", "FileType", "text");
```

### Structs

**Use snake_case for field names:**

```matlab
% Correct
data.subject_id = "sub-01";
data.timeseries = rand(100, 264);
data.roi_names = ["DLPFC", "PCC", "V1"];
data.metadata.tr = 2.0;
data.metadata.num_volumes = 100;

% Avoid
data.subjectID = "sub-01";  % camelCase
data.SubjectID = "sub-01";  % PascalCase
```

### Cell Arrays

**Use only when necessary** (mixed types or ragged arrays):

```matlab
% Appropriate - Mixed types
mixed_data = {subject_id, timeseries, roi_names};

% Appropriate - Ragged arrays (different lengths per element)
trial_data = cell(num_trials, 1);
for trial_idx = 1:num_trials
    trial_data{trial_idx} = load_trial(trial_idx);  % Each trial different length
end

% Avoid - Use string array instead
subject_ids = {"sub-01", "sub-02", "sub-03"};  % Should be string array

% Avoid - Use struct instead
data = {subject_id, age, sex};  % Hard to remember element order
```

---

## Functions

### Function Structure

**Every function should have:**

1. Function signature with descriptive name
2. Documentation header (description, inputs, outputs, example)
3. Input parsing and validation
4. Main logic
5. Return values

```matlab
function results = fcn_stats_compute_correlation(data, method, varargin)
    % Compute correlation matrix between variables
    %
    % Longer description if needed. Explain algorithm, assumptions,
    % or theoretical background.
    %
    % Inputs:
    %   data - [N x M] matrix of observations (rows) by variables (columns)
    %   method - Correlation method: "pearson" or "spearman"
    %
    % Optional Parameters (name-value pairs):
    %   'threshold' - Minimum correlation threshold (default: 0)
    %   'save_flag' - Save results to file: 1=yes, 0=no (default: 0)
    %
    % Outputs:
    %   results - [M x M] correlation matrix
    %
    % Example:
    %   data = randn(100, 5);
    %   corr_mat = fcn_stats_compute_correlation(data, "pearson", ...
    %                                             'threshold', 0.3);
    %
    % See also: fcn_stats_partial_correlation, corrcoef
    
    % Parse inputs
    p = inputParser;
    addRequired(p, 'data', @isnumeric);
    addRequired(p, 'method', @ischar);
    addParameter(p, 'threshold', 0, @isnumeric);
    addParameter(p, 'save_flag', 0, @isnumeric);
    parse(p, data, method, varargin{:});
    
    % Extract for readability
    threshold = p.Results.threshold;
    save_flag = p.Results.save_flag;
    method = string(method);
    
    % Validate inputs
    assert(size(data, 1) > size(data, 2), ...
        'Data should be [observations x variables], got [%d x %d]', ...
        size(data, 1), size(data, 2));
    assert(strcmp(method, "pearson") || strcmp(method, "spearman"), ...
        'Method must be "pearson" or "spearman", got "%s"', method);
    
    % Main computation
    results = corr(data, 'Type', char(method));
    
    % Apply threshold if specified
    if threshold > 0
        results(abs(results) < threshold) = 0;
    end
    
    % Optional save
    if save_flag
        save('correlation_matrix.mat', 'results');
    end
end
```

### Optional Parameters

**Use name-value pairs with `varargin` for all optional parameters and flags.**

```matlab
% Correct - Self-documenting
results = fcn_analysis(data, 'save_flag', 1, 'plot_flag', 0, ...
                       'verbose_flag', 1, 'method', "robust");

% Avoid - Positional flags (unreadable)
results = fcn_analysis(data, 1, 0, 1, "robust");  % Which parameter is which?
```

**Rationale:** Name-value pairs make function calls self-documenting. Users don't
need to remember parameter order, and intent is clear.

### Boolean Flags

**Accept numeric `0`/`1` for boolean parameters.**

Prefer `0`/`1` for readability (especially in long parameter lists), but `true`/`false`
are also acceptable.

```matlab
% Preferred - Easy to scan
results = fcn_analysis(data, 'save_flag', 1, 'plot_flag', 0, ...
                       'verbose_flag', 0, 'debug_flag', 0);

% Also acceptable
results = fcn_analysis(data, 'save_flag', true, 'plot_flag', false);

% Function implementation - accept numeric
addParameter(p, 'save_flag', 0, @isnumeric);  % Accepts 0, 1, true, false

% MATLAB treats 0 as false, non-zero as true
if save_flag
    save(output_file, 'results');
end
```

### Function Length and Modularity

**General guideline: Keep functions focused and reasonably sized.**

**Extract to separate function when:**
- Logic is used more than twice (DRY principle)
- Function has a clear, separable responsibility
- Testing would be easier with separation
- Code becomes hard to follow

**Keep in single function when:**
- Extensive parameter passing between steps (overhead not worth it)
- Tightly coupled logic where splitting reduces clarity
- Unique to one specific analysis (not reusable)
- Function has many case switches or parameter parsing (may be longer but acceptable)

**Note:** There's no strict line limit. A well-organized 200-line function with clear
sections can be better than artificially splitting into many tiny functions. Use judgment.

```matlab
% Good - Modular when it makes sense
function results = fcn_analysis_pipeline(data, config)
    preprocessed = preprocess_data(data, config);
    analyzed = analyze_data(preprocessed, config);
    results = format_results(analyzed);
end

% Also good - Longer function with clear sections
function results = fcn_analysis_process(data, config)
    %% Validate inputs
    % ... validation code
    
    %% Preprocess
    % ... preprocessing code
    
    %% Main analysis
    % ... analysis code
    
    %% Format output
    % ... formatting code
end
```

---

## Documentation

### Function Headers

**Every function must have a documentation header** with:
- Brief one-line description
- Longer description (if needed)
- Inputs with descriptions and dimensions
- Optional parameters
- Outputs
- Example usage
- Related functions (See also)

**Level of detail:**
- **High-level/user-facing functions:** Comprehensive documentation
- **Low-level helpers:** Minimal documentation if purpose is obvious

```matlab
% High-level function - Detailed
function results = fcn_analysis_compute_connectivity(data, config)
    % Compute functional connectivity between brain regions
    %
    % Implements Pearson correlation with optional Fisher z-transform
    % and significance testing via permutation. Follows methodology
    % from Smith et al. (2020).
    %
    % Inputs:
    %   data - [time x ROIs] BOLD timeseries
    %   config - Configuration struct with fields:
    %            .method - "pearson" or "spearman"
    %            .num_permutations - Number of permutations for significance
    %
    % Outputs:
    %   results - Struct with fields:
    %             .connectivity_matrix - [ROIs x ROIs] correlation matrix
    %             .p_values - [ROIs x ROIs] significance values
    %             .z_scores - [ROIs x ROIs] Fisher z-transformed values
    %
    % Example:
    %   data = randn(200, 264);  % 200 timepoints, 264 ROIs
    %   config.method = "pearson";
    %   config.num_permutations = 1000;
    %   results = fcn_analysis_compute_connectivity(data, config);
    %
    % See also: fcn_stats_compute_correlation, fcn_stats_permutation_test

% Low-level helper - Minimal
function z = fisher_z_transform(r)
    % Fisher z-transform of correlation coefficient
    z = 0.5 * log((1 + r) ./ (1 - r));
end
```

### Comments

**Comment to explain *why*, not *what*.**

```matlab
% Good - Explains reasoning
% Use Spearman correlation because fMRI data often has outliers
corr_matrix = corr(data, 'Type', 'Spearman');

% Apply Bonferroni correction for multiple comparisons
threshold = 0.05 / num_comparisons;

% Bad - States the obvious
% Compute correlation matrix
corr_matrix = corr(data);

% Set threshold
threshold = 0.05 / num_comparisons;
```

**Comment above code blocks, not inline (unless truly clarifying):**

```matlab
% Good - Comment above
% Exclude subjects with excessive head motion
for subject_idx = 1:num_subjects
    if mean_fd(subject_idx) > motion_threshold
        excluded_subjects(end+1) = subject_idx;
    end
end

% Avoid - Unnecessary inline comments
for subject_idx = 1:num_subjects  % Loop through subjects
    if mean_fd(subject_idx) > motion_threshold  % Check if motion exceeds threshold
        excluded_subjects(end+1) = subject_idx;  % Add to exclusion list
    end
end
```

---

## Code Style

### Loops

**Use descriptive index names:**

```matlab
% Correct
for subject_idx = 1:num_subjects
    process_subject(subjects(subject_idx));
end

for roi_idx = 1:num_rois
    activation(roi_idx) = mean(data(:, roi_idx));
end

% Avoid - Single letters
for i = 1:num_subjects
    process_subject(subjects(i));
end
```

**Use `numel()` for robustness** (handles row/column arrays):

```matlab
% Correct - Works for both row and column arrays
for subject_idx = 1:numel(subjects)
    process_subject(subjects(subject_idx));
end

% Less robust - Ambiguous for matrices
for subject_idx = 1:length(subjects)
    process_subject(subjects(subject_idx));
end
```

**Vectorize when clear and readable:**

```matlab
% Good - Simple vectorization
mean_values = mean(data, 1);

% Also good - Loop when vectorization is complex
% Sometimes a loop is more readable than complicated array operations
for roi_idx = 1:num_rois
    % Complex multi-step computation
    filtered = bandpass_filter(data(:, roi_idx));
    normalized = normalize(filtered);
    result(roi_idx) = compute_metric(normalized);
end
```

### Semicolons

**Always use semicolons to suppress output:**

```matlab
% Correct
data = load(filepath);
results = process(data);

% Avoid - Clutters console
data = load(filepath)  % Dumps entire structure to console
results = process(data)  % Shows all output
```

### Whitespace

**Use blank lines to separate logical sections:**

```matlab
function results = fcn_process(data, config)
    % Documentation
    
    % Parse and validate inputs
    assert(isnumeric(data), 'Data must be numeric');
    assert(isfield(config, 'method'), 'Config must have method field');
    
    % Load additional data if needed
    roi_definitions = load(config.roi_file);
    atlas_labels = load(config.atlas_file);
    
    % Main processing
    filtered = apply_filter(data, config);
    normalized = normalize_data(filtered);
    
    % Compute results
    results.mean = mean(normalized, 1);
    results.std = std(normalized, 0, 1);
    results.roi_names = atlas_labels.names;
    
    % Optional outputs
    if config.save_flag
        save(config.output_file, 'results');
    end
end
```

---

## Error Handling

### Input Validation

**Use `assert()` for validation with helpful messages:**

```matlab
function results = fcn_process(data, threshold, config)
    % Validate inputs
    assert(isnumeric(data), 'Data must be numeric, got %s', class(data));
    assert(ismatrix(data), 'Data must be a 2D matrix');
    assert(threshold >= 0 && threshold <= 1, ...
        'Threshold must be in [0, 1], got %.2f', threshold);
    assert(isstruct(config), 'Config must be a struct');
    
    % Process
    results = process(data, threshold, config);
end
```

**Provide helpful, specific error messages:**

```matlab
% Good - Specific and actionable
assert(exist(filepath, 'file'), ...
    'File not found: %s\nPlease check the path or run preprocessing first.', ...
    filepath);

% Bad - Generic
assert(exist(filepath, 'file'), 'Error: file not found');
```

### Warnings

**Use `warning()` for non-fatal issues:**

```matlab
if num_subjects < 20
    warning('Small sample size (N=%d). Results may be unreliable.', ...
            num_subjects);
end

if ~exist(config.output_dir, 'dir')
    warning('Output directory does not exist: %s\nCreating directory.', ...
            config.output_dir);
    mkdir(config.output_dir);
end
```

---

## Path Management

### Building Paths

**Always use `fullfile()` for cross-platform compatibility:**

```matlab
% Correct - Works on Windows, macOS, Linux
filepath = fullfile(config.data_dir, strcat(subject_id, ".mat"));
output_path = fullfile(config.output_dir, "results", "figures", "plot.png");

% Avoid - Manual delimiters break on Windows
filepath = strcat(config.data_dir, "/", subject_id, ".mat");
```

### Relative vs Absolute Paths

**Use relative paths for portability:**

```matlab
% Good - Relative to repository root
repo_root = fcn_utilsConfig_detect_repo_root();
data_dir = fullfile(repo_root, 'data_raw', 'examples');

% Avoid - Hardcoded absolute paths
data_dir = '/Users/yourname/Documents/project/data';  % Not portable!
```

**Exception:** Configuration files may use absolute paths for HPC environments:

```matlab
% In config_sherlock.m - absolute paths OK here
config.data_dir = '/oak/stanford/groups/yourgroup/data/raw';
config.scratch_dir = '/scratch/users/youruser/temp';
```

---

## Numerical Precision

### Saving Data

**Save with full precision - never truncate when saving:**

```matlab
% Correct - Full precision preserved
correlation_value = 0.456789123456789;
save('results.mat', 'correlation_value');  % Saves all digits

% Write to CSV/TSV
writetable(results, 'output.csv');  % Full precision
```

### Displaying Data

**Display with 3 significant figures for readability:**

```matlab
% Correct - Format for display
fprintf('Mean correlation: %.3g\n', correlation_value);  % "0.457"
fprintf('P-value: %.3g\n', p_value);  % "0.00123" or "1.23e-3"

% For formatted tables
formatted_value = round(value, 3, 'significant');
```

**Never truncate when:**
- Saving to files (.mat, .csv, .tsv)
- Performing intermediate calculations
- Computing statistical tests

**Do truncate when:**
- Printing to console
- Creating publication tables
- Generating reports
- Displaying in figures

---

## Data Presentation

### Internal vs Presentation Format

**Maintain clear separation between internal (computational) and presentation (publication) data.**

**Internal data characteristics:**
- snake_case column names
- Full numerical precision
- Machine-readable format
- Optimized for computation and reproducibility

**Presentation data characteristics:**
- Human-readable names (spaces, capitalization)
- Fixed significant figures (typically 3)
- Formatted for readability
- Optimized for papers, reports, presentations

### Never Modify Internal Data

**Always create separate presentation versions - never overwrite internal results.**

```matlab
% BAD - Destroys precision and consistency
results.mean_correlation = round(results.mean_correlation, 3);
results.Properties.VariableNames = {'ROI Name', 'Mean Correlation'};

% GOOD - Keep internal, create presentation copy
internal_results = results;  % Keep original
pub_results = fcn_tabViz_format_for_publication(results);
```

### Presentation Workflow

**Standard workflow for creating publication-ready tables:**

```matlab
% Step 1: Analysis produces internal results (full precision, snake_case)
results = compute_analysis(data, config);
writetable(results, fullfile(config.output_dir, "results", "internal", ...
                             "connectivity_results.csv"));

% Step 2: Create presentation version (formatted, readable names)
pub_table = fcn_tabViz_format_for_publication(results);
writetable(pub_table, fullfile(config.output_dir, "results", "publication", ...
                               "table1_connectivity.csv"));

% Step 3: Manual review before including in paper
```

### Name Conversion Dictionary

**Maintain a central dictionary for internal → presentation name mappings:**

Create `fcn/tabViz/fcn_tabViz_get_name_dictionary.m`:

```matlab
function name_dict = fcn_tabViz_get_name_dictionary()
    % Project-wide dictionary for converting internal to presentation names
    
    % ROI names
    roi_names = [
        "l_dlpfc", "Left DLPFC";
        "r_dlpfc", "Right DLPFC";
        "l_pcc", "Left PCC";
        "r_pcc", "Right PCC"
    ];
    
    % Metric names
    metric_names = [
        "mean_activation", "Mean Activation";
        "std_activation", "SD Activation";
        "p_value", "P-value";
        "num_subjects", "N"
    ];
    
    % Combine and create dictionary
    all_mappings = [roi_names; metric_names];
    name_dict = dictionary(all_mappings(:, 1), all_mappings(:, 2));
end
```

**Fallback for unmapped names:**

```matlab
% If name not in dictionary, auto-format
% "mean_activation" → "Mean Activation"
if ~isKey(name_dict, internal_name)
    readable_name = auto_format_name(internal_name);
end
```

### Number Formatting Rules

**Apply context-specific formatting:**

| Value Type | Format | Example |
|------------|--------|---------|
| **P-values** | < 0.001 or 3 decimals | "< 0.001" or "0.043" |
| **Correlations** | 3 decimal places | "0.457" |
| **Percentages** | 1 decimal + % | "23.5%" |
| **Counts** | Integer | "42" |
| **General** | 3 significant figures | "0.457" or "1.23e4" |

```matlab
% P-value formatting
function formatted = format_p_value(p)
    if p < 0.001
        formatted = "< 0.001";
    else
        formatted = sprintf("%.3f", p);
    end
end

% General formatting
formatted = sprintf("%.3g", value);  % 3 sig figs
```

### Directory Organization

```
data_pipeline/
└── results/
    ├── internal/              # Never modify - full precision, snake_case
    │   ├── connectivity_results.csv
    │   └── activation_results.csv
    │
    └── publication/           # Formatted for papers
        ├── table1_connectivity.csv
        ├── table2_activation.csv
        └── README.md          # Describes table contents
```

### Example: Formatting Function

```matlab
function pub_table = fcn_tabViz_format_for_publication(internal_table)
    % Convert internal results to publication-ready format
    %
    % Inputs:
    %   internal_table - Table with snake_case columns, full precision
    %
    % Outputs:
    %   pub_table - Formatted table with readable names, rounded values
    
    pub_table = internal_table;
    
    % Get name dictionary
    name_dict = fcn_tabViz_get_name_dictionary();
    
    % Round numeric columns to 3 sig figs
    for col_idx = 1:width(pub_table)
        col_name = pub_table.Properties.VariableNames{col_idx};
        col_data = pub_table.(col_name);
        
        if isnumeric(col_data)
            if contains(col_name, "p_value")
                % Special p-value formatting
                pub_table.(col_name) = format_p_values(col_data);
            elseif contains(col_name, "count") || contains(col_name, "num_")
                % Keep as integers
                pub_table.(col_name) = round(col_data);
            else
                % 3 significant figures
                pub_table.(col_name) = round(col_data, 3, 'significant');
            end
        elseif isstring(col_data)
            % Convert string values using dictionary
            for row_idx = 1:height(pub_table)
                if isKey(name_dict, col_data(row_idx))
                    pub_table.(col_name)(row_idx) = name_dict(col_data(row_idx));
                end
            end
        end
    end
    
    // Convert column names
    new_names = cell(1, width(pub_table));
    for col_idx = 1:width(pub_table)
        old_name = pub_table.Properties.VariableNames{col_idx};
        if isKey(name_dict, old_name)
            new_names{col_idx} = char(name_dict(old_name));
        else
            new_names{col_idx} = auto_format_name(old_name);
        end
    end
    pub_table.Properties.VariableNames = new_names;
end

function formatted = format_p_values(p_values)
    % Format array of p-values
    formatted = strings(size(p_values));
    for idx = 1:numel(p_values)
        if isnan(p_values(idx))
            formatted(idx) = "—";
        elseif p_values(idx) < 0.001
            formatted(idx) = "< 0.001";
        else
            formatted(idx) = sprintf("%.3f", p_values(idx));
        end
    end
end

function formatted = auto_format_name(snake_case_name)
    % Auto-format: "mean_activation" → "Mean Activation"
    formatted = strrep(snake_case_name, "_", " ");
    words = split(formatted, " ");
    for idx = 1:numel(words)
        if strlength(words(idx)) > 0
            words(idx) = upper(extractBefore(words(idx), 2)) + ...
                         extractAfter(words(idx), 1);
        end
    end
    formatted = join(words, " ");
end
```

### Best Practices

1. **Never overwrite internal results** - Always create new files for presentation
2. **Document formatting decisions** - Keep conversion functions well-documented
3. **Version control formatting scripts** - Make table creation reproducible
4. **Review before publication** - Manually inspect formatted tables
5. **Use consistent dictionaries** - One central name dictionary, update as needed

---

## Testing

### Test Organization

**Tests in `test/` directory, named `test_<descriptive_name>.m`:**

```
test/
├── test_correlation.m
├── test_preprocessing.m
└── test_io_functions.m
```

### What to Test

**Test what needs testing:**
- Public API functions
- Complex algorithms
- Edge cases and boundary conditions
- Private helpers if they contain critical logic

**Don't over-test:**
- Simple wrapper functions
- Obvious transformations
- MATLAB built-in functions

```matlab
% test/test_correlation.m
function test_correlation()
    % Test correlation computation
    
    fprintf('Testing correlation functions...\n');
    
    % Test 1: Perfect positive correlation
    data = [1, 2, 3; 1, 2, 3]';
    result = fcn_stats_compute_correlation(data, "pearson");
    assert(abs(result(1,2) - 1) < 1e-10, 'Perfect correlation should be 1');
    fprintf('  ✓ Perfect positive correlation\n');
    
    % Test 2: Perfect negative correlation
    data = [1, 2, 3; 3, 2, 1]';
    result = fcn_stats_compute_correlation(data, "pearson");
    assert(abs(result(1,2) + 1) < 1e-10, 'Negative correlation should be -1');
    fprintf('  ✓ Perfect negative correlation\n');
    
    % Test 3: Invalid method should error
    try
        fcn_stats_compute_correlation(data, "invalid_method");
        error('Should have thrown error for invalid method');
    catch ME
        assert(contains(ME.message, 'pearson') || contains(ME.message, 'spearman'));
        fprintf('  ✓ Invalid method detection\n');
    end
    
    fprintf('All correlation tests passed!\n\n');
end
```

---

## Version Control

### Git Commits

**Write descriptive commit messages:**

```bash
# Good - Specific and clear
git commit -m "Add correlation analysis with permutation testing"
git commit -m "Fix off-by-one error in ROI indexing"
git commit -m "Update README with installation instructions"

# Bad - Vague
git commit -m "Update"
git commit -m "Fix bug"
git commit -m "Changes"
```

**For significant changes, use commit message body:**

```bash
git commit -m "Add parallel processing support

- Implement parfor loops for subject-level processing
- Add num_workers parameter to configuration
- Update documentation with parallel computing requirements
- Tested with 1-16 workers on Sherlock"
```

### What to Commit

**Do commit:**
- All source code
- Configuration templates
- Documentation
- Small example data (< 10 MB)
- Test files
- SLURM script templates

**Don't commit:**
- Large data files (use `*_gitignore/` folders)
- Generated results
- User-specific configs (e.g., `config_local.m` if it contains local paths)
- Temporary files
- Binary outputs

---

## Parallel Processing

### Starting Parallel Pools

**Check for existing pool before starting:**

```matlab
if config.num_workers > 1
    pool = gcp('nocreate');  % Get current pool without creating
    
    if isempty(pool)
        parpool(config.num_workers);
    elseif pool.NumWorkers ~= config.num_workers
        delete(pool);
        parpool(config.num_workers);
    end
end

% Run parallel computation
parfor subject_idx = 1:num_subjects
    results{subject_idx} = process_subject(subjects(subject_idx), config);
end
```

### Parallel Loop Best Practices

```matlab
% Correct - Descriptive indices, preallocated results
results = cell(num_subjects, 1);
parfor subject_idx = 1:num_subjects
    results{subject_idx} = process_subject(subjects(subject_idx), config);
end

% Avoid - Single letter indices
parfor i = 1:num_subjects
    results{i} = process_subject(subjects(i), config);
end
```

---

## Common Patterns

### Loading Subject Data

```matlab
function data = fcn_io_load_subject(subject_id, config)
    % Load subject data from file
    %
    % Inputs:
    %   subject_id - Subject identifier (e.g., "sub-01")
    %   config - Configuration struct with data_dir field
    %
    % Outputs:
    %   data - Loaded data struct
    
    filepath = fullfile(config.data_dir, strcat(subject_id, ".mat"));
    
    assert(exist(filepath, 'file'), ...
        'Subject file not found: %s\nCheck data_dir: %s', ...
        filepath, config.data_dir);
    
    data = load(filepath);
end
```

### Iterating Over Subjects

```matlab
% Read subject list
subjects = readtable("participants.tsv", "FileType", "text", ...
                     "TextType", "string", ...
                     "VariableNamingRule", "preserve");
subject_ids = subjects.subject_id;

% Preallocate results
num_subjects = numel(subject_ids);
results = cell(num_subjects, 1);

% Process each subject
for subject_idx = 1:num_subjects
    subject_id = subject_ids(subject_idx);
    
    fprintf('Processing %s (%d/%d)...\n', subject_id, ...
            subject_idx, num_subjects);
    
    % Load and process
    data = fcn_io_load_subject(subject_id, config);
    results{subject_idx} = fcn_analysis_process(data, config);
end

fprintf('Processing complete for %d subjects.\n', num_subjects);
```

### Processing with Optional Outputs

```matlab
function results = fcn_analysis_process(data, varargin)
    % Process data with optional save and plot
    
    p = inputParser;
    addRequired(p, 'data');
    addParameter(p, 'save_flag', 0, @isnumeric);
    addParameter(p, 'plot_flag', 0, @isnumeric);
    addParameter(p, 'output_dir', pwd, @ischar);
    parse(p, data, varargin{:});
    
    save_flag = p.Results.save_flag;
    plot_flag = p.Results.plot_flag;
    output_dir = string(p.Results.output_dir);
    
    % Main processing
    results = process(data);
    
    % Optional save
    if save_flag
        output_file = fullfile(output_dir, "results.mat");
        save(output_file, 'results');
        fprintf('Results saved to: %s\n', output_file);
    end
    
    % Optional plot
    if plot_flag
        figure;
        plot(results.timeseries);
        title("Processed Results");
        
        if save_flag
            saveas(gcf, fullfile(output_dir, "results.png"));
        end
    end
end
```

---

## Summary

### Key Principles

1. **Functional programming** - Functions over scripts
2. **snake_case everywhere** - Except camelCase for module folder names
3. **Double quotes `"`** - For strings (except MATLAB parameters use `'`)
4. **`strcat()` and `fullfile()`** - For concatenation and paths
5. **`strcmp()`** - For string comparison
6. **Name-value pairs** - For optional parameters
7. **Descriptive names** - No single letters (except limited scope)
8. **Self-documenting code** - Comments explain why, not what
9. **Full precision internally** - 3 sig figs for display only
10. **Separate presentation from computation** - Internal vs publication data

### Quick Reference Card

```matlab
% ===== NAMING =====
num_subjects = 100;              % Counts: num_<items>
subject_idx = 1;                 % Indices: <item>_idx
is_valid = true;                 % Booleans: is_<condition>
ALPHA = 0.05;                    % Constants: UPPER_CASE

% ===== STRINGS =====
filename = "subject_01.mat";     % Use double quotes "
label = strcat("L_", roi_name);  % Concatenate with strcat()
filepath = fullfile(dir, file);  % Paths with fullfile()
if strcmp(method, "pearson")     % Compare with strcmp()

% ===== TABLES =====
data = readtable("file.tsv", "FileType", "text", ...
                 "TextType", "string", ...
                 "VariableNamingRule", "preserve");

% ===== FUNCTIONS =====
function results = fcn_module_name(data, varargin)
    % Brief description
    %
    % Inputs:
    %   data - Description
    %
    % Optional Parameters:
    %   'param' - Description (default: value)
    %
    % Outputs:
    %   results - Description
    %
    % Example:
    %   results = fcn_module_name(data, 'param', value);
    
    % Parse inputs
    p = inputParser;
    addRequired(p, 'data');
    addParameter(p, 'param', default_value);
    parse(p, data, varargin{:});
    
    % Validate
    assert(condition, 'Error message');
    
    % Process
    results = process(data);
end

% ===== LOOPS =====
for subject_idx = 1:numel(subjects)
    process(subjects(subject_idx));
end

% ===== PRECISION =====
save('data.mat', 'value');       % Full precision
fprintf('Value: %.3g\n', value); % 3 sig figs for display
```

---

## Exceptions and Flexibility

### When to Break the Rules

These are guidelines, not rigid laws. **Use judgment** and prioritize clarity.

**Break rules when:**
- Legacy code integration requires different conventions
- External tools/data dictate format
- Performance is critical and style impacts it
- Readability is clearly improved by deviation
- Mathematical notation has established conventions

**But always:** Document why you're deviating.

```matlab
% Using standard mathematical notation (single letters acceptable here)
% Following convention from Boyd & Vandenberghe (2004)
A = design_matrix;  % Design matrix (n x p)
x = parameters;     % Parameter vector
b = observations;   % Observation vector
x_hat = A \ b;      % Least squares solution (standard notation)
```

---

## Language-Specific Notes

### MATLAB Version Requirements

**Minimum: MATLAB R2019b** (for string features and `VariableNamingRule`)

**Don't use:**
- `arguments` block (not available before R2019b, avoid for compatibility)
- Features from very recent releases without documentation

**Recommended toolboxes:**
- Statistics and Machine Learning Toolbox
- Signal Processing Toolbox
- Parallel Computing Toolbox (for `parfor`)

### Python and R

**This style guide focuses on MATLAB.** Python and R guidelines will be developed
as needed for multi-language projects.

**General principle:** Follow language-specific conventions:
- **Python:** PEP 8, snake_case throughout
- **R:** tidyverse style guide, generally snake_case

**For interfacing between languages:**
- Use standard data formats (CSV, TSV, HDF5)
- Document data structure and column names
- Convert types at interface boundaries

---

## Getting Help

### When in Doubt

1. **Check this style guide** - Most common patterns are covered
2. **Look at existing code** - Follow established patterns in the project
3. **Ask team members** - Discuss ambiguous cases
4. **Prioritize clarity** - If it's more readable, it's probably better
5. **Document your decision** - Comment why you chose a particular approach

### Updating This Guide

This is a **living document**. As we encounter new patterns or edge cases:

1. Discuss with team
2. Document the decision
3. Update this guide
4. Commit changes with clear description

**To propose changes:**
- Open an issue or discussion
- Provide examples of the problem
- Suggest specific wording
- Get team consensus before updating

---

## Examples

### Complete Function Example

```matlab
function [connectivity_matrix, p_values] = fcn_stats_compute_connectivity(timeseries, varargin)
    % Compute functional connectivity between ROIs
    %
    % Calculates pairwise correlations between ROI timeseries with optional
    % significance testing via permutation. Supports Pearson and Spearman
    % correlation methods.
    %
    % Inputs:
    %   timeseries - [time x ROIs] BOLD timeseries matrix
    %
    % Optional Parameters (name-value pairs):
    %   'method' - Correlation method: "pearson" or "spearman" (default: "pearson")
    %   'num_permutations' - Number of permutations for significance test (default: 0)
    %   'threshold' - Minimum absolute correlation to retain (default: 0)
    %   'save_flag' - Save results: 1=yes, 0=no (default: 0)
    %
    % Outputs:
    %   connectivity_matrix - [ROIs x ROIs] correlation matrix
    %   p_values - [ROIs x ROIs] p-values (empty if num_permutations=0)
    %
    % Example:
    %   timeseries = randn(200, 264);  % 200 timepoints, 264 ROIs
    %   [conn, pvals] = fcn_stats_compute_connectivity(timeseries, ...
    %                       'method', "spearman", ...
    %                       'num_permutations', 1000, ...
    %                       'threshold', 0.3);
    %
    % See also: fcn_stats_permutation_test, corrcoef
    
    % Parse inputs
    p = inputParser;
    addRequired(p, 'timeseries', @isnumeric);
    addParameter(p, 'method', "pearson", @ischar);
    addParameter(p, 'num_permutations', 0, @isnumeric);
    addParameter(p, 'threshold', 0, @isnumeric);
    addParameter(p, 'save_flag', 0, @isnumeric);
    parse(p, timeseries, varargin{:});
    
    % Extract parameters
    method = string(p.Results.method);
    num_permutations = p.Results.num_permutations;
    threshold = p.Results.threshold;
    save_flag = p.Results.save_flag;
    
    % Validate inputs
    assert(ismatrix(timeseries), 'Timeseries must be a 2D matrix');
    assert(size(timeseries, 1) > size(timeseries, 2), ...
        'Timeseries should be [time x ROIs], got [%d x %d]', ...
        size(timeseries, 1), size(timeseries, 2));
    assert(strcmp(method, "pearson") || strcmp(method, "spearman"), ...
        'Method must be "pearson" or "spearman", got "%s"', method);
    assert(threshold >= 0 && threshold <= 1, ...
        'Threshold must be in [0, 1], got %.2f', threshold);
    
    % Compute connectivity matrix
    connectivity_matrix = corr(timeseries, 'Type', char(method));
    
    // Apply threshold
    if threshold > 0
        connectivity_matrix(abs(connectivity_matrix) < threshold) = 0;
    end
    
    % Compute significance if requested
    if num_permutations > 0
        p_values = fcn_stats_permutation_test(timeseries, connectivity_matrix, ...
                                              num_permutations, method);
    else
        p_values = [];
    end
    
    % Optional save
    if save_flag
        save('connectivity_results.mat', 'connectivity_matrix', 'p_values');
        fprintf('Results saved to connectivity_results.mat\n');
    end
end
```

### Complete Experiment Script Example

```matlab
% expt_02_compute_connectivity.m
% Compute functional connectivity for all subjects
%
% This script:
%   1. Loads preprocessed timeseries data
%   2. Computes connectivity matrices
%   3. Performs statistical testing
%   4. Saves results for group analysis

%% Setup
clear; close all; clc;

% Load configuration
config = fcn_utilsConfig_get_config();

% Analysis parameters
CORRELATION_METHOD = "pearson";
NUM_PERMUTATIONS = 1000;
ALPHA = 0.05;

%% Load subject list
fprintf('Loading subject list...\n');
subjects = readtable(fullfile(config.data_dir_raw, "participants.tsv"), ...
                     "FileType", "text", ...
                     "TextType", "string", ...
                     "VariableNamingRule", "preserve");
subject_ids = subjects.subject_id;
num_subjects = numel(subject_ids);

fprintf('Found %d subjects\n\n', num_subjects);

%% Process each subject
connectivity_results = cell(num_subjects, 1);

for subject_idx = 1:num_subjects
    subject_id = subject_ids(subject_idx);
    fprintf('Processing %s (%d/%d)...\n', subject_id, subject_idx, num_subjects);
    
    % Load preprocessed timeseries
    data = fcn_io_load_subject(subject_id, config);
    
    % Compute connectivity
    [conn_matrix, p_values] = fcn_stats_compute_connectivity(data.timeseries, ...
        'method', CORRELATION_METHOD, ...
        'num_permutations', NUM_PERMUTATIONS);
    
    % Store results
    connectivity_results{subject_idx}.subject_id = subject_id;
    connectivity_results{subject_idx}.connectivity_matrix = conn_matrix;
    connectivity_results{subject_idx}.p_values = p_values;
    connectivity_results{subject_idx}.method = CORRELATION_METHOD;
end

fprintf('\nProcessing complete!\n\n');

%% Save results
output_file = fullfile(config.output_dir, "connectivity_all_subjects.mat");
save(output_file, 'connectivity_results', 'subject_ids', ...
     'CORRELATION_METHOD', 'NUM_PERMUTATIONS', 'ALPHA');

fprintf('Results saved to: %s\n', output_file);
```

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-03-26 | Initial draft version |

---

## Acknowledgments

This style guide draws inspiration from:
- PEP 8 (Python)
- Google Style Guides
- MATLAB documentation best practices
- Neuroscience community conventions (BIDS)

---

**Questions or Suggestions?**

This is a living document. Please contribute feedback, examples, and improvements.

```