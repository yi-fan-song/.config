#!/bin/bash
input=$(cat)

# Parse fields
session_name=$(echo "$input" | jq -r '.session_name // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // empty')
percentage=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
rate_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0')
rate_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0')

# Shorten cwd: ~/repo/web -> web, ~/repo -> repo
cwd_short="${cwd/#$HOME\/repo\//}"
cwd_short="${cwd_short/#$HOME\/repo/repo}"
cwd_short="${cwd_short/#$HOME/~}"

# Colors
dim="\033[2m"
cyan="\033[36m"
reset="\033[0m"

# Color helper for percentages (green < 50, yellow < 80, red >= 80)
pct_color() {
    local val="${1%.*}" # truncate decimals
    if [ "$val" -ge 80 ] 2>/dev/null; then echo -n "\033[31m"
    elif [ "$val" -ge 50 ] 2>/dev/null; then echo -n "\033[33m"
    else echo -n "\033[32m"; fi
}

# Build: name (cwd) [model]
out=""
if [ -n "$session_name" ]; then
    out="${cyan}${session_name}${reset}"
else
    out="${dim}unnamed${reset}"
fi
out="$out ${dim}(${cwd_short})${reset} ${dim}[${model}]${reset}"

# Worktree
if [ -n "$worktree_branch" ]; then
    out="$out ${dim}|${reset} ${cyan}${worktree_branch}${reset}"
fi

# Context %
ctx_color=$(pct_color "$percentage")
out="$out ${dim}|${reset} ${ctx_color}${percentage}%${reset}"

# Rate limits
r5_color=$(pct_color "$rate_5h")
r7_color=$(pct_color "$rate_7d")
r5_int="${rate_5h%.*}"
r7_int="${rate_7d%.*}"
out="$out ${dim}| 5h${reset} ${r5_color}${r5_int}%${reset} ${dim}7d${reset} ${r7_color}${r7_int}%${reset}"

echo -e "$out"
