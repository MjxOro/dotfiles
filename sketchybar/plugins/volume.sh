#!/usr/bin/env bash

VOLUME=$(osascript -e 'output volume of (get volume settings)')
MUTED=$(osascript -e 'output muted of (get volume settings)')
ACCENT=0xff7dd3c0
DIM=0xff4a5060

if [ "$MUTED" = "true" ] || [ "$VOLUME" -eq 0 ]; then
    ICON="󰝟"
    COLOR=$DIM
elif [ "$VOLUME" -lt 33 ]; then
    ICON="󰕿"
    COLOR=$ACCENT
elif [ "$VOLUME" -lt 66 ]; then
    ICON="󰖀"
    COLOR=$ACCENT
else
    ICON="󰕾"
    COLOR=$ACCENT
fi

sketchybar --set volume icon="$ICON" icon.color=$COLOR label="${VOLUME}%"
