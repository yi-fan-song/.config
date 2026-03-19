#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.hammerspoon"

mkdir -p "$TARGET_DIR"

for src in "$SCRIPT_DIR"/*.lua; do
    name="$(basename "$src")"
    dst="$TARGET_DIR/$name"

    if [[ -e "$dst" && ! -L "$dst" ]]; then
        echo "SKIP $name (real file exists at $dst)"
        continue
    fi

    ln -sf "$src" "$dst"
    echo "LINK $name -> $dst"
done
