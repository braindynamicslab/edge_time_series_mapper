#!/bin/bash
#SBATCH --job-name=expt_compute_analyze_simplex_mapper_node_or_edge
#
# RESOURCE ALLOCATION
# The resource allocation below works for node or edge time series, but probably is insufficient for triangle time series
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=4G

# PARALLELIZATION
# This depends on the cohort.
# Cohorts one, two, and all_but_one_two all have cohort sizes smaller than 400,
# but joint cohorts may be bigger
# The percentage sign ensures that there are at most 20 concurrent processes,
# so that other lab members may access computation resources as well.
#SBATCH --array=1-400%20
#SBATCH --ntasks=1

# PARTITION
# These are all the partitions we can use. You may use fewer.
#SBATCH --partition=saggar,owners,normal

# OUTPUT
# The first two lines save the output and error files in the specified directories.
# Adapt to your own directory.
# The third line ensures that you can an email whenever your job starts or finish (or has hiccups).
#SBATCH --output=/scratch/users/siuc/edge_time_series_mapper/slurm_out/%x_%A_%3a.out
#SBATCH --error=/scratch/users/siuc/edge_time_series_mapper/slurm_err/%x_%A_%3a.err
#SBATCH --mail-type=ALL

# Parse input
COHORT=$1
SESSION=$2
SIMPLEX=$3
PARCELLATION=$4
EXPT_NAME=$5
CLEAN_GARBAGE_FLAG=${6:-1}
VARARGIN_STR=${7:-""}  # Optional 7th argument for MATLAB varargin

# Configuration
# Customize this section! Also, customize the output and error lines above!
REPO_ROOT="/home/users/siuc/edge_time_series_mapper/"
REPO_MASS_OUTPUT_DIRECTORY="/scratch/users/siuc/edge_time_series_mapper/"
TMP_DIRECTORY="/scratch/users/siuc/edge_time_series_mapper/tmp/"
SUMMARY_DIRECTORY="${REPO_ROOT}data_pipeline/${EXPT_NAME}/"
LOCKFILE="${SUMMARY_DIRECTORY}summary.lock"


# Load subject from cohort list
SUBJECT_IDX=$SLURM_ARRAY_TASK_ID
LINE_NUM=$((SUBJECT_IDX+1)) # The first line is the header line "Subject".
SUBJECT=$(awk "NR==$LINE_NUM" /home/users/siuc/edge_time_series_mapper/data_pipeline/data_cohort/cohort_${COHORT}_session_${SESSION}.csv) # get the corresponding line, which is a list of input arguments of my Matlab function, separated by commas
echo $SUBJECT

# Fix experimental parameters
OUTPUT_DIRECTORY="${REPO_MASS_OUTPUT_DIRECTORY}${EXPT_NAME}/"
COPY_DATA_FLAG=1
TMP_FILENAME="${TMP_DIRECTORY}tmp_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}_${SUBJECT}_${PARCELLATION}_${SESSION}_${SIMPLEX}.csv"


SUMMARY_FILENAME="${SUMMARY_DIRECTORY}summary_raw.csv"


# Create directories if they don't already exist
if [ ! -d "${OUTPUT_DIRECTORY}" ]; then
    mkdir -p "${OUTPUT_DIRECTORY}"
fi
if [ ! -d "${TMP_DIRECTORY}" ]; then
    mkdir -p "${TMP_DIRECTORY}"
fi
if [ ! -d "${SUMMARY_DIRECTORY}" ]; then
    mkdir -p "${SUMMARY_DIRECTORY}"
fi

# Actual computation starts here
CURRENT_DIRECTORY=$(pwd)
cd $REPO_ROOT

ml load matlab

# Build MATLAB command with optional varargin
# Process varargin, prefix with ", " if not already so
if [[ -n "$${VARARGIN_STR}" && "$${VARARGIN_STR}" != ,* ]]; then
        VARARGIN_STR=", ${VARARGIN_STR}";
    fi
fi

# Base command with required arguments
MATLAB_COMMAND="addpath(genpath('${REPO_ROOT}')); \
fcn_edgeMapper_compute_and_analyze_simplex_mapper(\
${SUBJECT}, '${PARCELLATION}', '${SESSION}', '${SIMPLEX}', '${OUTPUT_DIRECTORY}', \
'copy_data_flag', ${COPY_DATA_FLAG}, \
'summary_csv_path', '${TMP_FILENAME}'${VARARGIN_STR});"

# Notes on parameter passing:
# \ means the string continues in the next line
# Numeric parameters can be embedded directly.
# String parameter needs to be in quotes,
# e.g. if COHORT="one", "fcn(${COHORT})" evaluates to "fcn(one)" (wrong, unless one is a MATLAB variable);
# we need "fcn('${COHORT}')", which evaluates to "fcn('one')" (correct).
#
# VARARGIN_STR is already formatted with proper quotes from the submission script:
# - String arguments like 'dim_reduction_type' have single quotes
# - Numeric arguments like 0.95 or 20 have no quotes
# Example: VARARGIN_STR="'dim_reduction_type', 'pca_variance_threshold', 'target_explained_variance', 0.95"

# Note: Do not separate the addpath-genpath line into two MATLAB calls.
# This would open two MATLAB sessions, one just add the path and does nothing,
# and the other tries the call the function without adding the path.

# Note: Be careful when modifying the lines above to do multiple MATLAB function calls
# when temperary files are created and garbage collection is done. 
# You will need to modify the lines below to compile the temporary results for all calls.

echo $MATLAB_COMMAND
matlab -nodisplay -batch "$MATLAB_COMMAND"

# Collect numerical output to a table

# Check if MATLAB succeeded and created temp file
if [ $? -eq 0 ] && [ -f "${TMP_FILENAME}" ]; then
    # Use flock to safely append to summary file
    (
        flock -x 200  # Exclusive lock on file descriptor 200
        
        # Create header if file doesn't exist
        if [ ! -f "${SUMMARY_FILENAME}" ]; then
            head -n 1 "${TMP_FILENAME}" > "${SUMMARY_FILENAME}"
        fi
        
        # Append data (skip header)
        tail -n +2 "${TMP_FILENAME}" >> "${SUMMARY_FILENAME}"
        
    ) 200>"${LOCKFILE}"  # Lock file for synchronization
    
    # Clean up temp file
    if [ ${CLEAN_GARBAGE_FLAG} -eq 1 ]; then
        echo "Clearing tmp..."
        rm -f "${TMP_FILENAME}"
    else
        echo "Not clearing tmp"
    fi
    
    echo "Successfully appended results for task ${SLURM_ARRAY_TASK_ID}"
    echo "  subject: ${SUBJECT}, parcellation: ${PARCELLATION}, session: ${SESSION}, simplex: ${SIMPLEX}"
else
    echo "ERROR: MATLAB failed or did not produce output for task ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

cd $CURRENT_DIRECTORY