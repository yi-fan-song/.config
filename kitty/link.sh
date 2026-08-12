#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"

mkdir -p "$TARGET_DIR"

src="$SCRIPT_DIR/kitty.conf"
dst="$TARGET_DIR/kitty.conf"

if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "SKIP kitty.conf (real file exists at $dst)"
    exit 0
fi

ln -sf "$src" "$dst"
echo "LINK kitty.conf -> $dst"
