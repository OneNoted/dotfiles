#!/bin/sh

set -eu

dir="$HOME/Pictures/Screenshots/Snippets"
host="${HOSTNAME:-$(hostname)}"
app="unknown"

if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    app="$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // "unknown"' 2>/dev/null || printf 'unknown')"
fi

app="$(printf '%s' "$app" | tr '/[:space:]' '__' | tr -cd '[:alnum:]_.-')"
[ -n "$app" ] || app="unknown"

if ! command -v hyprshot >/dev/null 2>&1; then
    printf '%s\n' 'hyprshot not found in PATH' >&2
    exit 1
fi

mkdir -p "$dir"
file="$USER@$host-$(date +%Y-%m-%d_%H:%M:%S)-$app.png"

exec hyprshot --freeze --output-folder "$dir" --filename "$file" --mode region
