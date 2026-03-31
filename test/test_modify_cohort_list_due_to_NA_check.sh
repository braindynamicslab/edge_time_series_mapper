#!/bin/bash

# Rename cohort CSV files by adding _noNAcheck suffix
# Changes: cohort_*.csv -> cohort_*_noNAcheck.csv

# Directory containing the files
DIR="../data_pipeline/data_cohort"

# Check if directory exists
if [ ! -d "$DIR" ]; then
    echo "Error: Directory $DIR does not exist"
    exit 1
fi

# Counter for renamed files
count=0

echo "old directory"
ls $DIR

# Find and rename all cohort_*.csv files
for file in "$DIR"/cohort_*.csv; do
    # Check if file exists (handles case where no matches found)
    if [ -e "$file" ]; then
        # Extract directory, basename, and extension
        dirname=$(dirname "$file")
        basename=$(basename "$file" .csv)
        
        # Create new filename
        newfile="${dirname}/${basename}_noNAcheck.csv"
        
        # Rename the file
        mv "$file" "$newfile"
        echo "Renamed: $file -> $newfile"
        ((count++))
    fi
done

if [ $count -eq 0 ]; then
    echo "No files matching 'cohort_*.csv' found in $DIR"
else
    echo "Successfully renamed $count file(s)"
fi

echo "new directory"
ls $DIR
