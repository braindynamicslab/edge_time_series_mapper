#!/bin/bash
#
# bash_submit_simplex_mapper_jobs.sh
#
# Resubmit SLURM job based on whether the previously run job has timeout error.

set -e  # Exit on error
set -u  # Exit on undefined variable

# ============================================
# Configuration
# ============================================
SCRIPT_NAME=$(basename "$0")
REPO_ROOT="/home/users/siuc/edge_time_series_mapper/"
LOG_DIR="${REPO_ROOT}note_and_report/"
LOG_FILE="${LOG_DIR}log.txt"
COHORT_DIR="${REPO_ROOT}data_pipeline/data_cohort/"
SLURM_ERR_DIR="/scratch/users/siuc/edge_time_series_mapper/slurm_err"

SCRIPT="fcn/edgeMapper/slurm_edgeMapper_compute_and_analyze_simplex_mapper.sbatch"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# ============================================
# User input (BEFORE redirecting output)
# ============================================
echo "============================================"
echo "SIMPLEX MAPPER JOB SUBMISSION (TIME-BASED)"
echo "============================================"
echo ""
echo "Optional: Add comment about this run (press Enter to skip):"
read -r USER_COMMENT
echo ""

# ============================================
# Redirect all output to both console and log
# ============================================
exec > >(tee -a "${LOG_FILE}")
exec 2>&1

# ============================================
# Start logging
# ============================================
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
    echo "User comment: ${USER_COMMENT}"
    echo ""
fi

echo "Configuration:"
echo "  SLURM script:         ${SCRIPT}"
echo "  Cohort directory:     ${COHORT_DIR}"
echo "  SLURM error dir:      ${SLURM_ERR_DIR}"
echo ""

# ============================================
# DEFINE ALL JOBS MANUALLY
# ============================================
# Format: "COHORT|SESSION|SIMPLEX|PARCELLATION|VARARGIN1|VARARGIN2|...|ESTIMATED_MINUTES|FILENAME_PATTERN"
# - COHORT: cohort name (e.g., "one", "all_but_one")
# - SESSION: session name (e.g., "LR", "RL")
# - SIMPLEX: simplex type (e.g., "node", "edge")
# - PARCELLATION: parcellation name (e.g., "schaefer100x7", "schaefer200x7")
# - VARARGIN1-N: optional arguments to pass to MATLAB (use "(none)" if not needed)
# - ESTIMATED_MINUTES: how long this job will take to complete (SECOND TO LAST)
# - FILENAME_PATTERN: filename pattern to find failed tasks (MUST BE LAST)
#                     Use "(none)" to run full array, or provide pattern like:
#                     "expt_compute_analyze_simplex_mapper_node_or_edge_20481771"
#
# Jobs run sequentially in the order listed below.
# Each job starts when the previous job is estimated to finish.
# To skip a job, comment it out with #
#
# VARARGIN Syntax Rules:
# - String arguments MUST have single quotes: 'dim_reduction_type'
# - Numeric arguments have NO quotes: 0.95, 20, 1
# - Use (none) as placeholder when no varargin needed
#
# VARARGIN Examples:
#   No varargin, full array:
#     "one|LR|node|schaefer200x7|(none)|(none)|(none)|(none)|120|(none)"
#   
#   Four varargin arguments, re-run failed tasks from job 20481771:
#     "one|LR|node|schaefer100x7|'dim_reduction_type'|'pca_variance_threshold'|'target_explained_variance'|0.95|120|expt_compute_analyze_simplex_mapper_node_or_edge_20481771"
#   
#   Two varargin arguments, full array:
#     "one|LR|edge|schaefer100x7|'activity_mask_flag'|1|(none)|(none)|300|(none)"

JOBS=(
    "one|LR|triangle|schaefer100x7|'dim_reduction_type'|'pca_fixed_components'|'target_num_features'|30|100|expt_compute_analyze_simplex_mapper_node_or_edge_20481771"
)

