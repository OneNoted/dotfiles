#!/usr/bin/env sh

set -eu

state_dir="${XDG_RUNTIME_DIR:-/tmp}/niri-region-record"
pid_file="$state_dir/pid"
out_file="$state_dir/out"
tmp_file="$state_dir/tmp"
log_file="$state_dir/log"

mkdir -p "$state_dir"

finalize_recording() {
	out="$(cat "$out_file" 2>/dev/null || true)"
	tmp="$(cat "$tmp_file" 2>/dev/null || true)"

	if [ -z "$out" ] || [ -z "$tmp" ] || [ ! -s "$tmp" ]; then
		notify-send "Screen recording failed" "No recording data was captured."
		rm -f "$pid_file" "$out_file" "$tmp_file" "$log_file"
		exit 1
	fi

	if ! command -v ffmpeg >/dev/null 2>&1; then
		notify-send "Screen recording stopped" "ffmpeg missing; keeping raw file: $tmp"
		rm -f "$pid_file" "$out_file" "$tmp_file" "$log_file"
		exit 0
	fi

	if ffmpeg -v error -y -i "$tmp" -c copy -movflags +faststart "$out" >/dev/null 2>&1; then
		rm -f "$tmp" "$pid_file" "$out_file" "$tmp_file" "$log_file"
		notify-send "Screen recording stopped" "$out"
		exit 0
	fi

	# Fallback to re-encode if stream copy cannot produce a playable MP4.
	if ffmpeg -v error -y -i "$tmp" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -movflags +faststart "$out" >/dev/null 2>&1; then
		rm -f "$tmp" "$pid_file" "$out_file" "$tmp_file" "$log_file"
		notify-send "Screen recording stopped" "$out"
		exit 0
	fi

	notify-send "Screen recording failed" "Could not remux recording. See: $log_file"
	rm -f "$pid_file" "$out_file" "$tmp_file"
	exit 1
}

if [ -f "$pid_file" ]; then
	pid="$(cat "$pid_file" 2>/dev/null || true)"
	if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
		kill -INT "$pid" 2>/dev/null || true
		i=0
		while kill -0 "$pid" 2>/dev/null && [ "$i" -lt 200 ]; do
			sleep 0.1
			i=$((i + 1))
		done
	fi
	finalize_recording
fi

dir="$HOME/Pictures/Screencaptures/Snippets"
f="$USER@$HOSTNAME-$(date +%Y-%m-%d_%H:%M:%S)-$(niri msg focused-window | grep 'App ID' | awk '{print $NF}').mp4"

# Fallback if no focused app id could be resolved.
case "$f" in
	*-.mp4) f="${f%.mp4}-unknown.mp4" ;;
esac

mkdir -p "$dir"

geometry="$(slurp -f "%x,%y %wx%h")" || exit 0
out="$dir/$f"
tmp="$state_dir/${f%.mp4}.mkv"

wf-recorder -g "$geometry" -f "$tmp" -r 60 -c libx264 -p crf=18 -p preset=medium >"$log_file" 2>&1 &
pid="$!"
sleep 0.2
if ! kill -0 "$pid" 2>/dev/null; then
	notify-send "Screen recording failed" "wf-recorder did not start."
	exit 1
fi

echo "$pid" >"$pid_file"
echo "$out" >"$out_file"
echo "$tmp" >"$tmp_file"

notify-send "Screen recording started" "$(basename "$out")"
