#!/bin/bash

# Function to generate call tree
generate_call_tree() {
    local script=$1

    # Check if script file exists
    if [[ ! -f $script ]]; then
        echo "File $script does not exist."
        exit 1
    fi

    # Source the script to load its functions
    source $script

    # Get all function names
    local functions=$(declare -F | cut -d " " -f 3)

    # For each function
    for func in $functions; do
        echo "Function: $func"
        echo "Called at lines:"

        # Search for function calls in the script
        grep -n "$func(" $script | cut -d ":" -f 1

        echo "----------------------"
    done
}

# Call the function with the script as argument
generate_call_tree $1



#!/bin/bash

# Check if a script name was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <script>"
    exit 1
fi

SCRIPT=$1

# Check if the script exists
if [ ! -f "$SCRIPT" ]; then
    echo "File not found: $SCRIPT"
    exit 1
fi

# Extract function names
FUNCTIONS=$(grep -oP '^\s*\K\w+(?=\s*\(\))' "$SCRIPT")

# For each function
for FUNC in $FUNCTIONS; do
    echo "Function: $FUNC"
    echo "Called by:"
    # Find lines where the function is called
    grep -nP "\b$FUNC\b" "$SCRIPT" | while read -r line; do
        # Extract the function where the call is made
        caller=$(echo "$line" | grep -oP '^\s*\K\w+(?=\s*\(\))')
        # If the caller is not empty and is not the same as the function
        if [ -n "$caller" ] && [ "$caller" != "$FUNC" ]; then
            # Print the caller and the line
            echo "  $caller at line $(echo "$line" | grep -oP '^\K\d+(?=:)' )"
        fi
    done
    echo
done
