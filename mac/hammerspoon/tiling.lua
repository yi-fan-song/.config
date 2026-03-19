-- Tiling window management
-- Modifier keys used for all bindings
local mash      = {"ctrl", "alt"}
local mash_move = {"ctrl", "alt", "shift"}

-- Helper: move/resize window to a unit rect
local function tile(unitRect)
    local win = hs.window.focusedWindow()
    if win then
        win:moveToUnit(unitRect)
    end
end

-- Helper: move window to a specific screen
local function moveToScreen(dir)
    local win = hs.window.focusedWindow()
    if not win then return end
    local screen = win:screen()
    local target = dir == "next" and screen:next() or screen:previous()
    if target then
        win:moveToScreen(target, true, true)
    end
end

-- ── Half-screen ──────────────────────────────────────────────────────────────
hs.hotkey.bind(mash, "left",  function() tile({0,   0, 0.5, 1}) end)   -- left half
hs.hotkey.bind(mash, "right", function() tile({0.5, 0, 0.5, 1}) end)   -- right half
hs.hotkey.bind(mash, "up",    function() tile({0,   0, 1,   0.5}) end) -- top half
hs.hotkey.bind(mash, "down",  function() tile({0,   0.5, 1, 0.5}) end) -- bottom half

-- ── Thirds (horizontal) ──────────────────────────────────────────────────────
hs.hotkey.bind(mash, "u", function() tile({0,           0, 1/3, 1}) end) -- left third
hs.hotkey.bind(mash, "i", function() tile({1/3,         0, 1/3, 1}) end) -- center third
hs.hotkey.bind(mash, "o", function() tile({2/3,         0, 1/3, 1}) end) -- right third
hs.hotkey.bind(mash, "y", function() tile({0,           0, 2/3, 1}) end) -- left two-thirds
hs.hotkey.bind(mash, "p", function() tile({1/3,         0, 2/3, 1}) end) -- right two-thirds

-- ── Corners ───────────────────────────────────────────────────────────────────
hs.hotkey.bind(mash, "q", function() tile({0,   0,   0.5, 0.5}) end) -- top-left
hs.hotkey.bind(mash, "e", function() tile({0.5, 0,   0.5, 0.5}) end) -- top-right
hs.hotkey.bind(mash, "z", function() tile({0,   0.5, 0.5, 0.5}) end) -- bottom-left
hs.hotkey.bind(mash, "c", function() tile({0.5, 0.5, 0.5, 0.5}) end) -- bottom-right

-- ── Center / maximize ─────────────────────────────────────────────────────────
hs.hotkey.bind(mash, "f", function() tile({0, 0, 1, 1}) end)           -- maximize
hs.hotkey.bind(mash, "m", function() tile({0.1, 0.1, 0.8, 0.8}) end)  -- centered large

-- ── Multi-monitor ─────────────────────────────────────────────────────────────
hs.hotkey.bind(mash_move, "right", function() moveToScreen("next") end)
hs.hotkey.bind(mash_move, "left",  function() moveToScreen("prev") end)

-- ── Reload config ─────────────────────────────────────────────────────────────
hs.hotkey.bind(mash, "r", function()
    hs.reload()
end)

hs.alert.show("Hammerspoon config loaded")
