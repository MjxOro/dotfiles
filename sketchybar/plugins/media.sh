#!/usr/bin/env bash

GREEN=0xffa8ff60
RED=0xffff6c60
MAGENTA=0xffff73fd

YOUTUBE=$(osascript -e '
tell application "Google Chrome"
    if (count of windows) > 0 then
        set tabURL to URL of active tab of front window
        if tabURL contains "youtube.com/watch" or tabURL contains "music.youtube.com" then
            return title of active tab of front window
        end if
    end if
end tell
return ""
' 2>/dev/null)

if [ -n "$YOUTUBE" ] && [ "$YOUTUBE" != "" ]; then
    CLEAN=$(echo "$YOUTUBE" | sed 's/ - YouTube$//' | sed 's/^([0-9]*) //')
    LABEL="$CLEAN  ·  $CLEAN  ·  $CLEAN  ·  $CLEAN  ·  "
    sketchybar --set media icon="" icon.drawing=on icon.color=$RED icon.font="Maple Mono NF:Bold:18.0" label="$LABEL" drawing=on
    exit 0
fi

SPOTIFY=$(osascript -e 'tell application "System Events" to (name of processes) contains "Spotify"' 2>/dev/null)
if [ "$SPOTIFY" = "true" ]; then
    PLAYING=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)
    if [ "$PLAYING" = "playing" ]; then
        TRACK=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
        ARTIST=$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)
        LABEL="$ARTIST - $TRACK  ·  $ARTIST - $TRACK  ·  $ARTIST - $TRACK  ·  "
        sketchybar --set media icon="" icon.drawing=on icon.color=$GREEN icon.font="Maple Mono NF:Bold:18.0" label="$LABEL" drawing=on
        exit 0
    fi
fi

MUSIC=$(osascript -e 'tell application "System Events" to (name of processes) contains "Music"' 2>/dev/null)
if [ "$MUSIC" = "true" ]; then
    PLAYING=$(osascript -e 'tell application "Music" to player state as string' 2>/dev/null)
    if [ "$PLAYING" = "playing" ]; then
        TRACK=$(osascript -e 'tell application "Music" to name of current track' 2>/dev/null)
        ARTIST=$(osascript -e 'tell application "Music" to artist of current track' 2>/dev/null)
        LABEL="$ARTIST - $TRACK  ·  $ARTIST - $TRACK  ·  $ARTIST - $TRACK  ·  "
        sketchybar --set media icon="" icon.drawing=on icon.color=$MAGENTA icon.font="Maple Mono NF:Bold:18.0" label="$LABEL" drawing=on
        exit 0
    fi
fi

sketchybar --set media drawing=off
