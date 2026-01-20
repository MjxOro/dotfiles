#!/usr/bin/env bash

# Get battery info
BATTERY_INFO="$(pmset -g batt)"

# Check if battery exists
if echo "$BATTERY_INFO" | grep -q "InternalBattery"; then
  # Extract percentage
  PERCENTAGE=$(echo "$BATTERY_INFO" | grep -Eo "\d+%" | cut -d% -f1)
  
  # Check if charging
  if echo "$BATTERY_INFO" | grep -q "charging"; then
    ICON="⚡"
  else
    ICON="🔋"
  fi
  
  sketchybar --set "$NAME" \
                   icon="$ICON" \
                   label="${PERCENTAGE}%" \
                   drawing=on
else
  # No battery (desktop Mac) - hide the item
  sketchybar --set "$NAME" drawing=off
fi
