#!/usr/bin/env bash

ACCENT=0xff7dd3c0
DIM=0xff4a5060

# Check if WiFi interface has an IP (most reliable on newer macOS)
WIFI_IP=$(ipconfig getifaddr en0 2>/dev/null)

if [ -z "$WIFI_IP" ]; then
    sketchybar --set wifi icon="󰤭" icon.color=$DIM label="Off"
else
    # Try to get SSID (may be redacted on macOS 15+)
    SSID=$(networksetup -getairportnetwork en0 2>/dev/null | sed 's/Current Wi-Fi Network: //')
    if [ "$SSID" = "You are not associated with an AirPort network." ] || [ -z "$SSID" ]; then
        SSID="Connected"
    fi
    sketchybar --set wifi icon="󰤨" icon.color=$ACCENT label="$SSID"
fi
