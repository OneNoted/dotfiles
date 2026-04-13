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

command="$termcmd $cmd"
for arg in "$@"; do
    escaped=$(printf "%s" "$arg" | sed 's/"/\\"/g')
    command="$command \"$escaped\""
done

sh -c "$command"

if [ "$directory" = "1" ]; then
    if [ ! -s "$out" ] && [ -s "$out.1" ]; then
        cat "$out.1" > "$out"
        rm "$out.1"
    else
        rm -f "$out.1"
    fi
fi
