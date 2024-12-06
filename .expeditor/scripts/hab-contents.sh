#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <hab-content-dir>"
  exit 1
fi

# Base directory to iterate over
base_dir="$1"

# Expand user directory if present
base_dir=$(eval echo "$base_dir")

# Convert relative paths to absolute paths
base_dir=$(realpath "$base_dir")
parent_dir=$(dirname "$base_dir")

# Output file to store the RPM %files entries
output_file="hab-contents.txt"

# Clear the output file
> "$output_file"

content=""

# Function to iterate over the directory recursively
iterate_directory() {
    local dir_path="$1"
    # Check if we are at the top-level directory
    if [ "$dir_path" != "$base_dir" ]; then
	local hab_path="${dir_path#"$parent_dir"}"
        content+="%dir ${hab_path}\n"
    fi

    for entry in "$dir_path"/.* "$dir_path"/*; do
        # Skip current and parent directory entries
        if [ "$entry" == "$dir_path/." ] || [ "$entry" == "$dir_path/.." ]; then
            continue
        fi
        if [ -L "$entry" ]; then
            # Handle symbolic links
	    local hab_path="${entry#"$parent_dir"}"
            content+="${hab_path}\n"
        elif [ -d "$entry" ]; then
            # Recursively process directories
            iterate_directory "$entry"
        elif [ -f "$entry" ]; then
            # Record regular files
	    local hab_path="${entry#"$parent_dir"}"
            content+="${hab_path}\n"
        fi
    done
}

# Start the recursion from the base directory
iterate_directory "$base_dir"

# Write accumulated content to the output file
echo -e "$content" | sudo tee -a "$output_file" > /dev/null
