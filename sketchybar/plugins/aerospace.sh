#!/usr/bin/env bash

ACCENT=0xff7dd3c0
TEXT_BRIGHT=0xffeeeeee
DIM=0xff6c6c6c
SURFACE=0xcc1a1a1a
TRANSPARENT=0x00000000

if [ "$SENDER" = "aerospace_workspace_change" ]; then
    FOCUSED=$(aerospace list-workspaces --focused)
    
    for sid in 1 2 3 4 5; do
        if [ "$sid" = "$FOCUSED" ]; then
            sketchybar --set space.$sid \
                icon.color=$ACCENT \
                background.color=$SURFACE \
                background.border_color=$ACCENT \
                background.border_width=2
        else
            WINDOWS=$(aerospace list-windows --workspace $sid 2>/dev/null | wc -l | tr -d ' ')
            if [ "$WINDOWS" -gt 0 ]; then
                sketchybar --set space.$sid \
                    icon.color=$TEXT_BRIGHT \
                    background.color=$TRANSPARENT \
                    background.border_width=0
            else
                sketchybar --set space.$sid \
                    icon.color=$DIM \
                    background.color=$TRANSPARENT \
                    background.border_width=0
            fi
        fi
    done
fi
