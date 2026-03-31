#!/usr/bin/env sh

set -eu

state_dir="${XDG_RUNTIME_DIR:-/tmp}/niri-snappers-record"
pid_file="$state_dir/pid"
out_file="$state_dir/out"
log_file="$state_dir/log"

mkdir -p "$state_dir"

cleanup() {
	rm -f "$pid_file" "$out_file" "$log_file"
}

best_effort_notify() {
	if command -v notify-send >/dev/null 2>&1; then
		notify-send "$@" >/dev/null 2>&1 || true
	fi
}

if [ -f "$pid_file" ]; then
	pid="$(cat "$pid_file" 2>/dev/null || true)"
	out="$(cat "$out_file" 2>/dev/null || true)"

	if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
		kill -INT "$pid" 2>/dev/null || true
		i=0
		while kill -0 "$pid" 2>/dev/null && [ "$i" -lt 200 ]; do
			sleep 0.1
			i=$((i + 1))
		done
	fi

	if [ -n "$out" ] && [ -s "$out" ]; then
		best_effort_notify "Screen recording stopped" "$out"
	else
		best_effort_notify "Screen recording stopped" "The recording did not produce a file."
	fi

	cleanup
	exit 0
fi

dir="$HOME/Videos/Recordings"
mkdir -p "$dir"

out="$dir/Recording from $(date +%Y-%m-%d\ %H-%M-%S).mp4"
log="$state_dir/$(basename "$out").log"

/home/notes/.cargo/bin/snappers record area --path "$out" >"$log" 2>&1 &
pid="$!"
sleep 0.2

if ! kill -0 "$pid" 2>/dev/null; then
	best_effort_notify "Screen recording failed" "snappers did not stay running. See: $log"
	exit 1
fi

echo "$pid" >"$pid_file"
echo "$out" >"$out_file"
echo "$log" >"$log_file"

best_effort_notify "Screen recording started" "$(basename "$out")"
