#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zed/themes"

mkdir -p "$TARGET_DIR"

src="$SCRIPT_DIR/everforest-dark-hard.json"
dst="$TARGET_DIR/everforest-dark-hard.json"

if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "SKIP everforest-dark-hard.json (real file exists at $dst)"
    exit 0
fi

ln -sf "$src" "$dst"
echo "LINK everforest-dark-hard.json -> $dst"
