-- Application launchers
-- Mirrors sway's `$mod+Return exec $term`; cmd stands in for Mod4 on macOS.
local launch = {"cmd"}

-- ── Terminal ──────────────────────────────────────────────────────────────────
-- `--single-instance` puts each new window in the running kitty, so repeated
-- presses share one process. Launched via `open` so launchd owns it rather
-- than Hammerspoon, and so the call returns instead of blocking.
hs.hotkey.bind(launch, "return", function()
    hs.execute("open -na kitty --args --single-instance")
end)
