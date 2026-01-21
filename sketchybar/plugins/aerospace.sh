#!/usr/bin/env bash

# Colors
ACCENT=0xff7dd3c0
ITEM_BG_COLOR=0xff2d2d3d
INACTIVE_COLOR=0xff494d64

# Get the focused workspace from aerospace
FOCUSED_WORKSPACE="$FOCUSED_WORKSPACE"

# Extract space number from item name (space.1 -> 1)
SPACE_ID="${NAME##*.}"

if [ "$FOCUSED_WORKSPACE" = "$SPACE_ID" ]; then
  # Focused workspace - mint background
  sketchybar --set "$NAME" \
                   background.color=$ACCENT \
                   icon.color=0xff000000
else
  # Inactive workspace - default background
  sketchybar --set "$NAME" \
                   background.color=$ITEM_BG_COLOR \
                   icon.color=$INACTIVE_COLOR
fi
