#!/bin/sh

# Date and time
date_and_time=$(date +"%H:%M %Y-%m-%d")

#############
# Commands
#############

# Battery or charger
battery_charge=$(cat /sys/class/power_supply/BAT0/capacity)
battery_status=$(upower --show-info $(upower --enumerate | grep 'BAT') | grep "state" | awk '{print $2}')

# Audio and multimedia
audio_volume=$(pamixer --get-volume)
audio_is_muted=$(pamixer --get-mute)
media_artist=$(playerctl metadata artist)
media_song=$(playerctl metadata title)
player_status=$(playerctl status)

# Wifi SSID
wifi_ssid=$(nmcli connection show --active | grep wifi | awk '{print $1}')

# we'll cache ping using another script, remove for now
# ping=$(ping -c 1 www.google.com | tail -1| awk '{print $4}' | cut -d '/' -f 2 | cut -d '.' -f 1)

if [ $battery_status = "discharging" ];
then
    if [ $battery_charge -lt 20 ]
        then 
        battery_status_msg="🪫 $battery_charge%"
    else 
        battery_status_msg="🔋 $battery_charge%"
    fi
else
    battery_status_msg="🔌 $battery_charge%"
fi

if [ $wifi_ssid ]
then
    wifi_status=" 🛜 $wifi_ssid |"
else
    wifi_status=""
fi

if [ $player_status = "Playing" ]
then
    song_status='▶'
elif [ $player_status = "Paused" ]
then
    song_status='⏸'
else
    song_status='⏹'
fi

if [ $audio_is_muted = "true" ]
then
    audio_status='🔇'
else
    if [ "$audio_volume" -lt 15 ]
        then
        audio_status="🔈 $audio_volume%"
    elif [ "$audio_volume" -lt 35 ]
        then
        audio_status="🔉 $audio_volume%"
    else
        audio_status="🔊 $audio_volume%"
    fi
fi

echo "$audio_status |$wifi_status $date_and_time | $battery_status_msg"
