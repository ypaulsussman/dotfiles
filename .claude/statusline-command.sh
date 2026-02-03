#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Get just the directory name
dir_name=$(basename "$cwd")

# Get git branch if in a git repository
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || echo "detached")
    git_info=" ($branch)"
else
    git_info=""
fi

# Display context usage if available
if [ -n "$remaining" ]; then
    context_info=" [ctx: ${remaining}%]"
else
    context_info=""
fi

echo "${dir_name}${git_info}${context_info}"
