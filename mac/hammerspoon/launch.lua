-- Application launchers
-- Sway binds this to `$mod+Return`. cmd+Return is an app-level shortcut on
-- macOS, so this uses ctrl+alt — the same `mash` modifier as tiling.lua.
local launch = {"ctrl", "alt"}

-- ── Terminal ──────────────────────────────────────────────────────────────────
-- kitty binds cmd+n to new_os_window, so trigger that inside the running
-- instance: a real new window, still one process and one Dock icon. Launch
-- normally when kitty is not running yet.
hs.hotkey.bind(launch, "return", function()
    local kitty = hs.application.get("kitty")
    if kitty then
        kitty:activate()
        hs.eventtap.keyStroke({"cmd"}, "n", 0, kitty)
    else
        hs.application.launchOrFocus("kitty")
    end
end)
