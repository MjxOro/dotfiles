#!/usr/bin/env bash

# Get CPU usage from top
CPU_INFO=$(top -l 1 | grep "CPU usage")

# Extract user and system percentages
USER_CPU=$(echo "$CPU_INFO" | awk '{print $3}' | sed 's/%//')
SYS_CPU=$(echo "$CPU_INFO" | awk '{print $5}' | sed 's/%//')

# Calculate total CPU usage
TOTAL_CPU=$(echo "$USER_CPU + $SYS_CPU" | bc | awk '{printf "%.0f", $0}')

sketchybar --set "$NAME" label="${TOTAL_CPU}%"
