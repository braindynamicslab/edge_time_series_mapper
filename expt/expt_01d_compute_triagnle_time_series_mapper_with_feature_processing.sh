#!/bin/bash
#
# bash_submit_simplex_mapper_jobs.sh
#
# Submit SLURM jobs for simplex mapper analysis with time-based scheduling
# 
# MANUAL MODE: Each job is explicitly defined below.
# Jobs run sequentially - each starts when the previous one is estimated to finish.
# Array size is automatically determined from cohort files.
#

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
echo ""

# ============================================
# DEFINE ALL JOBS MANUALLY
# ============================================
# Format: "COHORT|SESSION|SIMPLEX|PARCELLATION|VARARGIN1|VARARGIN2|...|ESTIMATED_MINUTES"
# - COHORT: cohort name (e.g., "one", "all_but_one")
# - SESSION: session name (e.g., "LR", "RL")
# - SIMPLEX: simplex type (e.g., "node", "edge")
# - PARCELLATION: parcellation name (e.g., "schaefer100x7", "schaefer200x7")
# - VARARGIN1-N: optional arguments to pass to MATLAB (use "(none)" if not needed)
# - ESTIMATED_MINUTES: how long this job will take to complete (MUST BE LAST)
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
#   No varargin:
#     "one|LR|node|schaefer200x7|(none)|(none)|(none)|(none)|120"
#   
#   Four varargin arguments (two key-value pairs):
#     "one|LR|node|schaefer100x7|'dim_reduction_type'|'pca_variance_threshold'|'target_explained_variance'|0.95|120"
#   
#   Two varargin arguments (one key-value pair):
#     "one|LR|edge|schaefer100x7|'activity_mask_flag'|1|(none)|(none)|300"

JOBS=(
    "one|LR|triangle|schaefer100x7|'dim_reduction_type'|'pca_variance_threshold'|'target_explained_variance'|0.95|150"
    "one|LR|triangle|schaefer100x7|'dim_reduction_type'|'pca_fixed_components'|'target_num_features'|20|150"
    "one|LR|triangle|schaefer100x7|'dim_reduction_type'|'pca_fixed_components'|'target_num_features'|30|150"
    "one|LR|triangle|schaefer100x7|'dim_reduction_type'|'pca_fixed_components'|'target_num_features'|40|150"
    "one|LR|triangle|schaefer100x7|'activity_mask_flag'|1|'sign_by_coherence_flag'|1|150"
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
    
    # Last element is estimated minutes
    ESTIMATED_MINUTES="${JOB_PARTS[-1]}"
    
    # Validate estimated minutes
    if ! [[ "${ESTIMATED_MINUTES}" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Invalid estimated minutes '${ESTIMATED_MINUTES}' for job: ${JOB_SPEC}"
        exit 1
    fi
    
    # Everything between position 4 and last element is varargin
    VARARGIN_ARRAY=("${JOB_PARTS[@]:4:${#JOB_PARTS[@]}-5}")
    
    # Process varargin to get string and suffix
    RESULT=$(process_varargin VARARGIN_ARRAY)
    IFS='|||' read -r VARARGIN_STR EXPT_SUFFIX <<< "${RESULT}"
    
    # Build experiment name
    EXPT_NAME="simplex_mapper_raw_features_cohort_${COHORT}_${SESSION}_${SIMPLEX}_${PARCELLATION}${EXPT_SUFFIX}"
    
    # Get cohort size: count lines in CSV file minus 1 for header
    N_SUBJECTS=$(( $(wc -l < "${COHORT_DIR}cohort_${COHORT}_session_${SESSION}.csv") - 1 ))
    ARRAY_SPEC="1-${N_SUBJECTS}%50"
    
    # Build sbatch command
    # The VARARGIN_STR is passed as the 7th argument to the sbatch script
    if [ ${CUMULATIVE_DELAY} -eq 0 ]; then
        # First job - submit immediately
        SUBMIT_CMD="sbatch --time=00:20:00 --cpus-per-task=8 --mem-per-cpu=8G  --array=${ARRAY_SPEC} ${SCRIPT} \"${COHORT}\" \"${SESSION}\" \"${SIMPLEX}\" \"${PARCELLATION}\" \"${EXPT_NAME}\" 1 \"${VARARGIN_STR}\""
        
        echo "Job $((JOB_COUNT + 1)): Submitting NOW"
    else
        # Subsequent jobs - schedule for later
        START_TIME=$(date -d "+${CUMULATIVE_DELAY} minutes" '+%Y-%m-%dT%H:%M:%S')
        SUBMIT_CMD="sbatch --time=00:20:00 --cpus-per-task=8 --mem-per-cpu=8G  --array=${ARRAY_SPEC} --begin=${START_TIME} ${SCRIPT} \"${COHORT}\" \"${SESSION}\" \"${SIMPLEX}\" \"${PARCELLATION}\" \"${EXPT_NAME}\" 1 \"${VARARGIN_STR}\""
        
        echo "Job $((JOB_COUNT + 1)): Scheduling for ${START_TIME}"
    fi
    
    echo "  ${COHORT}/${SESSION}/${SIMPLEX}/${PARCELLATION}"
    if [ -n "${VARARGIN_STR}" ]; then
        echo "  Varargin: ${VARARGIN_STR}"
    fi
    echo "  Array: ${ARRAY_SPEC} (${N_SUBJECTS} subjects)"
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