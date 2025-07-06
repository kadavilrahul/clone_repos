#!/bin/bash

# Interactive script to count and compare total lines of code in multiple codebases
# Uses: find /path/to/folder -type f -exec wc -l {} + | tail -n 1

# Output file for results
OUTPUT_FILE="codebase_line_counts.txt"

# Function to handle script cleanup on exit
cleanup() {
    echo ""
    echo "Script completed!"
}

# Set up cleanup trap
trap cleanup EXIT

# Function to check if output file is writable
check_output_file() {
    if ! touch "$OUTPUT_FILE" 2>/dev/null; then
        echo "Error: Cannot write to output file '$OUTPUT_FILE'"
        echo "Please check permissions or choose a different location."
        exit 1
    fi
}

# Check output file writability
check_output_file

# Clear the output file and add header
echo "Codebase Line Count Comparison" > "$OUTPUT_FILE"
echo "Generated on: $(date)" >> "$OUTPUT_FILE"
echo "======================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "Interactive Codebase Line Counter"
echo "================================="
echo "This script will count total lines of code in multiple codebases."
echo "Results will be saved to: $OUTPUT_FILE"
echo ""

# Counter for codebase number
counter=1

while true; do
    echo "Codebase #$counter"
    echo "-------------"
    
    # Get folder path from user
    read -p "Enter the path to codebase folder (or 'quit' to finish): " folder_path
    
    # Trim whitespace
    folder_path=$(echo "$folder_path" | xargs)
    
    # Check if user wants to quit
    if [[ "$folder_path" == "quit" || "$folder_path" == "q" || -z "$folder_path" ]]; then
        break
    fi
    
    # Expand tilde to home directory
    folder_path="${folder_path/#\~/$HOME}"
    
    # Check if folder exists and is readable
    if [[ ! -d "$folder_path" ]]; then
        echo "Error: Directory '$folder_path' does not exist!"
        echo "Please try again."
        echo ""
        continue
    elif [[ ! -r "$folder_path" ]]; then
        echo "Error: Directory '$folder_path' is not readable!"
        echo "Please check permissions and try again."
        echo ""
        continue
    fi
    
    # Use folder name as codebase name
    codebase_name=$(basename "$folder_path")
    
    echo "Counting lines in '$codebase_name'..."
    
    # Count files first to provide better feedback
    file_count=$(find "$folder_path" -type f -readable 2>/dev/null | wc -l)
    
    if [[ "$file_count" == "0" ]]; then
        echo "Warning: No readable files found in '$folder_path'"
        line_count="0"
    else
        # Count lines using the specified command with better error handling
        line_count=$(find "$folder_path" -type f -readable -exec wc -l {} + 2>/dev/null | tail -n 1 | awk '{print $1}')
        
        # Validate the result
        if [[ -z "$line_count" ]] || ! [[ "$line_count" =~ ^[0-9]+$ ]]; then
            echo "Warning: Unable to count lines properly in '$folder_path'"
            line_count="0"
        fi
    fi
    
    # Format the result with additional info
    result="$codebase_name: $line_count lines ($file_count files) - Path: $folder_path"
    
    # Display result
    echo "SUCCESS: $result"
    
    # Save to file
    echo "$result" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    echo ""
    
    # Increment counter
    ((counter++))
done

echo ""
echo "Summary saved to: $OUTPUT_FILE"
echo ""

# Display final summary
if [[ -f "$OUTPUT_FILE" ]]; then
    echo "Final Results:"
    echo "=============="
    cat "$OUTPUT_FILE"
fi