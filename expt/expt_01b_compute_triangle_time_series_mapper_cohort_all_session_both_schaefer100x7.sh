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
PARCELLATION="schaefer100x7"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# ============================================
# User input (BEFORE redirecting output)
# ============================================
echo "============================================"
echo "SIMPLEX MAPPER JOB SUBMISSION (TIME-BASED)"
echo "============================================"
echo ""
echo "Configuration:"
echo "  Parcellation: ${PARCELLATION}"
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
echo "  Parcellation:         ${PARCELLATION}"
echo "  Cohort directory:     ${COHORT_DIR}"
echo ""

# ============================================
# DEFINE ALL JOBS MANUALLY
# ============================================
# Format: "COHORT|SESSION|SIMPLEX|ESTIMATED_MINUTES"
# - COHORT: cohort name (e.g., "one", "all_but_one")
# - SESSION: session name (e.g., "LR", "RL")
# - SIMPLEX: simplex type (e.g., "node", "edge")
# - ESTIMATED_MINUTES: how long this job will take to complete
#
# Jobs run sequentially in the order listed below.
# Each job starts when the previous job is estimated to finish.
# To skip a job, comment it out with #

JOBS=(
    #"one|LR|triangle|120"
    "one|RL|triangle|120"
    #"all_but_one|LR|triangle|240"
    #"all_but_one|RL|triangle|240"
)

# ============================================
# ACTUAL CODE STARTS HERE
# ============================================

echo "Submitting ${#JOBS[@]} jobs sequentially..."
echo ""

JOB_COUNT=0
CUMULATIVE_DELAY=0  # Track total delay from NOW for sequential scheduling

for JOB_SPEC in "${JOBS[@]}"; do
    # Parse job specification
    IFS='|' read -r COHORT SESSION SIMPLEX ESTIMATED_MINUTES <<< "${JOB_SPEC}"
    
    # Validate estimated minutes
    if ! [[ "${ESTIMATED_MINUTES}" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Invalid estimated minutes '${ESTIMATED_MINUTES}' for job: ${JOB_SPEC}"
        exit 1
    fi
    
    # Build experiment name
    EXPT_NAME="simplex_mapper_raw_features_cohort_${COHORT}_${SESSION}_${SIMPLEX}_${PARCELLATION}"
    
    # Get cohort size: count lines in CSV file minus 1 for header
    N_SUBJECTS=$(( $(wc -l < "${COHORT_DIR}cohort_${COHORT}_session_${SESSION}.csv") - 1 ))
    ARRAY_SPEC="1-${N_SUBJECTS}%40"
    
    # Build sbatch command
    if [ ${CUMULATIVE_DELAY} -eq 0 ]; then
        # First job - submit immediately
        SUBMIT_CMD="sbatch --time=00:20:00 --cpus-per-task=8 --mem-per-cpu=8G --array=${ARRAY_SPEC} ${SCRIPT} \"${COHORT}\" \"${SESSION}\" \"${SIMPLEX}\" \"${PARCELLATION}\" \"${EXPT_NAME}\""
        echo "Job $((JOB_COUNT + 1)): Submitting NOW"
        echo "  ${COHORT}/${SESSION}/${SIMPLEX}"
        echo "  Array: ${ARRAY_SPEC} (${N_SUBJECTS} subjects)"
        echo "  Estimated duration: ${ESTIMATED_MINUTES} min"
        echo "  Command: ${SUBMIT_CMD}"
    else
        # Subsequent jobs - schedule for later
        START_TIME=$(date -d "+${CUMULATIVE_DELAY} minutes" '+%Y-%m-%dT%H:%M:%S')
        SUBMIT_CMD="sbatch --time=00:20:00 --cpus-per-task=8 --mem-per-cpu=8G --array=${ARRAY_SPEC} --begin=${START_TIME} ${SCRIPT} \"${COHORT}\" \"${SESSION}\" \"${SIMPLEX}\" \"${PARCELLATION}\" \"${EXPT_NAME}\""
        echo "Job $((JOB_COUNT + 1)): Scheduling for ${START_TIME}"
        echo "  ${COHORT}/${SESSION}/${SIMPLEX}"
        echo "  Array: ${ARRAY_SPEC} (${N_SUBJECTS} subjects)"
        echo "  Start: ${CUMULATIVE_DELAY} min from now"
        echo "  Estimated duration: ${ESTIMATED_MINUTES} min"
        echo "  Command: ${SUBMIT_CMD}"
    fi
    
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
