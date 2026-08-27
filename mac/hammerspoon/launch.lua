-- Application launchers
-- Sway binds this to `$mod+Return`. cmd+Return is an app-level shortcut on
-- macOS, so this uses ctrl+alt — the same `mash` modifier as tiling.lua.
local launch = {"ctrl", "alt"}

-- ── Terminal ──────────────────────────────────────────────────────────────────
-- `--single-instance` puts each new window in the running kitty, so repeated
-- presses share one process. Launched via `open` so launchd owns it rather
-- than Hammerspoon, and so the call returns instead of blocking.
hs.hotkey.bind(launch, "return", function()
    hs.execute("open -na kitty --args --single-instance")
end)
