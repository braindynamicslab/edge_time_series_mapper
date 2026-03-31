#!/bin/bash

# Move old cohort CSV files (with _noNAcheck suffix) to data_cohort_old directory
# Moves: cohort_*_noNAcheck.csv from data_pipeline/data_cohort to data_pipeline/data_cohort_old

# Source and destination directories
SOURCE_DIR="../data_pipeline/data_cohort"
DEST_DIR="../data_pipeline/data_cohort_old"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory $SOURCE_DIR does not exist"
    exit 1
fi

# Create destination directory if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
    mkdir -p "$DEST_DIR"
    echo "Created directory: $DEST_DIR"
fi

# Counter for moved files
count=0

# Find and move all cohort_*_noNAcheck.csv files
for file in "$SOURCE_DIR"/cohort_*_noNAcheck.csv; do
    # Check if file exists (handles case where no matches found)
    if [ -e "$file" ]; then
        # Get just the filename
        filename=$(basename "$file")
        
        # Move the file
        mv "$file" "$DEST_DIR/$filename"
        echo "Moved: $filename"
        ((count++))
    fi
done

if [ $count -eq 0 ]; then
    echo "No files matching 'cohort_*_noNAcheck.csv' found in $SOURCE_DIR"
else
    echo "Successfully moved $count file(s) to $DEST_DIR"
fi