# ============================================
# Helper function to build varargin string and suffix
# ============================================
process_varargin() {
    # Receives array elements as individual arguments via "$@"
    local varargin_str=""
    local suffix=""
    
    # Iterate through all arguments passed to function
    for val in "$@"; do
        # Stop at first "(none)"
        if [ "${val}" = "(none)" ]; then
            break
        fi
        
        # Build comma-separated varargin string (with leading ", ")
        varargin_str="${varargin_str}, ${val}"
        
        # Build filesystem-safe suffix (clean version without quotes)
        local clean_val=$(echo "${val}" | tr -d "'" | tr ' .-' '_')
        suffix="${suffix}_${clean_val}"
    done
    
    # Return both values separated by |||
    echo "${varargin_str}|||${suffix}"
}

# ============================================
# Helper function to find failed array tasks
# ============================================
find_failed_tasks() {
    local pattern="$1"
    
    # Find files matching pattern that contain the timeout error
    local failed_files=$(find "${SLURM_ERR_DIR}" -maxdepth 1 -name "*${pattern}*" -type f ! -empty \
        -exec grep -l "CANCELLED AT .* DUE TO TIME LIMIT" {} \;)
    
    # Extract just the 3-digit numbers from the filenames
    local failed_tasks=""
    for file in ${failed_files}; do
        # Extract 3-digit number: pattern_XXX.err
        task_id=$(echo "$file" | sed -n "s/.*${pattern}_\([0-9]\{3\}\)\.err/\1/p")
        if [ -n "$task_id" ]; then
            failed_tasks="${failed_tasks}${task_id}"$'\n'
        fi
    done
    
    # Remove trailing newline and return
    echo "${failed_tasks}" | sed '/^$/d'
}

# ============================================
# ACTUAL CODE STARTS HERE
# ============================================

echo "Submitting ${#JOBS[@]} jobs sequentially..."
echo ""

JOB_COUNT=0
CUMULATIVE_DELAY=0  # Track total delay from NOW for sequential scheduling

