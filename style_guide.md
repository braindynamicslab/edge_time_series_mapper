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
- **Bash:** Version 4.0 or later (for associative arrays)
- **SLURM:** For HPC job scheduling
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
14. [Bash and SLURM Scripts](#bash-and-slurm-scripts)

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
```

**Functions:** Prefix with module name

```
fcn/<module>/fcn_<module>_<descriptive_name>.m

Examples:
fcn/io/fcn_io_load_subject.m
fcn/stats/fcn_stats_compute_correlation.m
fcn/tabViz/fcn_tabViz_format_for_publication.m
fcn/utils/fcn_utils_get_config.m
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

### Plural for Arrays

**Use plural form for arrays/collections, singular for scalar values or loop variables.**

```matlab
% Correct - Plural for arrays
subjects = [100206, 100307, 100408];
tasks = ["REST", "WM", "MOTOR"];
filepaths = ["file1.mat", "file2.mat"];

for subject_idx = 1:numel(subjects)
    subject = subjects(subject_idx);  % Singular extracted from plural
    process(subject);
end

% Avoid - Inconsistent naming
subject_list = [...];  % Should be 'subjects'
task_array = [...];    % Should be 'tasks'

### Domain-Specific Conventions

**Subject naming:**
- `subject` - The subject ID number (e.g., 100206)
- `subject_idx` - Loop index when iterating over subjects (1, 2, 3...)

We use `subject` instead of `subject_id` because subjects are only identified by 
their ID number. Adding `_id` suffix creates confusion with `subject_idx`.

```matlab
% Correct
for subject_idx = 1:num_subjects
    subject = subjects(subject_idx);
    data = load_data(subject);
end

% Avoid - Redundant and confusing
for subject_idx = 1:num_subjects
    subject_id = subject_id_list(subject_idx);  // subject_id vs subject_idx?
end
```

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

### MAT File Format and Loading

**Always save MAT files with version 7.3 format** to enable partial loading:

```matlab
% Correct - Always use v7.3
save('results.mat', 'data', 'metadata', '-v7.3');

% Avoid - Default format doesn't support partial loading
save('results.mat', 'data', 'metadata');
```
Always use partial loading with matfile() unless you need all variables:

```matlab
% Correct - Partial loading (memory efficient)
m = matfile('results.mat');
metadata = m.metadata;              % Load only metadata
data_subset = m.data(1:100, :);     % Load only subset of data

% Only load fully when necessary
loaded = load('results.mat');       % Loads everything into memory
```

**Rationale**: Version 7.3 uses HDF5 format, allowing MATLAB to read specific variables or array subsets without loading the entire file into memory. This is critical for:
* Large datasets that exceed available RAM
* Quick access to metadata or configuration without loading results
* Processing subsets of data iteratively

**Exception**: Load entire file when you know you need all variables and the file is small enough to fit in memory comfortably.

```matlab
% Exception - Small file, need everything
config = load('config.mat');  % OK if file is small and all data needed
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

### Use Named Constants Instead of Repeated `size()` Calls

**Avoid repeatedly calling `size()` on the same array.** Instead, extract dimensions into descriptive variables at the beginning of a code section. This improves readability, makes intent clear, and can prevent errors if array dimensions change during processing.

**Why This Matters**

```matlab
% Hard to interpret - what do these dimensions represent?
if target_num_features > size(data, 2)
    target_num_features = size(data, 2);
end
for feature_idx = 1:size(data, 2)
    process_feature(data(:, feature_idx));
end
fprintf('Processing %d features\n', size(data, 2));
```

**Problems:**
- Reader must mentally track what dimension 2 means
- Repeated function calls (minor performance cost)
- Easy to accidentally use wrong dimension number
- Intent unclear: are these the same "features" or different quantities?

**Better Approach**

```matlab
% Clear - dimensions have meaningful names
[num_timepoints, num_features] = size(data);

if target_num_features > num_features
    target_num_features = num_features;
end
for feature_idx = 1:num_features
    process_feature(data(:, feature_idx));
end
fprintf('Processing %d features\n', num_features);
```

**Benefits:**
- Self-documenting code
- Single source of truth for each dimension
- Catches errors: using `num_features` instead of `num_timepoints` is obvious
- Easier to refactor if data structure changes

**Recommended Pattern**

At the start of each processing section, extract dimensions:

```matlab
%% Preprocess data
[num_timepoints, num_rois] = size(concatenated_data);
fprintf('Data: %d timepoints x %d ROIs\n', num_timepoints, num_rois);

% ... processing using num_timepoints and num_rois

%% Generate features
[num_timepoints, num_higher_features] = size(data_higher_features);
fprintf('Generated %d higher-order features\n', num_higher_features);

% ... processing using num_higher_features

%% Dimension reduction
if target_num_features > num_higher_features
    actual_num_features = num_higher_features;
else
    actual_num_features = target_num_features;
end
```

**When to Extract Dimensions**

Always extract when:
- Dimension is used more than once
- Code section spans multiple logical operations
- Dimension meaning is not immediately obvious

Can skip when:
- Used exactly once in a very simple operation
- Meaning is completely obvious from context
  ```matlab
  % OK - used once, meaning clear
  num_subjects = numel(subject_list);
  ```

**Example: Before and After**

Before:
```matlab
function process_data(data)
    for i = 1:size(data, 1)
        for j = 1:size(data, 2)
            if data(i, j) > threshold
                result(i, j) = process(data(i, j));
            end
        end
    end
    fprintf('Processed %d x %d matrix\n', size(data, 1), size(data, 2));
end
```

After:
```matlab
function process_data(data)
    [num_observations, num_features] = size(data);
    
    for obs_idx = 1:num_observations
        for feature_idx = 1:num_features
            if data(obs_idx, feature_idx) > threshold
                result(obs_idx, feature_idx) = process(data(obs_idx, feature_idx));
            end
        end
    end
    fprintf('Processed %d observations x %d features\n', num_observations, num_features);
end
```

**The intent is immediately clear, and the code is more maintainable.**

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

### Informative Error and Warning Messages

**Always provide sufficient context in error and warning messages** to help users diagnose and fix problems without needing to inspect code.

**Error messages should include:**
- What went wrong (the problem)
- What was expected vs. what was received
- Relevant variable values (IDs, paths, parameter values)
- Suggestions for how to fix it when appropriate

```matlab
% Good - Specific and actionable
error('File not found: %s\nCheck that preprocessing has been run for subject %d', ...
      filepath, subject_id);

assert(threshold >= 0 && threshold <= 1, ...
    'Threshold must be in [0, 1], got %.2f', threshold);

assert(strcmp(method, "pearson") || strcmp(method, "spearman"), ...
    'Method must be "pearson" or "spearman", got "%s"', method);

% Bad - Too vague
error('File not found');
assert(valid_threshold, 'Invalid threshold');
error('Wrong method');
```

**Warning messages should include:**
- Subject/item identifier being processed
- Specific file paths or parameters involved
- What data is missing or problematic

```matlab
% Good - Complete diagnostic information
warning('File not found: %s', filepath);
warning('Batch not found for subject %d, task %s, session %s', subject_id, task, session);
warning('Subject %d excluded: mean FD = %.3f exceeds threshold %.3f', ...
        subject_id, mean_fd, threshold);

% Bad - Missing context
warning('File not found');
warning('Missing data for subject %d', subject_id);  % Which file? Which task?
warning('Subject excluded');  % Why? Which subject?
```

**For parameter validation, show both expected and received:**

```matlab
% Good - Shows what was expected and what was received
assert(isnumeric(data), 'Data must be numeric, got %s', class(data));
assert(ismatrix(data), 'Data must be 2D matrix, got %d dimensions', ndims(data));
assert(size(data, 1) > size(data, 2), ...
    'Data should be [observations x variables], got [%d x %d]', ...
    size(data, 1), size(data, 2));
```

**Use formatting to make values clear:**

```matlab
% Use appropriate formatting for different data types
error('Subject %d not found', subject_id);           % %d for integers
error('Correlation = %.3f out of range [-1, 1]', r); % %.3f for floats
error('Method "%s" not recognized', method);          % %s for strings
error('File not found: %s', filepath);                % %s for paths
```

**Multi-line messages for complex errors:**

```matlab
error(['Configuration incomplete.\n', ...
       'Required fields: data_dir, output_dir, batch_table_path\n', ...
       'Missing: %s'], strjoin(missing_fields, ', '));
```

**Rationale:** Good error messages save debugging time. When processing hundreds of subjects on HPC, you need to know exactly which subject failed and why, without re-running or reading code. Assume the user seeing the error doesn't have access to variable values or code context.

### Error Handling: Errors vs. Flags

**Use `error()` or `assert()` when:**
- The problem makes continuation impossible or dangerous
- Called function is used interactively or in single-item scripts
- Caller cannot reasonably handle the failure
- Data corruption or invalid results would occur if execution continued

```matlab
% Correct - Configuration errors should halt execution
assert(isfield(config, 'data_dir'), 'Config must have data_dir field');

% Correct - File corruption is unrecoverable
if corrupted_data
    error('Data file is corrupted: %s', filepath);
end
```

**Use error flags when:**
- Processing multiple independent items (subjects, sessions, files, trials)
- Each item can succeed or fail independently
- Failure of one item should not prevent processing others
- Missing data is expected for some items
- You want to collect all results, including which items failed

**Common pattern:** Looping over subjects where some subjects may have missing data.

```matlab
% Correct - Allow loop to continue with other subjects
function [data, missing_flag] = load_subject_data(subject_id)
    missing_flag = 0;
    
    if ~isfile(filepath)
        warning('File not found for subject %d', subject_id);
        missing_flag = 1;
        return;
    end
    
    data = load(filepath);
end

% Usage in loop - process all subjects, skip those with missing data
for subject_idx = 1:num_subjects
    [data, missing] = load_subject_data(subjects(subject_idx));
    
    if missing
        continue;  % Skip to next subject
    end
    
    results{subject_idx} = process(data);
end
```

**Key principle:** If items are independent (one subject's failure doesn't affect another), use flags so the loop can continue. If items are dependent (like sequential pipeline steps), use errors to halt immediately.

**Extension:** When writing a function, you don't know whether it will be called once or many times in a loop. Therefore, prefer error flags and / or warnings by default, and only throw errors for fundamental problems that indicate programming mistakes (wrong data type, missing required configuration, violated function contracts). This makes functions robust in both interactive and batch processing contexts.

```matlab
% Throw error - indicates programming mistake (wrong type)
function results = process_subject(subject_id, config)
    assert(isnumeric(subject_id), 'subject_id must be numeric, got %s', class(subject_id));
    assert(isstruct(config), 'config must be struct, got %s', class(config));
    
    % Return flag - data-dependent issue (some subjects may have missing data)
    error_flag = 0;
    if ~isfile(data_path)
        warning('Data not found for subject %d', subject_id);
        error_flag = 1;
        return;
    end
    
    results = process(data);
end
```

**Flag naming convention:**
- Use `<condition>_flag` pattern: `missing_data_flag`, `error_flag`, `success_flag`
- Return as output argument, not as global variable
- Document clearly in function header
- Always initialize to default value (typically 0 for "no error")

**Combine with warnings:**
- Set flag AND issue warning to inform user
- Warning provides context, flag enables graceful continuation

```matlab
if problem_detected
    warning('Problem with subject %d: %s', subject_id, description);
    error_flag = 1;
    return;
end
```

**When to use both:**
- Validate critical parameters with `assert()` at function start (these failures indicate programming errors)
- Use flags for data-dependent failures during processing (these are expected in real data)

```matlab
function [results, error_flag] = process_subject(subject_id, config)
    % Validate inputs - these should never fail in correct usage
    assert(isnumeric(subject_id), 'subject_id must be numeric');
    assert(isstruct(config), 'config must be a struct');
    
    error_flag = 0;
    
    % Data loading might fail for some subjects - use flag
    if ~data_exists(subject_id)
        warning('No data for subject %d', subject_id);
        error_flag = 1;
        return;
    end
    
    results = process(data);
end
```

**Note:** This pattern applies across programming languages, not just MATLAB. The specific syntax (`error()`, `assert()`, return values) varies, but the principle of "flags for independent items, errors for critical failures" is universal.
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

### Separating Path Components

**Always separate path components - avoid hardcoded slashes or backslashes**

```matlab
% Correct - Each component separated
filepath = fullfile(config.repo_root, "data_pipeline", "results", "internal", filename);
filepath = fullfile(base_dir, batch_dir, scan_id, "fcon", parcellation, filename);

% Avoid - Hardcoded separators (even though it works)
filepath = fullfile(config.repo_root, "data_pipeline/results/internal", filename);
filepath = fullfile(base_dir, "fcon/schaefer100x7", filename);
```

Rationale: While MATLAB's fullfile() normalizes all separators and both styles work identically across platforms, always separating components:

Makes the structure explicit and uniform
Avoids confusion about which separator to use (/ vs \)

Exception: When passing a complete path from external source (e.g., command output, config file), keep as-is and let fullfile() normalize it.

```matlab
% OK - External path passed through
external_path = get_path_from_config();  % Might contain / or \
filepath = fullfile(base_dir, external_path);
```

### Relative vs Absolute Paths in MATLAB

**Use relative paths for portability:**

```matlab
% Good - Relative to repository root
repo_root = fcn_utils_detect_repo_root();
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



### Bash Path Management

**All directory variables must have trailing slashes:**

```bash
# Correct
REPO_ROOT="/home/users/username/project/"
DATA_DIR="/oak/stanford/groups/group/data/"

# Use without additional slash
FILEPATH="${DATA_DIR}subject_01.mat"

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

**Rationale:**
- Consistent visual pattern - directories always end with `/`
- Never add `/` when concatenating - it's already there
- Avoids both missing and double slashes
- Clear distinction between directories and files

**Rules:**
1. **Directory variables:** Always end with `/`
2. **File variables:** Never end with `/`  
3. **Concatenating filenames:** Never add `/` (already in directory variable)
4. **Creating subdirectories:** Add trailing `/`

```bash
# Setting up paths
BASE_DIR="/oak/stanford/groups/project/"
DATA_DIR="${BASE_DIR}data/"
SUBJECT_DIR="$${DATA_DIR}sub-$${SUBJECT}/"
OUTPUT_FILE="${SUBJECT_DIR}results.csv"

# Creating directories  
mkdir -p "${DATA_DIR}"
mkdir -p "${SUBJECT_DIR}"

# Creating files
touch "${OUTPUT_FILE}"
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

### Submitting SLURM Jobs with Dependencies

```bash
# Submit jobs in sequence
PREV_JOB=""
for SIMPLEX in node edge; do
    if [ -z "${PREV_JOB}" ]; then
        PREV_JOB=$$(sbatch --parsable script.sbatch "$${COHORT}" "${SIMPLEX}")
    else
        PREV_JOB=$$(sbatch --dependency=afterok:$${PREV_JOB} --parsable script.sbatch "$${COHORT}" "$${SIMPLEX}")
    fi
done

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
config = fcn_utils_get_config();

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

## Bash and SLURM Style Guide

### Philosophy

**Keep bash and SLURM scripts light.** Outsource heavy computation and complex logic to higher-level languages (MATLAB, Python, R) for easier debugging, testing, and maintenance. Bash should orchestrate workflows, not implement algorithms.

```bash
# Good - Bash orchestrates, MATLAB computes
matlab -nodisplay -batch "fcn_analysis_complex_computation(data, params);"

# Avoid - Complex computation in bash
# Don't implement statistical tests, signal processing, etc. in bash
```

**Why:**
- Higher-level languages have better debugging tools
- Easier to test and validate complex logic
- More readable and maintainable
- Better error messages and stack traces

---

### Comments and Print Statements

**Comments and print statements are highly encouraged** to avoid bugs and misunderstandings. Bash scripts can be opaque - make execution transparent.

```bash
# Print what you're doing at each step
echo "Loading configuration..."
source config.sh

echo "Processing ${num_subjects} subjects"
echo "Output directory: ${OUTPUT_DIR}"
echo "Method: ${METHOD}"

# Comment non-obvious decisions
# Use Spearman correlation because data may have outliers
METHOD="spearman"

# Explain file operations
echo "Creating output directories..."
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${TMP_DIR}"
```

**Print important variable values:**

```bash
# At start of script
echo "========================================="
echo "Script: $(basename \$0)"
echo "Started: $(date)"
echo "User: ${USER}"
echo "========================================="
echo ""

echo "Configuration:"
echo "  COHORT: ${COHORT}"
echo "  SESSION: ${SESSION}"
echo "  SIMPLEX: ${SIMPLEX}"
echo "  OUTPUT_DIR: ${OUTPUT_DIR}"
echo ""
```

---

### Building Commands with Variables

**When building commands with variables, save the command as a string and print it before execution.** This aids debugging and reduces confusion about quotes.

#### The Problem

```bash
# Hard to debug - what does MATLAB actually receive?
matlab -batch "fcn_process($${SUBJECT}, '$${SESSION}', ${SIMPLEX})"
```

If this fails, you can't see what was actually passed to MATLAB. Was `${SUBJECT}` expanded correctly? Are the quotes right?

#### The Solution

```bash
# Build command as a string
MATLAB_COMMAND="addpath(genpath('${REPO_ROOT}')); \
fcn_edgeMapper_compute_and_analyze_simplex_mapper(\
$${SUBJECT}, '$${PARCELLATION}', '$${SESSION}', $${SIMPLEX}, '${OUTPUT_DIR}', \
'copy_data_flag', ${COPY_DATA_FLAG}, \
'summary_csv_path', '${TMP_FILENAME}');"

# Print for debugging
echo "MATLAB command:"
echo "${MATLAB_COMMAND}"
echo ""

# Execute
matlab -nodisplay -batch "${MATLAB_COMMAND}"
```

**Benefits:**
- Can see exactly what MATLAB receives
- Easy to copy-paste for interactive testing
- Helps catch quoting errors before execution
- Clear separation between construction and execution

#### Understanding Quotes in Bash-MATLAB Interface

**Three layers of quoting:**
1. Bash shell quoting
2. The `-batch` argument string  
3. MATLAB string syntax

**Rules:**

```bash
# String variables in bash → Strings in MATLAB
# Need quotes around bash variable so MATLAB sees it as a string
PARCELLATION="schaefer100x7"
"'${PARCELLATION}'"  # Bash expands to → 'schaefer100x7' in MATLAB

# Numeric variables in bash → Numbers in MATLAB  
# No quotes around bash variable so MATLAB sees it as a number
SIMPLEX=2
"${SIMPLEX}"  # Bash expands to → 2 in MATLAB

# Literal strings (parameter names) → Strings in MATLAB
# Single quotes for MATLAB
"'copy_data_flag'"  # → 'copy_data_flag' in MATLAB
```

**Complete example with comments:**

```bash
# Variables
SUBJECT=101              # Numeric subject ID
PARCELLATION="schaefer100x7"  # String parcellation name
SIMPLEX=2               # Numeric simplex level
COPY_DATA_FLAG=1        # Numeric flag

# Build MATLAB command
# Use double quotes for the entire bash string
# Use single quotes around bash variables that should be MATLAB strings
# Use ${VAR} without quotes for bash variables that should be MATLAB numbers
MATLAB_COMMAND="addpath(genpath('${REPO_ROOT}')); \
fcn_process(\
${SUBJECT}, \
'${PARCELLATION}', \
${SIMPLEX}, \
'copy_data_flag', ${COPY_DATA_FLAG});"

# What MATLAB receives (after bash expansion):
# addpath(genpath('/path/to/repo')); 
# fcn_process(101, 'schaefer100x7', 2, 'copy_data_flag', 1);
#              ^^^  ^^^^^^^^^^^^^^  ^                      ^
#              number  string    number                  number
```

**Why this matters:**

```bash
# Wrong - MATLAB sees variable name instead of string
COHORT="one"
"fcn(${COHORT})"  
# Bash expands to → fcn(one)
# MATLAB error: Undefined variable 'one'

# Correct - MATLAB sees string literal  
"fcn('${COHORT}')"
# Bash expands to → fcn('one')
# MATLAB receives string: 'one'
```

**Additional notes:**

```bash
# Backslash \ continues the string to next line
COMMAND="first_part \
second_part"

# Note: Do not separate the addpath line from the function call!
# This would create TWO MATLAB sessions:
matlab -batch "addpath(...)"        # Session 1: adds path, exits
matlab -batch "fcn_process(...)"    # Session 2: path not available!

# Correct - one session:
MATLAB_COMMAND="addpath(...); fcn_process(...);"
matlab -batch "${MATLAB_COMMAND}"
```

---

### Reproducibility: Scripts Over Interactive Commands

**Always write a script and execute it, rather than running commands interactively.** This ensures reproducibility and creates an audit trail.

```bash
# Good - Script is version controlled and reproducible
bash scripts/submit_all_jobs.sh one LR edge schaefer100x7

# Avoid - Interactive commands are lost
cd /some/path
for i in 1 2 3; do
    sbatch script.sh $i  # Where did this run? What were the exact parameters?
done
```

**Why:**
- Scripts are version controlled
- Can be re-run with same parameters
- Documents what was done
- Can be reviewed and debugged
- Creates audit trail in logs

---

### Logging: Automatic Documentation

**Every bash script should log execution details automatically.** This is especially critical when launching SLURM jobs.

#### Standard Logging Pattern

```bash
#!/bin/bash
#
# Description of what this script does
#

# ============================================
# Configuration
# ============================================
SCRIPT_NAME=$(basename "\$0")
LOG_DIR="note_and_report"
LOG_FILE="${LOG_DIR}/log.txt"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# ============================================
# Start logging
# ============================================
{
    echo "============================================"
    echo "SCRIPT START"
    echo "============================================"
    echo "Script:    ${SCRIPT_NAME}"
    echo "User:      ${USER}"
    echo "Date:      $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hostname:  $(hostname)"
    echo "Directory: $(pwd)"
    echo ""
    echo "Parameters:"
    echo "  COHORT:       ${COHORT}"
    echo "  SESSION:      ${SESSION}"
    echo "  SIMPLEX:      ${SIMPLEX}"
    echo ""
} >> "${LOG_FILE}"

# ============================================
# Main script execution
# ============================================

# Example: Submit jobs and log IDs
echo "Submitting jobs..." | tee -a "${LOG_FILE}"

for SIMPLEX in node edge; do
    JOB_ID=$$(sbatch --parsable script.sbatch "$${COHORT}" "$${SESSION}" "$${SIMPLEX}")
    
    {
        echo "Submitted job:"
        echo "  Job ID:   ${JOB_ID}"
        echo "  Simplex:  ${SIMPLEX}"
        echo "  Command:  sbatch script.sbatch $${COHORT} $${SESSION} ${SIMPLEX}"
        echo ""
    } >> "${LOG_FILE}"
done

# ============================================
# End logging
# ============================================
{
    echo "Script completed successfully"
    echo "End time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "============================================"
    echo ""
    echo ""
} >> "${LOG_FILE}"
```

#### Why Log Job IDs?

SLURM job IDs are critical for:
- Checking job status: `squeue -j ${JOB_ID}`
- Viewing job details: `sacct -j ${JOB_ID}`  
- Canceling jobs: `scancel ${JOB_ID}`
- Debugging failures
- Tracking which analysis produced which results

**Without logging, you lose track of which jobs you launched and with what parameters.**

#### Adding User Comments to Log

Encourage users to document why they're running the analysis:

```bash
# Allow user to add comments before script runs
echo ""
echo "Optional: Add comment about this run (press Enter to skip):"
read -r USER_COMMENT

if [ -n "${USER_COMMENT}" ]; then
    {
        echo "User comment:"
        echo "  ${USER_COMMENT}"
        echo ""
    } >> "${LOG_FILE}"
fi
```

**Example comments:**
- "Testing new preprocessing parameters"
- "Rerunning failed subjects from batch 2"
- "Exploratory analysis for reviewer response"
- "Final analysis for paper submission"

#### Log Format

Use clear separators between log entries for easy navigation:

```
============================================
SCRIPT START
============================================
Script:    submit_jobs.sh
User:      username
Date:      2024-03-26 14:30:00
Hostname:  sh-ln01.stanford.edu
Directory: /home/users/username/project

Parameters:
  COHORT:       one
  SESSION:      LR
  SIMPLEX:      edge

User comment:
  Testing edge mapper with new parameters

Submitting jobs...

Submitted job:
  Job ID:   20016104
  Simplex:  node
  Command:  sbatch script.sbatch one LR node

Submitted job:
  Job ID:   20016105
  Simplex:  edge
  Command:  sbatch script.sbatch one LR edge

Script completed successfully
End time: 2024-03-26 14:30:15
============================================


============================================
SCRIPT START
============================================
Script:    submit_jobs.sh
User:      username
Date:      2024-03-27 09:15:23
...next entry...
```

**Benefits:**
- Easy to grep for specific dates or job IDs
- Clear visual separation between runs
- Complete context for each execution
- Searchable history of all analyses

#### Redirecting Output to Log

**Option 1: Append selected output (recommended)**

```bash
# Explicit logging of specific messages
echo "Processing subject $${SUBJECT}..." >> "$${LOG_FILE}"
```

**Option 2: Tee for simultaneous console and log**

```bash
# Show on console AND append to log
echo "Processing subject $${SUBJECT}..." | tee -a "$${LOG_FILE}"
```

**Option 3: Redirect all script output (use carefully)**

```bash
#!/bin/bash

# Redirect stdout and stderr to log file AND console
exec > >(tee -a "${LOG_FILE}")
exec 2>&1

# Now everything is logged automatically
echo "This goes to console and log"
ls /nonexistent  # Errors also logged
```

**Recommendation:** Use explicit logging (Option 1) or tee (Option 2) for important messages. Avoid redirecting everything (Option 3) as it can create massive log files with unnecessary detail.

#### Complete Template Script with Logging

```bash
#!/bin/bash
#
# submit_analysis_jobs.sh
#
# Submit SLURM jobs for connectivity analysis across cohorts and sessions
#

set -e  # Exit on error
set -u  # Exit on undefined variable

# ============================================
# Configuration
# ============================================
SCRIPT_NAME=$(basename "\$0")
REPO_ROOT="/home/users/username/project/"
LOG_DIR="${REPO_ROOT}note_and_report/"
LOG_FILE="${LOG_DIR}log.txt"

COHORTS=("one" "all_but_one")
SESSIONS=("LR" "RL")
SIMPLEXES=("node" "edge")

SLURM_SCRIPT="${REPO_ROOT}slurm_script/analysis.sbatch"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# ============================================
# User input
# ============================================
echo "============================================"
echo "JOB SUBMISSION SCRIPT"
echo "============================================"
echo ""
echo "Will submit $$(( $${#COHORTS[@]} * $${#SESSIONS[@]} * $${#SIMPLEXES[@]} )) jobs"
echo ""
echo "Optional: Add comment about this run (press Enter to skip):"
read -r USER_COMMENT
echo ""

# ============================================
# Start logging
# ============================================
{
    echo "============================================"
    echo "SCRIPT START"
    echo "============================================"
    echo "Script:    ${SCRIPT_NAME}"
    echo "User:      ${USER}"
    echo "Date:      $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hostname:  $(hostname)"
    echo "Directory: $(pwd)"
    echo ""
    
    if [ -n "${USER_COMMENT}" ]; then
        echo "User comment:"
        echo "  ${USER_COMMENT}"
        echo ""
    fi
    
    echo "Configuration:"
    echo "  Cohorts:   ${COHORTS[*]}"
    echo "  Sessions:  ${SESSIONS[*]}"
    echo "  Simplexes: ${SIMPLEXES[*]}"
    echo "  SLURM script: ${SLURM_SCRIPT}"
    echo ""
} >> "${LOG_FILE}"

# ============================================
# Submit jobs
# ============================================
echo "Submitting jobs..." | tee -a "${LOG_FILE}"
echo "" >> "${LOG_FILE}"

JOB_COUNT=0

for COHORT in "${COHORTS[@]}"; do
    for SESSION in "${SESSIONS[@]}"; do
        PREV_JOB=""
        
        for SIMPLEX in "${SIMPLEXES[@]}"; do
            # Build experiment name
            EXPT_NAME="analysis_$${COHORT}_$${SESSION}_${SIMPLEX}"
            
            # Submit with dependency
            if [ -z "${PREV_JOB}" ]; then
                JOB_ID=$$(sbatch --parsable "$${SLURM_SCRIPT}" \
                    "$${COHORT}" "$${SESSION}" "$${SIMPLEX}" "$${EXPT_NAME}")
                
                echo "  Job $${JOB_ID}: cohort=$${COHORT}, session=$${SESSION}, simplex=$${SIMPLEX}"
                
                {
                    echo "Submitted job ${JOB_ID}:"
                    echo "  Cohort:       ${COHORT}"
                    echo "  Session:      ${SESSION}"
                    echo "  Simplex:      ${SIMPLEX}"
                    echo "  Experiment:   ${EXPT_NAME}"
                    echo "  Dependency:   none (first in chain)"
                    echo ""
                } >> "${LOG_FILE}"
            else
                JOB_ID=$$(sbatch --dependency=afterok:$${PREV_JOB} --parsable "${SLURM_SCRIPT}" \
                    "$${COHORT}" "$${SESSION}" "$${SIMPLEX}" "$${EXPT_NAME}")
                
                echo "  Job $${JOB_ID}: cohort=$${COHORT}, session=$${SESSION}, simplex=$${SIMPLEX} (depends on ${PREV_JOB})"
                
                {
                    echo "Submitted job ${JOB_ID}:"
                    echo "  Cohort:       ${COHORT}"
                    echo "  Session:      ${SESSION}"
                    echo "  Simplex:      ${SIMPLEX}"
                    echo "  Experiment:   ${EXPT_NAME}"
                    echo "  Dependency:   afterok:${PREV_JOB}"
                    echo ""
                } >> "${LOG_FILE}"
            fi
            
            PREV_JOB="${JOB_ID}"
            JOB_COUNT=$((JOB_COUNT + 1))
        done
        
        echo "" >> "${LOG_FILE}"
    done
done

# ============================================
# Summary
# ============================================
echo ""
echo "Submission complete!" | tee -a "${LOG_FILE}"

{
    echo "Summary:"
    echo "  Total jobs submitted: ${JOB_COUNT}"
    echo "  Check status: squeue -u ${USER}"
    echo "  View details: sacct -j <JOB_ID>"
    echo ""
} | tee -a "${LOG_FILE}"

# ============================================
# End logging
# ============================================
{
    echo "Script completed successfully"
    echo "End time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "============================================"
    echo ""
    echo ""
} >> "${LOG_FILE}"

echo ""
echo "Log saved to: ${LOG_FILE}"
```

#### Using the Log File

**View recent entries:**
```bash
tail -100 note_and_report/log.txt
```

**Search for specific job ID:**
```bash
grep "20016104" note_and_report/log.txt
```

**Find all runs from a specific date:**
```bash
grep "2024-03-26" note_and_report/log.txt
```

**Extract all job IDs from a run:**
```bash
# Get the block for a specific run, then extract job IDs
sed -n '/SCRIPT START.*2024-03-26 14:30/,/SCRIPT.*completed/p' note_and_report/log.txt | \
    grep "Job ID:"
```

**Cancel all jobs from a logged run:**
```bash
# Extract job IDs and cancel them
grep "Job ID:" note_and_report/log.txt | tail -10 | awk '{print \$3}' | xargs scancel
```

#### Best Practices

1. **Always log before modifying:**
   - Log before deleting files
   - Log before overwriting results
   - Log before launching large job arrays

2. **Include context:**
   - Why you're running this analysis
   - What parameters changed from last time
   - Expected completion time

3. **Review logs periodically:**
   - Archive old entries (e.g., yearly)
   - Check for patterns in failures
   - Document successful parameter combinations

4. **Version control:**
   - Commit `log.txt` periodically (or use `.gitignore` if it gets too large)
   - Keep separate logs for different projects
   - Include timestamps in archived logs: `log_2024.txt`

#### Example Log Review Session

```bash
# What jobs did I submit today?
grep "$(date '+%Y-%m-%d')" note_and_report/log.txt

# Which jobs are still pending?
JOBS=$(grep "Job ID:" note_and_report/log.txt | tail -20 | awk '{print \$3}')
for JOB in $JOBS; do
    squeue -j $$JOB 2>/dev/null || echo "Job $$JOB completed or not found"
done

# Review my comment from last run
grep -A 2 "User comment:" note_and_report/log.txt | tail -3
```

---

### Script vs Interactive Commands

**Always prefer scripts over interactive commands for reproducibility.**

#### Why Scripts?

| Interactive | Script |
|------------|--------|
| No record of what you did | Complete history |
| Can't reproduce exactly | Reproducible |
| Typos cause errors | Typos caught in testing |
| Parameter values forgotten | Parameters documented |
| Can't review before execution | Can review and version control |

#### Example: Interactive (Avoid)

```bash
# At command line - no record, no logging
$ cd /scratch/users/siuc/project
$ sbatch analysis.sbatch one LR node
Submitted batch job 12345
$ sbatch analysis.sbatch one LR edge
Submitted batch job 12346
# ... 30 minutes later: which parameters did I use? What were the job IDs?
```

#### Example: Script (Preferred)

```bash
# submit_jobs.sh - versioned, logged, reproducible
$ bash submit_jobs.sh

============================================
JOB SUBMISSION SCRIPT
============================================

Will submit 4 jobs

Optional: Add comment about this run (press Enter to skip):
Testing new filtering parameters

Submitting jobs...
  Job 20016104: cohort=one, session=LR, simplex=node
  Job 20016105: cohort=one, session=LR, simplex=edge
  ...

Submission complete!
Log saved to: note_and_report/log.txt
```

**Benefits:**
- Every execution is logged
- Parameters are documented
- Can review script before running
- Easy to modify and rerun
- Version controlled
- Shareable with collaborators

#### When Interactive is Acceptable

**Quick checks and exploration:**
```bash
# OK - Simple query
squeue -u $USER

# OK - Checking a file
head data/participants.tsv

# OK - Testing a command before scripting
matlab -nodisplay -batch "disp('test')"
```

**But for any real work:**
- Launching jobs → Write a script
- Processing data → Write a script
- Moving/deleting files → Write a script
- Anything you might need to repeat → Write a script

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