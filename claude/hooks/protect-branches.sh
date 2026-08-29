#!/bin/bash
#
# PreToolUse(Bash) hook: blocks state-mutating git commands on protected branches.
#
# Registered globally in ~/.claude/settings.json, so it sees every Bash git command
# in every repo. Which repos it guards -- and on which branches -- comes from
# ~/.claude/protected-repos; see that file for the rule format.
#
# Every git repo is protected on `main`/`master` by default. Rules in that file
# opt repos out (`!pattern`) or change their branch set (`pattern:a,b`).
#
# Branch list, first hit wins:
#   1. $PROTECTED_BRANCHES               colon-separated, e.g. "main:master:production"
#   2. the matching rule's `:branches`   from protected-repos
#   3. <repo root>/.protected-branches   one branch per line
#   4. the `default:` line               in protected-repos
#   5. main, master
#
# Requires jq.
#

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
    exit 0
fi

# Only inspect git commands. The class covers every way a command can start:
# line start, whitespace, `&&`/`||`/`;`, and `(`/backtick for subshells and
# substitutions -- `echo $(git commit)` must not slip past.
boundary='(^|[[:space:];&|(`])'

if ! printf '%s' "$command" | grep -qE "${boundary}git[[:space:]]"; then
    exit 0
fi

# Extract the first git subcommand from the command string
git_subcmd=$(printf '%s' "$command" | grep -oE "${boundary}[[:space:]]*git[[:space:]]+[a-z-]+" | head -1 | awk '{print $NF}')

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

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
workspace_root="${cwd:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# The hook's cwd is the session dir at fire time, which for a `cd sub && git ...`
# command is the *pre-cd* dir. Resolve the dir the git command actually targets so
# we check the right repo's branch (a leading `cd <dir>` and `git -C <dir>` both win).
resolve_dir() {
    case "$1" in
        /*) printf '%s' "$1" ;;
        "~"|"~/"*) printf '%s' "${1/#\~/$HOME}" ;;
        *) printf '%s/%s' "$workspace_root" "$1" ;;
    esac
}

target_dir="$workspace_root"
cd_target=$(printf '%s' "$command" | sed -nE 's/(^|.*[;&|][[:space:]]*)cd[[:space:]]+([^;&|[:space:]]+).*/\2/p' | head -1)
[ -n "$cd_target" ] && target_dir=$(resolve_dir "$cd_target")
gitc_target=$(printf '%s' "$command" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+([^;&|[:space:]]+).*/\1/p' | head -1)
[ -n "$gitc_target" ] && target_dir=$(resolve_dir "$gitc_target")

# Not a repo (or a bogus path) -- nothing to protect
repo_root=$(git -C "$target_dir" rev-parse --show-toplevel 2>/dev/null)
if [ -z "$repo_root" ]; then
    exit 0
fi

# In a linked worktree, repo_root is the worktree; main_root is the repo it came
# from. Rules are matched against the worktree first, then the origin repo, so a
# rule written for the repo covers its worktrees too.
main_root=""
common_dir=$(git -C "$target_dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
if [ -z "$common_dir" ]; then
    # git < 2.31: no --path-format, and the answer may come back relative
    common_dir=$(git -C "$target_dir" rev-parse --git-common-dir 2>/dev/null)
    case "$common_dir" in
        ""|/*) ;;
        *) common_dir="$target_dir/$common_dir" ;;
    esac
fi
if [ -n "$common_dir" ]; then
    main_root=$(cd "$common_dir/.." 2>/dev/null && pwd)
fi

# --- Which repos are protected -----------------------------------------------

repos_config=""
for candidate in \
    "$HOME/.claude/protected-repos" \
    "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/protected-repos"
do
    if [ -f "$candidate" ]; then
        repos_config="$candidate"
        break
    fi
done

rules=()
if [ -n "$PROTECTED_REPOS" ]; then
    while IFS= read -r line; do
        rules+=("$line")
    done <<< "${PROTECTED_REPOS//;/$'\n'}"
elif [ -n "$repos_config" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        rules+=("$line")
    done < "$repos_config"
fi

# Opt-out model: protected unless a rule says otherwise.
repo_protected=1
rule_branches=""
default_branches=""

# True if $2 (a rule pattern) matches $1 (a repo path).
rule_matches() {
    local path="$1" rule="$2" subject="$1"

    # A rule with no slash matches the repo's directory name anywhere on disk
    case "$rule" in */*) ;; *) subject="${path##*/}" ;; esac

    # Unquoted $rule so it globs; `*` spans `/`, and a rule naming a
    # directory also covers every repo beneath it.
    [[ "$subject" == $rule || "$subject" == $rule/* ]]
}

# Applies every rule in order; the LAST match wins, so a broad `!/*` can be
# followed by narrow rules that re-protect individual repos.
#
# Each rule is tested against BOTH the checkout path and the repo it was created
# from -- identical outside a linked worktree. So a rule naming a repo covers its
# worktrees wherever they live, and a rule naming a worktree path can still
# override that by coming later in the file. Testing both in one pass (rather
# than falling back to the origin repo only when nothing matched) is what keeps a
# catch-all `!/*` from swallowing worktrees before their repo's rule is seen.
apply_rules() {
    local rule negate branches matched
    for rule in "${rules[@]}"; do
        rule=$(trim "${rule%%#*}")
        [ -z "$rule" ] && continue

        # `default: main,master` sets the fallback branch set for every repo
        case "$rule" in
            default:*|defaults:*)
                default_branches=$(trim "${rule#*:}")
                continue
                ;;
        esac

        negate=0
        case "$rule" in '!'*) negate=1; rule=$(trim "${rule#\!}") ;; esac

        branches=""
        case "$rule" in
            *:*) branches=$(trim "${rule#*:}"); rule=$(trim "${rule%%:*}") ;;
        esac

        rule="${rule/#\~/$HOME}"
        [ "$rule" != "/" ] && rule="${rule%/}"
        [ -z "$rule" ] && continue

        matched=0
        rule_matches "$repo_root" "$rule" && matched=1
        if [ "$matched" -eq 0 ] && [ -n "$main_root" ] && [ "$main_root" != "$repo_root" ]; then
            rule_matches "$main_root" "$rule" && matched=1
        fi

        if [ "$matched" -eq 1 ]; then
            if [ "$negate" -eq 1 ]; then
                repo_protected=0
                rule_branches=""
            else
                repo_protected=1
                rule_branches="$branches"
            fi
        fi
    done
}

if [ ${#rules[@]} -gt 0 ]; then
    apply_rules
fi

if [ "$repo_protected" -eq 0 ]; then
    exit 0
fi

# --- Which branches are protected in it --------------------------------------

branch_config=""
if [ -f "$repo_root/.protected-branches" ]; then
    branch_config="$repo_root/.protected-branches"
elif [ -n "$main_root" ] && [ -f "$main_root/.protected-branches" ]; then
    branch_config="$main_root/.protected-branches"
fi

protected_branches=()
if [ -n "$PROTECTED_BRANCHES" ]; then
    IFS=':' read -ra protected_branches <<< "$PROTECTED_BRANCHES"
elif [ -n "$rule_branches" ]; then
    IFS=',' read -ra protected_branches <<< "$rule_branches"
elif [ -n "$branch_config" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        line=$(trim "${line%%#*}")
        [ -n "$line" ] && protected_branches+=("$line")
    done < "$branch_config"
elif [ -n "$default_branches" ]; then
    IFS=',' read -ra protected_branches <<< "$default_branches"
else
    protected_branches=("main" "master")
fi

# Drop blanks and stray whitespace left by the list splits
cleaned=()
for branch in "${protected_branches[@]}"; do
    branch=$(trim "$branch")
    [ -n "$branch" ] && cleaned+=("$branch")
done
protected_branches=("${cleaned[@]}")

if [ ${#protected_branches[@]} -eq 0 ]; then
    exit 0
fi

# `rev-parse --abbrev-ref HEAD` is wrong here: it returns the shortest
# *unambiguous* name, so a repo carrying both a `staging` branch and a `staging`
# tag reports `heads/staging` and never matches a protected name. symbolic-ref
# gives the exact ref, and fails on a detached HEAD -- where there is no branch
# to protect.
current_branch=$(git -C "$repo_root" symbolic-ref --quiet HEAD 2>/dev/null)
current_branch="${current_branch#refs/heads/}"

if [ -z "$current_branch" ]; then
    exit 0
fi

for branch in "${protected_branches[@]}"; do
    if [ "$current_branch" = "$branch" ]; then
        jq -n --arg reason "git ${git_subcmd} is not allowed on protected branch '${branch}' in ${repo_root}. Only fetch/pull/worktree and read-only inspection commands are permitted. Switch to a feature branch or create a worktree first. To stop protecting this repo, add '!${repo_root}' to ~/.claude/protected-repos." \
            '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
        exit 0
    fi
done

exit 0
