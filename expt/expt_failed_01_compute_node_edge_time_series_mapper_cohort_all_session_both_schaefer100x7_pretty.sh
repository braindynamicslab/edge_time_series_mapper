#!/bin/bash
#
# bash_submit_simplex_mapper_jobs.sh
#
# Submit SLURM jobs for simplex mapper analysis across cohorts, sessions, and simplexes
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

SCRIPT="fcn/edgeMapper/slurm_edgeMapper_compute_and_analyze_simplex_mapper.sbatch"
PARCELLATION="schaefer100x7"

COHORTS=("one" "all_but_one")
SESSIONS=("LR")
#SESSIONS=("LR" "RL")  # Uncomment for both sessions
SIMPLEXES=("node" "edge")

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# ============================================
# User input (BEFORE redirecting output)
# ============================================
echo "============================================"
echo "SIMPLEX MAPPER JOB SUBMISSION"
echo "============================================"
echo ""
echo "Configuration:"
echo "  Cohorts:      ${COHORTS[*]}"
echo "  Sessions:     ${SESSIONS[*]}"
echo "  Simplexes:    ${SIMPLEXES[*]}"
echo "  Parcellation: ${PARCELLATION}"
echo ""
echo "Total job chains: $(( ${#SESSIONS[@]} * ${#COHORTS[@]} ))"
echo "Jobs per chain:   ${#SIMPLEXES[@]}"
echo "Total jobs:       $(( ${#SESSIONS[@]} * ${#COHORTS[@]} * ${#SIMPLEXES[@]} ))"
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
echo "  SLURM script:  ${SCRIPT}"
echo "  Parcellation:  ${PARCELLATION}"
echo "  Cohorts:       ${COHORTS[*]}"
echo "  Sessions:      ${SESSIONS[*]}"
echo "  Simplexes:     ${SIMPLEXES[*]}"
echo ""

# ============================================
# ACTUAL CODE STARTS HERE
# ============================================

echo "Submitting jobs..."
echo ""

JOB_COUNT=0
CHAIN_COUNT=0

for SESSION in "${SESSIONS[@]}"; do
    for COHORT in "${COHORTS[@]}"; do
        CHAIN_COUNT=$((CHAIN_COUNT + 1))
        PREV_JOB=""
        
        echo "Chain ${CHAIN_COUNT}: cohort=${COHORT}, session=${SESSION}"
        
        for SIMPLEX in "${SIMPLEXES[@]}"; do
            EXPT_NAME="simplex_mapper_raw_features_cohort_${COHORT}_${SESSION}_${SIMPLEX}_${PARCELLATION}"

            if [ -z "${PREV_JOB}" ]; then
                PREV_JOB=$(sbatch --parsable ${SCRIPT} "${COHORT}" "${SESSION}" "${SIMPLEX}" "${PARCELLATION}" "${EXPT_NAME}")
                echo "  Submitted job ${PREV_JOB}: cohort=${COHORT}, session=${SESSION}, simplex=${SIMPLEX}"
            else
                PREV_JOB=$(sbatch --dependency=afterok:${PREV_JOB} --parsable ${SCRIPT} "${COHORT}" "${SESSION}" "${SIMPLEX}" "${PARCELLATION}" "${EXPT_NAME}")
                echo "  Submitted job ${PREV_JOB}: cohort=${COHORT}, session=${SESSION}, simplex=${SIMPLEX} (depends on previous)"
            fi
            
            JOB_COUNT=$((JOB_COUNT + 1))
        done
        
        echo ""
    done
done

# ============================================
# ACTUAL CODE ENDS HERE
# ============================================

echo "Submission complete!"
echo ""
echo "Summary:"
echo "  Total job chains:  ${CHAIN_COUNT}"
echo "  Total jobs:        ${JOB_COUNT}"
echo ""
echo "Useful commands:"
echo "  Check status:      squeue -u ${USER}"
echo "  View details:      sacct -j <JOB_ID>"
echo "  Cancel all:        scancel -u ${USER}"
echo ""

# ============================================
# End logging
# ============================================
echo "Script completed successfully"
echo "End time: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
echo ""
echo ""
