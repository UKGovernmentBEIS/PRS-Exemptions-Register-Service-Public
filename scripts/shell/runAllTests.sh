#!/bin/bash

#Run this if you don't have permission
#chmod +x ./scripts/shell/runAllTests.sh

# Default folder path
DEFAULT_PATH="./force-app/main/default/test"

# Use provided path or default
FOLDER_PATH="${1:-$DEFAULT_PATH}"

# Find all .cls files and extract class names
CLASS_NAMES=$(find "$FOLDER_PATH" -type f -name "*.cls" -exec basename {} .cls \; | awk '{print "--class-names " $0}' | tr '\n' ' ')

# Run the test and capture the output
echo -e "\e[32mRunning tests\e[0m"
output=$(sf apex run test $CLASS_NAMES --result-format human)

echo -e "\e[32mRetrieving test output\e[0m"
# Extract the command inside the quotes
cmd=$(echo "$output" | grep -oP 'Run "\K[^"]+')

# Execute the extracted command
eval "$cmd"
