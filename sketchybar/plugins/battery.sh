#!/usr/bin/env bash

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | head -1 | tr -d '%')
CHARGING=$(pmset -g batt | grep -c "AC Power")

GREEN=0xffa8ff60
YELLOW=0xffffffb6
RED=0xffff6c60
ACCENT=0xff7dd3c0

if [ -z "$PERCENTAGE" ]; then
    sketchybar --set battery drawing=off
    exit 0
fi

if [ "$CHARGING" -gt 0 ]; then
    ICON="󰂄"
    COLOR=$ACCENT
elif [ "$PERCENTAGE" -gt 80 ]; then
    ICON="󰁹"
    COLOR=$GREEN
elif [ "$PERCENTAGE" -gt 60 ]; then
    ICON="󰂀"
    COLOR=$GREEN
elif [ "$PERCENTAGE" -gt 40 ]; then
    ICON="󰁾"
    COLOR=$YELLOW
elif [ "$PERCENTAGE" -gt 20 ]; then
    ICON="󰁻"
    COLOR=$YELLOW
else
    ICON="󰁺"
    COLOR=$RED
fi

sketchybar --set battery icon="$ICON" icon.color=$COLOR label="${PERCENTAGE}%"
