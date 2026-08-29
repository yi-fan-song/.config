# AGENTS.md

Personal dotfiles/config repo. Config files for Claude Code, Kitty, Sway, herdr, Zed, Hammerspoon, etc.

`CLAUDE.md` is a symlink to this file — Claude Code only discovers `CLAUDE.md`/`CLAUDE.local.md`,
it does not read `AGENTS.md`. Edit this file; leave the symlink alone.

## Install convention

Each `link.sh` symlinks its own files into place and is safe to re-run. Run from anywhere —
they resolve their own directory: `./kitty/link.sh`.

| Script | Target | If a real file is already there |
|---|---|---|
| `claude/link.sh` | `~/.claude/` | SKIP that file, continue with the rest |
| `claude/link.sh --hooks DIR` | `DIR/.claude/` | SKIP that file, continue with the rest |
| `herdr/link.sh` | `$XDG_CONFIG_HOME/herdr` | **overwrites** (writes `.bak` first if it differs) |
| `kitty/link.sh` | `$XDG_CONFIG_HOME/kitty` | SKIP and exit |
| `zed/link.sh` | `$XDG_CONFIG_HOME/zed/themes` | SKIP and exit |
| `mac/hammerspoon/link.sh` | `~/.hammerspoon` | SKIP that file, continue with the rest |

`sway/`, `systemd/`, and `wofi/` have no `link.sh` — those files are placed by hand.

**herdr is the odd one out** — it *copies* instead of symlinking, because herdr and its plugins
rewrite `config.toml` via temp-file rename, which would replace a symlink with a real file and
silently strand the repo copy. `--diff` shows drift, `--save` copies the live config back into
the repo. Check `--diff` before re-running it bare, since bare mode overwrites the live config.

## Rules for editing

- Do not add comments to config files unless the file already has them or the user asks.
- Do not link/edit anything outside the tracked directories.
- `claude/link.sh` has two modes: bare (statusline + branch protection into `~/.claude/`) and
  `--hooks <workspace>` (worktree enforcement into `<workspace>/.claude/`). Don't confuse them.
- Both modes merge a `settings.json` patch with `jq -s '.[0] * .[1]'`. Objects merge, but **arrays
  are replaced wholesale** — re-running it discards any hand-added hook under an event the patch
  also defines (`PreToolUse`, `UserPromptSubmit`, `Stop`). Add such hooks to the repo patch, not
  to the live file.
- Claude Code branch protection rules live in `claude/protected-repos`, not per-workspace. Every
  repo is protected by default; `!` prefix exempts.
- That file is machine-specific and **gitignored**. `claude/link.sh` seeds it from the tracked
  `claude/protected-repos.example` on first run and leaves it alone thereafter. Edit the example
  only to change what a fresh machine starts with; edit the real file to change this machine.
