#!/bin/bash
#
# PreToolUse hook: blocks Edit/Write to protected directories.
# Claude must use a worktree instead of editing these folders directly.
#
# Configuration: set ENFORCE_WORKTREE_DIRS as a colon-separated list of
# absolute paths to protect. Defaults below match the Pivot repo layout.
#
#   export ENFORCE_WORKTREE_DIRS="/Users/me/repo/mobile:/Users/me/repo/web"
#
# Or create a .enforce-worktree file in the workspace root (one path per line):
#
#   /Users/me/repo/mobile
#   /Users/me/repo/web
#

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [ -z "$file_path" ]; then
    exit 0
fi

# Load protected dirs from env var, config file, or defaults
protected_dirs=()

# Resolve workspace root: hook lives at <workspace>/.claude/hooks/
cwd=$(echo "$input" | jq -r '.cwd // empty')
workspace_root="${cwd:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
config_file="$workspace_root/.enforce-worktree"

if [ -n "$ENFORCE_WORKTREE_DIRS" ]; then
    IFS=':' read -ra protected_dirs <<< "$ENFORCE_WORKTREE_DIRS"
elif [ -f "$config_file" ]; then
    while IFS= read -r line; do
        line="${line%%#*}"     # strip comments
        line="${line%"${line##*[! ]}"}" # trim trailing whitespace
        [ -n "$line" ] && protected_dirs+=("$line")
    done < "$config_file"
fi

if [ ${#protected_dirs[@]} -eq 0 ]; then
    exit 0
fi

for dir in "${protected_dirs[@]}"; do
    # Ensure dir ends with / for prefix matching
    [[ "$dir" != */ ]] && dir="$dir/"

    if [[ "$file_path" == "$dir"* ]]; then
        dirname=$(basename "${dir%/}")
        cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Direct edits to ${dirname}/ are not allowed. Create a worktree first and work there instead."}}
EOF
        exit 0
    fi
done

exit 0
