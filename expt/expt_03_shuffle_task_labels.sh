#!/bin/bash
#SBATCH --job-name=expt_shuffle_task_labels
#
# RESOURCE ALLOCATION
# The resource allocation below works for node or edge time series, but probably is insufficient for triangle time series
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=2G

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

REPO_ROOT="/home/users/siuc/edge_time_series_mapper/"
CURRENT_DIRECTORY=$(pwd)
cd $REPO_ROOT

ml load matlab

# Base command with required arguments
MATLAB_COMMAND="addpath(genpath('${REPO_ROOT}')); \
expt_03_shuffle_task_labels;"
# expt_03_shuffle_task_labels.m" is a script in REPO_ROOT/expt/

# Notes on parameter passing:
# \ means the string continues in the next line

# Note: Do not separate the addpath-genpath line into two MATLAB calls.
# This would open two MATLAB sessions, one just add the path and does nothing,
# and the other tries the call the function without adding the path.

echo $MATLAB_COMMAND
matlab -nodisplay -batch "$MATLAB_COMMAND"

# Check if MATLAB succeeded and created temp file
if [ $? -eq 0 ] ; then
    echo "Successfully ran expt_03_shuffle_task_labels"
else
    echo "ERROR: MATLAB failed"
    exit 1
fi

cd $CURRENT_DIRECTORY