#!/usr/bin/env python3

import random
import subprocess
from pathlib import Path

wallpaper_dir = "~/configs/wallpapers"
wallpaper_symlink = "~/configs/wallpaper"

def get_cmd(s):
    return  f"swaymsg output '*' bg {s} fill"

def shuffle_background():
    """Pick a random image from wallpaper_dir and set it as background."""
    # Expand home directory
    wall_path = Path(wallpaper_dir).expanduser()
    symlink_path = Path(wallpaper_symlink).expanduser()

    if not wall_path.exists():
        print(f"Error: wallpaper directory does not exist: {wall_path}")
        return False

    # Find all image files (common formats)
    image_extensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif'}
    images = [f for f in wall_path.iterdir()
              if f.is_file() and f.suffix.lower() in image_extensions]

    if not images:
        print(f"Error: no image files found in {wall_path}")
        return False

    # Pick a random image
    chosen = random.choice(images)
    print(f"Selected wallpaper: {chosen}")

    # Create or update symlink to the chosen wallpaper
    try:
        if symlink_path.exists() or symlink_path.is_symlink():
            symlink_path.unlink()
        symlink_path.symlink_to(chosen)
        print(f"Created symlink: {symlink_path} -> {chosen}")
    except OSError as e:
        print(f"Warning: could not create symlink: {e}")

    # Run the command to set the background
    cmd = get_cmd(chosen)
    try:
        subprocess.run(cmd, shell=True, check=True)
        print(f"Successfully set wallpaper to {chosen.name}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error setting wallpaper: {e}")
        return False


if (__name__ == "__main__"):
    shuffle_background()

