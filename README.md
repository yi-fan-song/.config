# .config

Config files.

| | |
|---|---|
| [`claude/`](claude/README.md) | Claude Code: statusline, branch protection, worktree hooks |
| [`herdr/`](herdr/README.md) | [herdr](https://herdr.dev) terminal workspace manager + plugins |
| `kitty/` | Kitty terminal |
| `mac/hammerspoon/` | macOS window tiling |
| `sway/` | Sway WM, swaybar, keybinds |
| `systemd/` | Wallpaper timer unit |
| `wofi/` | Wofi launcher styling |
| `zed/` | Zed editor theme |

Most folders carry a `link.sh` that symlinks their files into place, skipping
any real file already at the destination:

```bash
./kitty/link.sh
```

`herdr/` is the exception — it copies rather than symlinks, because herdr
rewrites its own config. See [herdr/README.md](herdr/README.md#why-this-one-copies-instead-of-symlinking).

Agent instructions live in [AGENTS.md](AGENTS.md); `CLAUDE.md` is a symlink to it,
because Claude Code only discovers `CLAUDE.md`.

Colour palette: [colors.md](colors.md).
