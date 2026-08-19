#!/usr/bin/env bash
set -euo pipefail

# Unlike the other configs in this repo, herdr's config.toml is COPIED, not
# symlinked. herdr and its plugins rewrite config.toml themselves (theme
# changes, `herdr config reset-keys`, the space-usage `$usage` row) and every
# write is a temp-file rename — which replaces a symlink with a real file and
# silently strands the repo copy. So: copy in, copy back.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/herdr"

src="$SCRIPT_DIR/config.toml"
dst="$TARGET_DIR/config.toml"
plugins_file="$SCRIPT_DIR/plugins"

usage() {
    echo "Usage:"
    echo "  ./link.sh            Install config.toml + plugins onto this machine"
    echo "  ./link.sh --save     Copy the live config.toml back into this repo"
    echo "  ./link.sh --diff     Show drift between repo and live config"
    exit 1
}

install_plugins() {
    [[ -f "$plugins_file" ]] || return 0
    command -v herdr >/dev/null 2>&1 || { echo "SKIP plugins (herdr not on PATH)"; return 0; }

    local installed
    installed="$(herdr plugin list 2>/dev/null || true)"

    while read -r repo; do
        [[ -z "$repo" || "$repo" == \#* ]] && continue
        if grep -qF "$repo" <<<"$installed"; then
            echo "HAVE  $repo"
            continue
        fi
        echo "BUILD $repo (cargo build --release, takes a few minutes)"
        herdr plugin install "$repo" -y
    done < "$plugins_file"
}

case "${1:-}" in
    -h|--help) usage ;;

    --diff)
        [[ -f "$dst" ]] || { echo "No live config at $dst"; exit 1; }
        if diff -u "$src" "$dst" --label "repo/config.toml" --label "live/config.toml"; then
            echo "IN SYNC repo and live config.toml match"
        fi
        ;;

    --save)
        [[ -f "$dst" ]] || { echo "No live config at $dst"; exit 1; }
        cp "$dst" "$src"
        echo "SAVE  $dst -> $src"
        ;;

    "")
        mkdir -p "$TARGET_DIR"
        if [[ -f "$dst" ]] && ! diff -q "$src" "$dst" >/dev/null; then
            cp "$dst" "$dst.bak"
            echo "BACKUP $dst -> $dst.bak"
        fi
        cp "$src" "$dst"
        echo "COPY  $src -> $dst"

        install_plugins

        if command -v herdr >/dev/null 2>&1; then
            herdr server reload-config >/dev/null 2>&1 \
                && echo "RELOAD running herdr server picked up the new config" || true
        fi
        ;;

    *) usage ;;
esac
