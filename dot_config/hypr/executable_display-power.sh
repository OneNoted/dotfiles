#!/bin/sh

set -eu

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <on|off>" >&2
    exit 2
fi

case "$1" in
    on)
        niri_action="power-on-monitors"
        hypr_mode="on"
        ;;
    off)
        niri_action="power-off-monitors"
        hypr_mode="off"
        ;;
    *)
        echo "usage: $0 <on|off>" >&2
        exit 2
        ;;
esac

if [ -n "${NIRI_SOCKET:-}" ]; then
    exec niri msg action "$niri_action"
fi

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    exec hyprctl dispatch dpms "$hypr_mode"
fi

echo "display-power.sh: no supported compositor session detected" >&2
exit 1
