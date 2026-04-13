#!/bin/sh

# Invoked by xdg-desktop-portal-termfilechooser.
# Argument semantics come from xdg-desktop-portal-termfilechooser(5).

multiple="$1"
directory="$2"
save="$3"
path="$4"
out="$5"
debug="$6"

set -eu

if [ "$debug" = "1" ]; then
	set -x
fi

cmd="${YAZI_PORTAL_CMD:-yazi}"
termcmd="${TERMCMD:-kitty --title termfilechooser}"

if [ "$save" = "1" ]; then
	set -- --chooser-file="$out" "$path"
elif [ "$directory" = "1" ]; then
	set -- --chooser-file="$out" --cwd-file="$out.1" "$path"
elif [ "$multiple" = "1" ]; then
	set -- --chooser-file="$out" "$path"
else
	set -- --chooser-file="$out" "$path"
fi

# TERMCMD is a whitespace-delimited launcher command such as:
#   kitty --title termfilechooser
# Split it into words and exec directly so portal-supplied paths never flow
# through `sh -c`.
# shellcheck disable=SC2086
set -- $termcmd "$cmd" "$@"
"$@"

if [ "$directory" = "1" ]; then
	if [ ! -s "$out" ] && [ -s "$out.1" ]; then
		cat "$out.1" >"$out"
		rm "$out.1"
	else
		rm -f "$out.1"
	fi
fi
