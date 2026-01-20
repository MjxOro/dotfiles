#!/usr/bin/env bash

# Format: "Mon Jan 19  14:30"
CLOCK_LABEL="$(date '+%a %b %d  %H:%M')"

sketchybar --set "$NAME" label="$CLOCK_LABEL"
