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

if [ -s "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
    pid="$(cat "$pid_file")"
    kill -INT "$pid"
    while kill -0 "$pid" 2>/dev/null; do
        sleep 0.1
    done

    file="$(cat "$path_file" 2>/dev/null || true)"
    if [ -n "$file" ] && [ -s "$file" ]; then
        if command -v wl-copy >/dev/null 2>&1; then
            wl-copy --type video/mp4 < "$file"
            notify "Recording stopped; copied to clipboard."
        else
            notify "Recording stopped; wl-copy not found."
        fi
    else
        notify "Recording stopped, but no output file was found."
    fi

    rm -f "$pid_file" "$path_file"
    exit 0
fi

if ! command -v slurp >/dev/null 2>&1 || ! command -v wf-recorder >/dev/null 2>&1; then
    notify "Missing dependency: slurp or wf-recorder."
    exit 1
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
