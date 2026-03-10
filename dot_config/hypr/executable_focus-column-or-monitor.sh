#!/bin/sh

set -eu

dir="${1:-}"

case "$dir" in
    l|r) ;;
    *)
        printf '%s\n' "usage: ${0##*/} <l|r>" >&2
        exit 2
        ;;
esac

if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "hyprctl and jq are required" >&2
    exit 1
fi

active="$(hyprctl activewindow -j 2>/dev/null || printf '{}')"
address="$(printf '%s' "$active" | jq -r '.address // empty')"

if [ -z "$address" ]; then
    exec hyprctl dispatch focusmonitor "$dir"
fi

monitor="$(printf '%s' "$active" | jq -r '.monitor')"
workspace="$(printf '%s' "$active" | jq -r '.workspace.id')"
xpos="$(printf '%s' "$active" | jq -r '.at[0]')"

has_column_in_direction="$(
    hyprctl clients -j | jq -r \
        --arg address "$address" \
        --arg dir "$dir" \
        --argjson monitor "$monitor" \
        --argjson workspace "$workspace" \
        --argjson xpos "$xpos" '
        any(
            .[];
            .address != $address
            and .mapped == true
            and .hidden == false
            and .floating == false
            and .monitor == $monitor
            and .workspace.id == $workspace
            and (
                if $dir == "l" then
                    .at[0] < $xpos
                else
                    .at[0] > $xpos
                end
            )
        )'
)"

if [ "$has_column_in_direction" = "true" ]; then
    exec hyprctl dispatch layoutmsg "focus $dir"
fi

exec hyprctl dispatch focusmonitor "$dir"
