-- Application launchers
-- Sway binds this to `$mod+Return`. cmd+Return is an app-level shortcut on
-- macOS, so this uses ctrl+alt — the same `mash` modifier as tiling.lua.
local launch = {"ctrl", "alt"}

-- ── Terminal ──────────────────────────────────────────────────────────────────
-- Focus the running kitty rather than spawning one, so there is only ever a
-- single Dock icon. New terminals come from herdr's own `prefix+c`.
hs.hotkey.bind(launch, "return", function()
    hs.application.launchOrFocus("kitty")
end)
