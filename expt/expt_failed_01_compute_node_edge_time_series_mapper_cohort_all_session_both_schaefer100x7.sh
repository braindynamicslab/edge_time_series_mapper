#!/bin/bash

SCRIPT="fcn/edgeMapper/slurm_edgeMapper_compute_and_analyze_simplex_mapper.sbatch"
PARCELLATION="schaefer100x7"

COHORTS=("one" "all_but_one")
#SESSIONS=("LR" "RL")
SESSIONS=("LR")
SIMPLEXES=("node" "edge")

PREV_JOB=""

# Loop through cohorts and sessions
for SESSION in "${SESSIONS[@]}"; do
    for COHORT in "${COHORTS[@]}"; do
        for SIMPLEX in "${SIMPLEXES[@]}"; do
            EXPT_NAME="simplex_mapper_raw_features_cohort_${COHORT}_${SESSION}_${SIMPLEX}_${PARCELLATION}"
            
            if [ -z "${PREV_JOB}" ]; then
                PREV_JOB=$(sbatch --parsable ${SCRIPT} "${COHORT}" "${SESSION}" "${SIMPLEX}" "${PARCELLATION}" "${EXPT_NAME}")
                echo "Submitted job ${PREV_JOB}: cohort=${COHORT}, session=${SESSION}, simplex=${SIMPLEX}"
            else
                PREV_JOB=$(sbatch --dependency=afterok:${PREV_JOB} --parsable ${SCRIPT} "${COHORT}" "${SESSION}" "${SIMPLEX}" "${PARCELLATION}" "${EXPT_NAME}")
                echo "Submitted job ${PREV_JOB}: cohort=${COHORT}, session=${SESSION}, simplex=${SIMPLEX} (depends on previous simplex)"
            fi
        done
        
        echo "  Finished chain for cohort=${COHORT}, session=${SESSION}"
    done
done

echo ""
echo "All jobs submitted!"