for JOB_SPEC in "${JOBS[@]}"; do
    # Parse job specification into array
    IFS='|' read -ra JOB_PARTS <<< "${JOB_SPEC}"
    
    # Extract fixed fields
    COHORT="${JOB_PARTS[0]}"
    SESSION="${JOB_PARTS[1]}"
    SIMPLEX="${JOB_PARTS[2]}"
    PARCELLATION="${JOB_PARTS[3]}"
    
    # Last element is filename pattern
    FILENAME_PATTERN="${JOB_PARTS[-1]}"
    
    # Second to last element is estimated minutes
    ESTIMATED_MINUTES="${JOB_PARTS[-2]}"
    
    # Validate estimated minutes
    if ! [[ "${ESTIMATED_MINUTES}" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Invalid estimated minutes '${ESTIMATED_MINUTES}' for job: ${JOB_SPEC}"
        exit 1
    fi
    
    # Everything between position 4 and second-to-last element is varargin
    VARARGIN_ARRAY=("${JOB_PARTS[@]:4:${#JOB_PARTS[@]}-6}")
    
    # Process varargin to get string and suffix
    RESULT=$(process_varargin "${VARARGIN_ARRAY[@]}")
    IFS='|||' read -r VARARGIN_STR EXPT_SUFFIX <<< "${RESULT}"
    
    # Build experiment name
    EXPT_NAME="simplex_mapper_raw_features_cohort_${COHORT}_${SESSION}_${SIMPLEX}_${PARCELLATION}${EXPT_SUFFIX}"
    
    # Determine array specification
    if [ "${FILENAME_PATTERN}" = "(none)" ]; then
        # Full array - count lines in CSV file minus 1 for header
        N_SUBJECTS=$(( $(wc -l < "${COHORT_DIR}cohort_${COHORT}_session_${SESSION}.csv") - 1 ))
        ARRAY_SPEC="1-${N_SUBJECTS}%50"
        ARRAY_DESC="${N_SUBJECTS} subjects (full cohort)"
    else
        # Re-run failed tasks only
        echo "Searching for failed tasks matching pattern: ${FILENAME_PATTERN}"
        FAILED_TASKS=$(find_failed_tasks "${FILENAME_PATTERN}")
        
        if [ -z "${FAILED_TASKS}" ]; then
            echo "WARNING: No failed tasks found for pattern '${FILENAME_PATTERN}'"
            echo "Skipping this job."
            echo ""
            continue
        fi
        
        # Convert newline-separated list to comma-separated
        ARRAY_SPEC=$(echo "${FAILED_TASKS}" | tr '\n' ',' | sed 's/,$//')
        TASK_COUNT=$(echo "${FAILED_TASKS}" | wc -l)
        
        echo "Found ${TASK_COUNT} failed tasks: ${ARRAY_SPEC}"
        ARRAY_DESC="${TASK_COUNT} failed tasks"
    fi
    
    # Build sbatch command
    if [ ${CUMULATIVE_DELAY} -eq 0 ]; then
        # First job - submit immediately
        SUBMIT_CMD="sbatch --time=01:00:00 --cpus-per-task=8 --mem-per-cpu=8G --array=${ARRAY_SPEC} ${SCRIPT} \"${COHORT}\" \"${SESSION}\" \"${SIMPLEX}\" \"${PARCELLATION}\" \"${EXPT_NAME}\" 1 \"${VARARGIN_STR}\""
        
        echo "Job $((JOB_COUNT + 1)): Submitting NOW"
    else
        # Subsequent jobs - schedule for later
        START_TIME=$(date -d "+${CUMULATIVE_DELAY} minutes" '+%Y-%m-%dT%H:%M:%S')
        SUBMIT_CMD="sbatch --time=01:00:00 --cpus-per-task=8 --mem-per-cpu=8G --array=${ARRAY_SPEC} --begin=${START_TIME} ${SCRIPT} \"${COHORT}\" \"${SESSION}\" \"${SIMPLEX}\" \"${PARCELLATION}\" \"${EXPT_NAME}\" 1 \"${VARARGIN_STR}\""
        
        echo "Job $((JOB_COUNT + 1)): Scheduling for ${START_TIME}"
    fi
    
    echo "  ${COHORT}/${SESSION}/${SIMPLEX}/${PARCELLATION}"
    if [ -n "${VARARGIN_STR}" ]; then
        echo "  Varargin: ${VARARGIN_STR}"
    fi
    echo "  Array: ${ARRAY_SPEC} (${ARRAY_DESC})"
    if [ ${CUMULATIVE_DELAY} -gt 0 ]; then
        echo "  Start: ${CUMULATIVE_DELAY} min from now"
    fi
    echo "  Estimated duration: ${ESTIMATED_MINUTES} min"
    echo "  Experiment: ${EXPT_NAME}"
    echo "  Command: ${SUBMIT_CMD}"
    
    eval ${SUBMIT_CMD}
    echo ""
    
    # Update cumulative delay for next job
    CUMULATIVE_DELAY=$((CUMULATIVE_DELAY + ESTIMATED_MINUTES))
    JOB_COUNT=$((JOB_COUNT + 1))
done

# ============================================
# ACTUAL CODE ENDS HERE
# ============================================

echo "Submission complete!"
echo ""
echo "Summary:"
echo "  Total jobs submitted:      ${JOB_COUNT}"
echo "  Total estimated duration:  ${CUMULATIVE_DELAY} minutes (~$((CUMULATIVE_DELAY / 60)) hours $((CUMULATIVE_DELAY % 60)) min)"
echo "  Expected completion:       $(date -d "+${CUMULATIVE_DELAY} minutes" '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "Useful commands:"
echo "  Check status:      squeue -u ${USER}"
echo "  View scheduled:    squeue -u ${USER} --start"
echo "  View details:      sacct -j <JOB_ID> --format=JobID,State,Elapsed,ExitCode"
echo "  Cancel all:        scancel -u ${USER}"
echo "  Cancel specific:   scancel <JOB_ID>"
echo ""

# ============================================
# End logging
# ============================================
echo "Script completed successfully"
echo "End time: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
echo ""
echo ""