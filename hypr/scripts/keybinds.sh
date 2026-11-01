#!/usr/bin/env bash
# Keybind cheatsheet overlay. Run bare to toggle the floating window; the
# window itself runs `keybinds.sh --render`. Binds come from `hyprctl binds`,
# so the sheet always matches the loaded config.
set -euo pipefail

CLASS=hypr-keybinds

render() {
    hyprctl binds -j | jq -r '
        def modnames($m):
            [ [64,"Super"], [4,"Ctrl"], [8,"Alt"], [1,"Shift"] ]
            | map(select(($m / .[0] | floor) % 2 == 1) | .[1]);
        def keyname:
            if   . == "mouse:272"  then "LMB drag"
            elif . == "mouse:273"  then "RMB drag"
            elif . == "mouse_down" then "Scroll ↓"
            elif . == "mouse_up"   then "Scroll ↑"
            elif . == "left"  then "←" elif . == "right" then "→"
            elif . == "up"    then "↑" elif . == "down"  then "↓"
            elif . == "slash" then "/"
            else sub("^XF86"; "") end;
        def action:
            if .has_description then .description
            elif .dispatcher == "exec" then
                (if   (.arg | test("hyprshutdown"))            then "exit / shutdown"
                 elif (.arg | test("set-volume.*%\\+"))       then "volume up"
                 elif (.arg | test("set-volume.*%-"))         then "volume down"
                 elif (.arg | test("set-mute.*SINK"))         then "mute"
                 elif (.arg | test("set-mute.*SOURCE"))       then "mic mute"
                 elif (.arg | test("brightnessctl.*\\+"))     then "brightness up"
                 elif (.arg | test("brightnessctl.*-$"))      then "brightness down"
                 elif (.arg | test("^playerctl "))            then "media: " + (.arg | sub("^playerctl "; ""))
                 else .arg | if length > 44 then .[:43] + "…" else . end end)
            elif .dispatcher == "killactive"             then "close window"
            elif .dispatcher == "togglefloating"         then "toggle floating"
            elif .dispatcher == "pseudo"                 then "pseudo-tile"
            elif .dispatcher == "layoutmsg"              then "layout: " + .arg
            elif .dispatcher == "movefocus"              then "move focus"
            elif .dispatcher == "workspace"              then "workspace " + .arg
            elif .dispatcher == "movetoworkspace"        then "move window to workspace " + .arg
            elif .dispatcher == "togglespecialworkspace" then "toggle scratchpad " + .arg
            elif .dispatcher == "mouse"                  then (.arg | sub("window$"; " window"))
            else .dispatcher + " " + .arg end;

        # Collapse runs like Super+1..0 → workspace 1..10 and the four
        # movefocus arrows into one row each.
        [ .[] | select(.submap == "") ]
        | group_by([.modmask, .dispatcher, (.arg | test("^[0-9]+$"))])
        | map(
            if length > 2 and (.[0].dispatcher | IN("workspace","movetoworkspace"))
               and (.[0].arg | test("^[0-9]+$")) then
                { mods: modnames(.[0].modmask),
                  key: "1…0",
                  act: (.[0] | .arg = "1–10" | action) }
            elif length == 4 and .[0].dispatcher == "movefocus" then
                { mods: modnames(.[0].modmask), key: "←↑↓→", act: "move focus" }
            else .[] | { mods: modnames(.modmask), key: (.key | keyname), act: action } end)
        | flatten
        # Modifier binds first, bare media keys last.
        | sort_by(if (.mods | length) == 0 then 1 else 0 end)
        | .[]
        # Pad here, not in awk: jq counts characters, awk counts bytes.
        | ((.mods + [.key]) | join(" + ")) as $k
        | [ $k + (" " * ([26 - ($k | length), 1] | max)), .act ]
        | @tsv' |
    awk -F'\t' '
        BEGIN { printf "\n  \033[1mKeybinds\033[0m\n\n" }
        { printf "  \033[36m%s\033[0m %s\n", $1, $2 }
        END { printf "\n  \033[2mpress any key to close\033[0m\n" }'
}

if [[ "${1:-}" == "--render" ]]; then
    render
    read -rsn1
    exit 0
fi

# Toggle: close the overlay if it is already open.
addr=$(hyprctl clients -j | jq -r --arg c "$CLASS" '.[] | select(.class == $c) | .address' | head -1)
if [[ -n "$addr" ]]; then
    hyprctl dispatch closewindow "address:$addr" >/dev/null
    exit 0
fi

exec kitty --class "$CLASS" -o confirm_os_window_close=0 "$(readlink -f "$0")" --render
