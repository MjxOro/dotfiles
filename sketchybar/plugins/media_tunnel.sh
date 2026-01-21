#!/usr/bin/env bash

SCROLL_FILE="/tmp/sketchybar_media_scroll"
DISPLAY_CHARS=28
SCROLL_STEP=2

get_media() {
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
        echo "$YOUTUBE" | sed 's/ - YouTube$//' | sed 's/^([0-9]*) //'
        return
    fi

    SPOTIFY=$(osascript -e 'tell application "System Events" to (name of processes) contains "Spotify"' 2>/dev/null)
    if [ "$SPOTIFY" = "true" ]; then
        PLAYING=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)
        if [ "$PLAYING" = "playing" ]; then
            TRACK=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
            ARTIST=$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)
            echo "$ARTIST - $TRACK"
            return
        fi
    fi

    MUSIC=$(osascript -e 'tell application "System Events" to (name of processes) contains "Music"' 2>/dev/null)
    if [ "$MUSIC" = "true" ]; then
        PLAYING=$(osascript -e 'tell application "Music" to player state as string' 2>/dev/null)
        if [ "$PLAYING" = "playing" ]; then
            TRACK=$(osascript -e 'tell application "Music" to name of current track' 2>/dev/null)
            ARTIST=$(osascript -e 'tell application "Music" to artist of current track' 2>/dev/null)
            echo "$ARTIST - $TRACK"
            return
        fi
    fi
}

TEXT=$(get_media)

if [ -z "$TEXT" ]; then
    sketchybar --set media_left drawing=off --set media_right drawing=off
    rm -f "$SCROLL_FILE"
    exit 0
fi

PADDED="  $TEXT          $TEXT          "
PADDED_LEN=${#PADDED}
HALF_LEN=$(( PADDED_LEN / 2 ))

POS=0
if [ -f "$SCROLL_FILE" ]; then
    POS=$(cat "$SCROLL_FILE")
fi

DISPLAY=$(echo "$PADDED" | cut -c$((POS + 1))-$((POS + DISPLAY_CHARS)))

sketchybar --set media_left label="$DISPLAY" drawing=on \
           --set media_right label="$DISPLAY" drawing=on

NEXT_POS=$(( (POS + SCROLL_STEP) % HALF_LEN ))
echo "$NEXT_POS" > "$SCROLL_FILE"
