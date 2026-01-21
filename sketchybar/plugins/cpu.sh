#!/usr/bin/env bash
CPU=$(top -l 1 | grep -E "^CPU" | awk '{print int($3)}')
sketchybar --set cpu label="${CPU}%"
