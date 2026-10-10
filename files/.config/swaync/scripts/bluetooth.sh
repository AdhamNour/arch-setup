#!/usr/bin/env bash
# bluetooth.sh status|toggle — used by the swaync buttons-grid
case "$1" in
    status) bluetoothctl show | grep -q "Powered: yes" && echo true || echo false ;;
    toggle) [ "$SWAYNC_TOGGLE_STATE" = true ] && bluetoothctl power on || bluetoothctl power off ;;
esac
