# herdr

Config for [herdr](https://herdr.dev) — a terminal workspace manager that keeps
coding-agent sessions running persistently in the background, so they survive a
closed laptop or a dropped connection.

## Contents

```
herdr/
├── config.toml   # herdr config: UI, theme, sidebar rows
├── plugins       # Plugins to install, one OWNER/REPO per line
├── link.sh       # Install / save / diff script
└── README.md
```

## Install herdr

herdr itself is not vendored here — install it from upstream first:

```bash
curl -fsSL https://herdr.dev/install.sh | sh
```

Windows uses `irm https://herdr.dev/install.ps1 | iex`; Homebrew, Nix, and
manual installs are covered in [the herdr docs](https://herdr.dev/docs).

Then verify and pull in this config:

```bash
herdr --version
./link.sh
```

## Install this config

```bash
./link.sh          # copy config.toml into ~/.config/herdr/ and install plugins
./link.sh --save   # copy the live config back into this repo
./link.sh --diff   # show drift between repo and live
```

`link.sh` backs up the live config to `config.toml.bak` before overwriting it if
the two differ, then reloads the running server via `herdr server reload-config`
so changes apply without restarting your session.

### Why this one copies instead of symlinking

Every other config in this repo is symlinked. herdr is the exception, because
herdr and its plugins **rewrite `config.toml` themselves** — theme switches,
`herdr config reset-keys`, and the space-usage plugin's `$usage` row all edit the
file — and each write is a temp-file rename. A rename replaces a symlink with a
real file, so the link is gone after the first write and the repo copy silently
stops tracking anything. Verified here: linking `config.toml` and then invoking
the plugin's `status-enable` left a plain 290-byte file where the symlink had
been.

So the flow is two-way on purpose. Change settings in herdr, then run
`./link.sh --save` to bring them back into the repo. `./link.sh --diff` tells you
whether you have anything to save.

## Plugins

Listed in `plugins`, one `OWNER/REPO` per line, installed by `./link.sh`.

**Plugins are compiled from source at install time**, so the machine hosting the
herdr server needs a Rust toolchain:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Without `cargo` on `PATH` the install fails with
`error: plugin build failed … failed to start: No such file or directory (os error 2)`.
For remote setups (`herdr --remote`), plugins run on the server box, so Rust is
only needed there. The first build takes a few minutes.

### PC RAM & CPU Usage Overlay

[`ezcorp-org/herdr-pc-ram-and-cpu-usage-overlay`](https://github.com/ezcorp-org/herdr-pc-ram-and-cpu-usage-overlay)
— live CPU and RAM per space, so you can see which workspace is eating the
machine when several agents are running. Both figures are a share of the whole
machine (0–100%), refreshed every 5s, grouped under each space's git branch.
Worktree workspaces fold into their parent space's total.

```
  ● config      main          cpu 0.0%   ram 504 MB (2%)  · 1 pane
  ○ repo        (no branch)   cpu 0.0%   ram 211 MB (1%)  · 2 panes
  ○ web         development   cpu 0.0%   ram   1 MB (0%)  · 1 pane
  ── total   cpu 0.0%   ram 716 MB (3%)   bat 100%=   disk 72% 130G
```

Installed as plugin id `ez-corp.space-usage`:

```bash
herdr plugin install ezcorp-org/herdr-pc-ram-and-cpu-usage-overlay
```

**It edits `config.toml`.** herdr only draws a `$usage` token if some row in its
own config references one, and no plugin API can contribute a row — so on first
run the plugin appends one to `[ui.sidebar.spaces]`, wrapped in a marker
comment. That block is in the tracked `config.toml` here, which is why a fresh
machine gets the overlay immediately rather than on second run. The plugin backs
the file up to `config.toml.space-usage.bak` before writing, and won't touch a
config that already references `$usage`.

Settings live in `~/.config/herdr/plugins/config/ez-corp.space-usage/config.toml`
— absent until you create it, at which point the defaults are:

| Key | Default | Notes |
|---|---|---|
| `mode` | `sidebar` | or `agents-panel` |
| `interval_seconds` | `5` | 1–28800 |
| `ram_display` | `percent` | or `gb`, `absolute` |
| `icons` | `auto` | or `text`, `unicode`, `nerdfont`, `emoji` — `auto` uses Nerd Font glyphs when one is detected |
| `battery` | `true` | hidden automatically on machines without one |
| `disk` | `true` | |
| `disks` | all | e.g. `"/, /home"` |
| `window_title_totals` | `true` | totals in the terminal window title |

That config directory is *not* tracked here — the defaults are what's in use.

Useful commands:

```bash
herdr plugin list                                          # what's installed
herdr plugin action invoke report --plugin ez-corp.space-usage   # one-shot report
herdr plugin action invoke status-toggle --plugin ez-corp.space-usage
herdr plugin pane open dashboard --plugin ez-corp.space-usage    # live pane
herdr plugin log                                           # debug a plugin run
```

`status-disable` removes the marked `$usage` block from `config.toml` and stops
the sidebar readout; `status-enable` puts it back.

## Notes

- Runtime state in `~/.config/herdr/` — `session.json`, `plugins.json`,
  `*.log`, `*.sock`, `.plugins.lock`, and the `plugins/` build tree — is
  machine-local and deliberately untracked. Only `config.toml` is.
- `herdr config check` validates `config.toml` and prints diagnostics.
- `herdr --default-config` prints the full annotated default config, which is
  the reference for anything not set here.
