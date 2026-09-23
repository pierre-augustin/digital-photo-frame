#!/bin/bash
# Éteint/rallume l'écran HDMI sous Wayland/labwc pendant la veille nocturne.
# `xset dpms` ne fonctionne pas sous ce compositeur wlroots : on passe par
# wlopm (wlr-output-power-management), déclenché via cron.
#
# Usage : screen-sleep.sh {on|off}
# Appelé par cron sans environnement graphique : XDG_RUNTIME_DIR et
# WAYLAND_DISPLAY sont donc fixés ici plutôt que supposés déjà exportés.

set -euo pipefail

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

case "${1:-}" in
    off)
        wlopm --off '*'
        ;;
    on)
        wlopm --on '*'
        ;;
    *)
        echo "Usage: $0 {on|off}" >&2
        exit 1
        ;;
esac
