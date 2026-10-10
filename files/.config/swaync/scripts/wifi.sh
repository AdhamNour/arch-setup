#!/usr/bin/env bash
# wifi.sh status|toggle — used by the swaync buttons-grid
case "$1" in
    status) [ "$(nmcli radio wifi)" = enabled ] && echo true || echo false ;;
    toggle) [ "$SWAYNC_TOGGLE_STATE" = true ] && nmcli radio wifi on || nmcli radio wifi off ;;
esac
