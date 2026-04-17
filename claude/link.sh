#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo "Usage:"
    echo "  ./link.sh              Install statusline into ~/.claude/"
    echo "  ./link.sh --hooks DIR  Install worktree enforcement hooks into DIR/.claude/"
    exit 1
}

link_file() {
    local src="$1" dst="$2"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        echo "SKIP $(basename "$src") (real file exists at $dst)"
        return
    fi
    ln -sf "$src" "$dst"
    echo "LINK $(basename "$src") -> $dst"
}

merge_settings() {
    local target="$1" patch="$2"
    if [[ -f "$target" ]]; then
        tmp=$(mktemp)
        jq -s '.[0] * .[1]' "$target" "$patch" > "$tmp" && mv "$tmp" "$target"
        echo "MERGE $(basename "$patch") -> $target"
    else
        cp "$patch" "$target"
        echo "COPY $(basename "$patch") -> $target"
    fi
}

# --- Statusline (global) ---
install_statusline() {
    local target_dir="$HOME/.claude"
    mkdir -p "$target_dir"

    link_file "$SCRIPT_DIR/statusline.sh" "$target_dir/statusline.sh"
    merge_settings "$target_dir/settings.json" "$SCRIPT_DIR/settings.json"
}

# --- Hooks (per-workspace) ---
install_hooks() {
    local workspace="$1"
    local target_dir="$workspace/.claude"
    local hooks_dir="$target_dir/hooks"

    mkdir -p "$hooks_dir"

    link_file "$SCRIPT_DIR/hooks/enforce-worktree.sh" "$hooks_dir/enforce-worktree.sh"
    link_file "$SCRIPT_DIR/hooks/protect-branches.sh" "$hooks_dir/protect-branches.sh"
    merge_settings "$target_dir/settings.json" "$SCRIPT_DIR/hooks/settings.json"

    # Create default config if missing
    local config="$workspace/.enforce-worktree"
    if [[ ! -f "$config" ]]; then
        cat > "$config" <<'EOF'
# Directories protected from direct edits (one per line).
# Claude will be told to use a worktree instead.
# Lines starting with # are ignored.
EOF
        echo "CREATE $config (add protected paths here)"
    else
        echo "EXISTS $config"
    fi

    local branch_config="$workspace/.protected-branches"
    if [[ ! -f "$branch_config" ]]; then
        cat > "$branch_config" <<'EOF'
# Branches where git commands are restricted (one per line).
# Only fetch/pull/worktree and read-only inspection commands are allowed.
# Lines starting with # are ignored.
# If this file is empty/absent, defaults to: main, master
main
master
EOF
        echo "CREATE $branch_config (edit protected branches here)"
    else
        echo "EXISTS $branch_config"
    fi
}

# --- Main ---
if [[ "${1:-}" == "--hooks" ]]; then
    [[ -z "${2:-}" ]] && usage
    workspace="${2%/}"
    [[ ! -d "$workspace" ]] && echo "Error: $workspace is not a directory" && exit 1
    install_hooks "$workspace"
else
    [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage
    install_statusline
fi
