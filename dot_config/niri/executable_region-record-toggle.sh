#!/bin/sh

set -eu

runtime="${XDG_RUNTIME_DIR:-/tmp}"
pid_file="$runtime/niri-region-record.pid"
path_file="$runtime/niri-region-record.path"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "niri" "Region Recorder" "$1"
    fi
}

copy_recording() {
    file="$1"
    uri="file://$file"
    apng_file="${file%.mp4}.apng.png"
    gif_file="${file%.mp4}.gif"

    if [ ! -s "$file" ]; then
        notify "Recording stopped, but output file is empty."
        return 1
    fi

    if ! command -v wl-copy >/dev/null 2>&1; then
        notify "Recording saved to $file (wl-copy not found)."
        return 1
    fi

    # Discord on Linux accepts image/png pastes more reliably than file/video clipboard payloads.
    # Generate APNG and copy it as image/png so Ctrl+V works in Discord while keeping animation.
    if command -v ffmpeg >/dev/null 2>&1; then
        if ffmpeg -v error -y -i "$file" -vf "fps=10,scale='min(960,iw)':-1:flags=lanczos" -plays 0 -f apng "$apng_file"; then
            if [ -s "$apng_file" ] && wl-copy --type image/png < "$apng_file"; then
                notify "Recording stopped; copied APNG to clipboard. MP4 saved in Snippets."
                return 0
            fi
        fi

        if ffmpeg -v error -y -i "$file" -vf "fps=12,scale='min(960,iw)':-1:flags=lanczos" -loop 0 "$gif_file"; then
            if [ -s "$gif_file" ] && wl-copy --type image/gif < "$gif_file"; then
                notify "Recording stopped; copied GIF to clipboard. MP4 saved in Snippets."
                return 0
            fi
        fi
    fi

    # Prefer file-copy clipboard formats for better app compatibility on paste.
    if printf 'copy\n%s\n' "$uri" | wl-copy --type x-special/gnome-copied-files; then
        notify "Recording stopped; copied file to clipboard."
        return 0
    fi

    if printf '%s\n' "$uri" | wl-copy --type text/uri-list; then
        notify "Recording stopped; copied file path to clipboard."
        return 0
    fi

    if wl-copy --type video/mp4 < "$file"; then
        notify "Recording stopped; copied video bytes to clipboard."
        return 0
    fi

    notify "Recording saved to $file; clipboard copy failed."
    return 1
}

if [ -s "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
    pid="$(cat "$pid_file")"
    kill -INT "$pid" 2>/dev/null || true
    notify "Stopping recording..."
    exit 0
fi

if ! command -v slurp >/dev/null 2>&1 || ! command -v wf-recorder >/dev/null 2>&1; then
    notify "Missing dependency: slurp or wf-recorder."
    exit 1
fi

if [ -s "$pid_file" ]; then
    rm -f "$pid_file" "$path_file"
fi

dir="$HOME/Videos/Recordings/Snippets"
host="${HOSTNAME:-$(hostname)}"
file="$dir/$USER@$host-$(date +%Y-%m-%d_%H:%M:%S)-region.mp4"
mkdir -p "$dir"

geom="$(slurp)" || exit 0
[ -n "$geom" ] || exit 0

wf-recorder -g "$geom" -f "$file" >/dev/null 2>&1 &
pid=$!

sleep 0.2
if kill -0 "$pid" 2>/dev/null; then
    printf '%s' "$pid" > "$pid_file"
    printf '%s' "$file" > "$path_file"
    notify "Recording started."
else
    rm -f "$pid_file" "$path_file"
    notify "Failed to start recording."
    exit 1
fi

wait "$pid" || true

rm -f "$pid_file" "$path_file"
copy_recording "$file" || true
