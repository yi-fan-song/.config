# Claude Code

Config files for [Claude Code](https://claude.ai/code).

## Contents

```
claude/
├── statusline.sh          # Status line: name, cwd, model, worktree, context%, rate limits
├── settings.json          # Global settings patch (statusLine config)
├── link.sh                # Install script
├── hooks/
│   ├── enforce-worktree.sh  # PreToolUse hook: blocks edits to protected directories
│   └── settings.json        # Workspace settings patch (hooks config)
└── README.md
```

## Install

### Statusline (global)

```bash
./link.sh
```

Symlinks `statusline.sh` into `~/.claude/` and merges the statusLine config into `~/.claude/settings.json`.

### Worktree enforcement hooks (per workspace)

```bash
./link.sh --hooks /path/to/workspace
```

This will:

1. Symlink `enforce-worktree.sh` into `<workspace>/.claude/hooks/`
2. Merge the hooks config into `<workspace>/.claude/settings.json`
3. Create a `.enforce-worktree` config file in the workspace root (if missing)

Then edit `.enforce-worktree` to list the directories to protect:

```
# One absolute path per line. Lines starting with # are ignored.
/Users/me/repo/mobile
/Users/me/repo/web
```

When Claude tries to Edit or Write a file inside a protected directory, the hook denies it and tells Claude to use a worktree instead.

You can also set the `ENFORCE_WORKTREE_DIRS` env var as an alternative (colon-separated paths):

```bash
export ENFORCE_WORKTREE_DIRS="/Users/me/repo/mobile:/Users/me/repo/web"
```

Requires `jq`.

## Statusline customization

Edit `statusline.sh` to change what the status bar displays. The script receives JSON on stdin with:

| Field | Description |
|---|---|
| **Session** | |
| `session_id` | Unique session ID |
| `session_name` | Custom name (via `--name` or `/rename`, absent if unset) |
| `version` | Claude Code version |
| **Model** | |
| `model.id` | Model identifier (e.g. `claude-opus-4-6`) |
| `model.display_name` | Display name (e.g. `Opus`) |
| **Workspace** | |
| `cwd` / `workspace.current_dir` | Current working directory |
| `workspace.project_dir` | Directory where Claude Code was launched |
| `workspace.git_worktree` | Git worktree name (if in a worktree) |
| **Context** | |
| `context_window.used_percentage` | Context usage (0-100) |
| `context_window.remaining_percentage` | Context remaining (0-100) |
| `context_window.context_window_size` | Max context window in tokens |
| `context_window.current_usage.*` | Input/output/cache token counts |
| **Cost** | |
| `cost.total_cost_usd` | Session cost in USD |
| `cost.total_duration_ms` | Wall-clock time since session start |
| `cost.total_api_duration_ms` | Time waiting for API responses |
| `cost.total_lines_added` / `removed` | Lines of code changed |
| **Rate limits** | |
| `rate_limits.five_hour.used_percentage` | 5-hour rate limit usage (0-100) |
| `rate_limits.seven_day.used_percentage` | 7-day rate limit usage (0-100) |
| **Conditional** | |
| `worktree.branch` / `name` / `path` | Claude-managed worktree info |
| `vim.mode` | Vim mode (when enabled) |
| `agent.name` | Agent name (with `--agent` flag) |

ANSI color codes are supported.
