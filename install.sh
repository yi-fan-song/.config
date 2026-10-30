#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Packages ─────────────────────────────────────────────────────────────────

PACMAN_PACKAGES=(
    # Hyprland
    hyprland
    kitty
    wofi
    waybar
    hyprpaper
    brightnessctl
    playerctl
    pipewire
    wireplumber

    # hyprpm build dependencies
    cmake
    cpio
    pkg-config
    git
    gcc
    base-devel

    # herdr (plugins are compiled from source, so rust is required)
    herdr
    rust

    # claude/link.sh and its hooks
    jq

    # Kills the biggest process under memory pressure, before the machine
    # thrashes itself into an unrecoverable freeze.
    earlyoom
)

echo "Installing pacman packages..."
sudo pacman -S --needed "${PACMAN_PACKAGES[@]}"

# ── System services ──────────────────────────────────────────────────────────
# earlyoom must be enabled, not just installed -- the package ships the unit
# disabled. Tune thresholds in /etc/earlyoom.conf (defaults: act at 10% free).

echo "Enabling earlyoom..."
sudo systemctl enable --now earlyoom.service

# ── Hyprland plugins ─────────────────────────────────────────────────────────

echo "Installing Hyprland plugins via hyprpm..."
hyprpm update
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm enable hyprbars

# ── Symlinks ─────────────────────────────────────────────────────────────────

symlink() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    echo "  $dst -> $src"
}

echo "Creating symlinks..."
symlink "$REPO_DIR/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
symlink "$REPO_DIR/hypr/scripts/keybinds.sh" "$HOME/.config/hypr/scripts/keybinds.sh"

# ── Claude Code ──────────────────────────────────────────────────────────────
# Links statusline + hooks into ~/.claude and merges the settings patch.

echo "Installing Claude Code config..."
"$REPO_DIR/claude/link.sh"

# ── herdr ────────────────────────────────────────────────────────────────────
# Copies config.toml (not a symlink — see herdr/link.sh) and builds plugins.

echo "Installing herdr config..."
"$REPO_DIR/herdr/link.sh"
