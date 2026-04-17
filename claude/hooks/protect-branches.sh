#!/bin/bash
#
# PreToolUse hook: blocks git commands (except fetch/pull) on protected branches.
#
# Configuration: set PROTECTED_BRANCHES as a colon-separated list of branch names.
#
#   export PROTECTED_BRANCHES="main:master:production"
#
# Or create a .protected-branches file in the workspace root (one name per line):
#
#   main
#   master
#   production
#
# Defaults to: main, master
#

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
    exit 0
fi

# Only inspect git commands
if ! echo "$command" | grep -qE '(^|\s|&&|\|\||;)git\s'; then
    exit 0
fi

# Extract the first git subcommand from the command string
git_subcmd=$(echo "$command" | grep -oE '(^|\s|&&|\|\||;)\s*git\s+[a-z-]+' | head -1 | awk '{print $NF}')

# Allow fetch/pull/worktree and read-only inspection commands
case "$git_subcmd" in
    fetch|pull|worktree|\
    status|diff|log|show|blame|branch|tag|remote|config|\
    rev-parse|describe|reflog|grep|ls-files|ls-tree|ls-remote|\
    cat-file|shortlog|whatchanged|name-rev|for-each-ref|\
    help|version)
        exit 0
        ;;
esac

# Load protected branches from env var, config file, or defaults
protected_branches=()

cwd=$(echo "$input" | jq -r '.cwd // empty')
workspace_root="${cwd:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
config_file="$workspace_root/.protected-branches"

if [ -n "$PROTECTED_BRANCHES" ]; then
    IFS=':' read -ra protected_branches <<< "$PROTECTED_BRANCHES"
elif [ -f "$config_file" ]; then
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line%"${line##*[! ]}"}"
        [ -n "$line" ] && protected_branches+=("$line")
    done < "$config_file"
else
    protected_branches=("main" "master")
fi

if [ ${#protected_branches[@]} -eq 0 ]; then
    exit 0
fi

# Get current branch
current_branch=$(git -C "$workspace_root" rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ -z "$current_branch" ]; then
    exit 0
fi

for branch in "${protected_branches[@]}"; do
    if [ "$current_branch" = "$branch" ]; then
        cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"git ${git_subcmd} is not allowed on protected branch '${branch}'. Only fetch/pull/worktree and read-only inspection commands are permitted. Switch to a feature branch or create a worktree first."}}
EOF
        exit 0
    fi
done

exit 0
