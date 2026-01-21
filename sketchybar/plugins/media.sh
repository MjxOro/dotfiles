#!/usr/bin/env bash

# Check Music.app
MUSIC_STATE=$(osascript -e 'tell application "Music" to player state as string' 2>/dev/null)
if [ "$MUSIC_STATE" = "playing" ]; then
  TRACK=$(osascript -e 'tell application "Music" to name of current track' 2>/dev/null)
  if [ -n "$TRACK" ]; then
    # Truncate to 30 characters
    if [ ${#TRACK} -gt 30 ]; then
      TRACK="${TRACK:0:27}..."
    fi
    sketchybar --set "$NAME" label="$TRACK"
    exit 0
  fi
fi

# Check Spotify
SPOTIFY_STATE=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)
if [ "$SPOTIFY_STATE" = "playing" ]; then
  TRACK=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
  if [ -n "$TRACK" ]; then
    # Truncate to 30 characters
    if [ ${#TRACK} -gt 30 ]; then
      TRACK="${TRACK:0:27}..."
    fi
    sketchybar --set "$NAME" label="$TRACK"
    exit 0
  fi
fi

# Nothing playing
sketchybar --set "$NAME" label="♫"
