#!/usr/bin/env python3
"""Waybar custom module: current keyboard layout (EN / ع), updated from Hyprland's event socket.
(waybar 0.15's built-in hyprland/language module shows only "…" with Hyprland 0.56.)"""
import json
import os
import socket
import subprocess

ICON = "\U000f030c"  # nf-md-keyboard


def current_keymap():
    out = subprocess.run(["hyprctl", "devices", "-j"], capture_output=True, text=True).stdout
    keyboards = json.loads(out)["keyboards"]
    kb = next((k for k in keyboards if k.get("main")), keyboards[0])
    return kb["active_keymap"]


def emit(keymap):
    arabic = keymap.startswith("Arabic")
    print(json.dumps({
        "text": f"{ICON}  {'ع' if arabic else 'EN'}",
        "tooltip": f"{keymap}  ·  SUPER+Space to switch",
        "class": "ar" if arabic else "en",
    }), flush=True)


last = current_keymap()
emit(last)

sock_path = os.path.join(os.environ["XDG_RUNTIME_DIR"], "hypr",
                         os.environ["HYPRLAND_INSTANCE_SIGNATURE"], ".socket2.sock")
sock = socket.socket(socket.AF_UNIX)
sock.connect(sock_path)
buf = b""
while True:
    data = sock.recv(4096)
    if not data:
        break
    buf += data
    while b"\n" in buf:
        line, buf = buf.split(b"\n", 1)
        if line.startswith(b"activelayout>>"):
            keymap = line.decode(errors="replace").split(",", 1)[-1]
            if keymap != last:          # the event fires once per keyboard device
                last = keymap
                emit(keymap)
