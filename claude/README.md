# Claude Code

Config files for [Claude Code](https://claude.ai/code).

## Contents

```
claude/
├── statusline.sh            # Status line: name, cwd, model, worktree, context%, rate limits
├── settings.json            # Global settings patch (statusLine + branch protection)
├── protected-repos          # Which repos branch protection guards (global config)
├── link.sh                  # Install script
├── hooks/
│   ├── enforce-worktree.sh  # PreToolUse hook: blocks edits to protected directories
│   ├── protect-branches.sh  # PreToolUse hook: blocks git commands on protected branches
│   └── settings.json        # Workspace settings patch (worktree hook config)
└── README.md
```

## Install

### Statusline + branch protection (global)

```bash
./link.sh
```

Symlinks `statusline.sh` and `protected-repos` into `~/.claude/`, and merges the statusLine config plus the branch-protection hook registration into `~/.claude/settings.json`.

### Worktree enforcement hooks (per workspace)

```bash
./link.sh --hooks /path/to/workspace
```

This will:

1. Symlink `enforce-worktree.sh` into `<workspace>/.claude/hooks/`
2. Merge the hooks config into `<workspace>/.claude/settings.json`
3. Create a `.enforce-worktree` config file in the workspace root (if missing)

Branch protection used to be installed here too. It is global now — if a workspace still has a `PreToolUse`/`Bash` entry for `protect-branches.sh` in its `.claude/settings.json`, remove it so the hook doesn't fire twice, and delete the workspace's `.protected-branches` (only a *repo root* copy is read now).

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

### Branch protection (global)

Installed by `./link.sh`. Registered once in `~/.claude/settings.json`, so it applies from any cwd rather than only in workspaces where hooks were installed.

On protected branches, Claude is blocked from running git commands that could mutate state. Allowed: `fetch`, `pull`, `worktree`, and read-only inspection (`status`, `diff`, `log`, `show`, `blame`, `branch`, `tag`, `remote`, `config`, `rev-parse`, `describe`, `reflog`, `grep`, `ls-files`/`ls-tree`/`ls-remote`, `cat-file`, `shortlog`, `whatchanged`, `name-rev`, `for-each-ref`, `help`, `version`). This prevents accidental commits, pushes, or resets on branches like `main`.

The hook resolves which repo a command actually targets, so `cd sub && git ...` and `git -C sub ...` are checked against that repo's branch, not the session's cwd.

#### Which repos

**Every git repo is protected by default** (on `main` and `master`). Edit `protected-repos` to adjust:

```
default: main,master                          # fallback branch set

~/repo/web:main,uat,development,production    # different branch set
!~/scratch                                    # not protected at all
!sandbox                                      # no slash => matches repo dir name
```

The **last matching rule wins**, so a broad rule can be followed by a narrow override. That is how you invert the default and protect only specific repos:

```
!/*                  # protect nothing...
~/repo/web           # ...except these two
~/repo/mobile
```

Patterns expand `~`, and `*` globs across `/` — so `~/x/*` covers nested repos, and a pattern naming a directory also covers every repo beneath it (`!~/scratch` is the same as `!~/scratch/*`).

#### Worktrees

Every rule is tested against both the checkout path **and** the repo it was created from, so **a rule naming a repo covers all of its worktrees** regardless of where they live — `~/repo/web` covers `~/repo/web-branches/*` and `~/repo/web/.claude/worktrees/*` alike. This matters: worktrees like `web-branches/uat` sit permanently on a protected branch.

Both paths are checked in a single pass rather than falling back to the origin repo only when nothing matched. Otherwise a catch-all `!/*` would match a worktree's own path and short-circuit its repo's rule, leaving every worktree unprotected.

To treat one worktree differently, name its path in a rule placed *after* the repo's rule:

```
~/repo/web:main,uat
!~/repo/web-branches/uat    # ...but let me work in this one
```

#### Which branches

First hit wins:

1. `PROTECTED_BRANCHES` env var — colon-separated, e.g. `export PROTECTED_BRANCHES="main:master:production"`
2. the `:branches` override on the matching `protected-repos` rule
3. `<repo root>/.protected-branches` — one branch name per line
4. the `default:` line in `protected-repos`
5. `main`, `master`

The current branch is read with `git symbolic-ref HEAD`, not `rev-parse --abbrev-ref HEAD`. The latter returns the shortest *unambiguous* name, so a repo carrying both a `uat` branch and a `uat` tag (as `web` does) reports `heads/uat` and would never match a protected branch name. A detached HEAD has no branch and is never blocked.

`PROTECTED_REPOS` replaces the `protected-repos` file entirely; entries are separated by `;` or newlines:

```bash
export PROTECTED_REPOS="!~/tmp;~/repo/web:main,production"
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
