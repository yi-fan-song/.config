-- Application launchers
-- Mirrors sway's `$mod+Return exec $term`; cmd stands in for Mod4 on macOS.
local launch = {"cmd"}

-- ── Terminal ──────────────────────────────────────────────────────────────────
-- `open -na` spawns a new instance every press, like sway's `exec $term`,
-- rather than focusing an existing window.
hs.hotkey.bind(launch, "return", function()
    hs.execute("open -na kitty")
end)
