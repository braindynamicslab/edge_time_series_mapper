#!/bin/bash

# ========================================================
# SPECIPY INPUTS HERE
# ========================================================
# Default directory is current directory if not specified
# DIR="${1:-.}"
# Default output file location
# OUTPUT_FILE="${2:-./directory_contents.txt}"

# DIR="/Users/siuc/Documents/GitHub/edge_time_series_mapper/fcn/"
# OUTPUT_FILE="/Users/siuc/Documents/GitHub/edge_time_series_mapper/test/file_tree/fcn_26032501.txt"

# DIR="/Users/siuc/Documents/GitHub/edge_time_series_mapper/config/"
# OUTPUT_FILE="/Users/siuc/Documents/GitHub/edge_time_series_mapper/test/file_tree/config_26032501.txt"

# DIR="/Users/siuc/Documents/GitHub/edge_time_series_mapper/fcn/"
# OUTPUT_FILE="/Users/siuc/Documents/GitHub/edge_time_series_mapper/test/file_tree/fcn_26071001.txt"

DIR="/Users/siuc/Documents/GitHub/edge_time_series_mapper/expt/"
OUTPUT_FILE="/Users/siuc/Documents/GitHub/edge_time_series_mapper/test/file_tree/expt_26071001.txt"

# ========================================================

# Check if directory exists
if [ ! -d "$DIR" ]; then
    echo "Error: Directory '$DIR' does not exist"
    exit 1
fi

# Create output directory if it doesn't exist
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# Function to write output (both to file and console)
write_output() {
    echo "$1" | tee -a "$OUTPUT_FILE"
}

# Clear/create output file
> "$OUTPUT_FILE"

echo "Saving directory analysis to: $OUTPUT_FILE"
echo ""

write_output "========================================="
write_output "DIRECTORY TREE"
write_output "========================================="
write_output ""

# Print directory tree
if command -v tree &> /dev/null; then
    tree "$DIR" | tee -a "$OUTPUT_FILE"
else
    # Fallback to find-based tree display
    find "$DIR" -print | sed -e "s;$DIR;.;g;s;[^/]*\/;|___;g;s;___|; |;g" | tee -a "$OUTPUT_FILE"
fi

write_output ""
write_output "========================================="
write_output "FILE CONTENTS"
write_output "========================================="
write_output ""

# Find and cat all files recursively
find "$DIR" -type f | sort | while IFS= read -r file; do
    {
        echo "╔═══════════════════════════════════════"
        echo "║ File: $file"
        echo "╚═══════════════════════════════════════"
        echo ""
        
        # Check if file is readable and appears to be text
        if [ -r "$file" ]; then
            if file "$file" | grep -q text; then
                cat "$file"
            else
                echo "[Binary file - skipped]"
            fi
        else
            echo "[File is not readable]"
        fi
        
        echo ""
        echo "---"
        echo ""
    } | tee -a "$OUTPUT_FILE"
done

write_output "========================================="
write_output "COMPLETE"
write_output "========================================="

echo ""
echo "Output saved to: $OUTPUT_FILE"