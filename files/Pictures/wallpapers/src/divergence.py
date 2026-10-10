#!/usr/bin/env python3
"""Steins;Gate-inspired divergence meter wallpaper in Tokyo Night colors.

Usage: python3 divergence.py [value] > divergence.svg
       rsvg-convert -w 1920 -h 1080 divergence.svg -o divergence.png
"""
import math
import random
import sys

W, H = 1920, 1080
_args = [a for a in sys.argv[1:] if not a.startswith("--")]
VALUE = _args[0] if _args else "1.048596"
# Optional flags (used for the GRUB background): --no-caption, --y-shift=PX
NO_CAPTION = "--no-caption" in sys.argv
Y_SHIFT = next((int(a.split("=", 1)[1]) for a in sys.argv if a.startswith("--y-shift=")), 0)

BG, BG_DARK, BG_HL = "#1a1b26", "#16161e", "#292e42"
COMMENT, TERM_BLACK = "#565f89", "#414868"
BLUE, BLUE0, MAGENTA, CYAN, ORANGE = "#7aa2f7", "#3d59a1", "#bb9af7", "#7dcfff", "#ff9e64"

random.seed(1048596)
out = []
w = out.append


def gear(cx, cy, r, teeth, depth, rot=0.0):
    pts = []
    steps = teeth * 4
    for i in range(steps):
        a = rot + 2 * math.pi * i / steps
        rr = r if (i % 4) in (0, 1) else r - depth
        pts.append(f"{cx + rr * math.cos(a):.1f},{cy + rr * math.sin(a):.1f}")
    return "M" + " L".join(pts) + " Z"


w(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
w(f"""<defs>
  <radialGradient id="bg" cx="50%" cy="46%" r="75%">
    <stop offset="0" stop-color="#222436"/>
    <stop offset="0.55" stop-color="{BG}"/>
    <stop offset="1" stop-color="{BG_DARK}"/>
  </radialGradient>
  <radialGradient id="halo" cx="50%" cy="50%" r="50%">
    <stop offset="0" stop-color="{ORANGE}" stop-opacity="0.16"/>
    <stop offset="1" stop-color="{ORANGE}" stop-opacity="0"/>
  </radialGradient>
  <linearGradient id="glass" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#c0caf5" stop-opacity="0.10"/>
    <stop offset="0.25" stop-color="#c0caf5" stop-opacity="0.02"/>
    <stop offset="0.8" stop-color="#c0caf5" stop-opacity="0.01"/>
    <stop offset="1" stop-color="#c0caf5" stop-opacity="0.07"/>
  </linearGradient>
  <linearGradient id="base" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{BG_HL}"/>
    <stop offset="1" stop-color="{BG_DARK}"/>
  </linearGradient>
  <filter id="glow" filterUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">
    <feGaussianBlur in="SourceGraphic" stdDeviation="14" result="b1"/>
    <feGaussianBlur in="SourceGraphic" stdDeviation="4" result="b2"/>
    <feMerge><feMergeNode in="b1"/><feMergeNode in="b1"/><feMergeNode in="b2"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
  <filter id="soft" x="-20%" y="-20%" width="140%" height="140%">
    <feGaussianBlur stdDeviation="2"/>
  </filter>
  <pattern id="mesh" width="9" height="9" patternUnits="userSpaceOnUse">
    <path d="M0 4.5 L4.5 0 L9 4.5 L4.5 9 Z" fill="none" stroke="{TERM_BLACK}" stroke-width="0.8" opacity="0.55"/>
  </pattern>
</defs>""")

w(f'<rect width="{W}" height="{H}" fill="url(#bg)"/>')

# Faint chart grid
for x in range(0, W + 1, 80):
    w(f'<line x1="{x}" y1="0" x2="{x}" y2="{H}" stroke="{BG_HL}" stroke-width="1" opacity="0.35"/>')
for y in range(0, H + 1, 80):
    w(f'<line x1="0" y1="{y}" x2="{W}" y2="{y}" stroke="{BG_HL}" stroke-width="1" opacity="0.35"/>')

# Gears (the S;G logo motif) in the corners
w(f'<g fill="none" stroke="{BLUE0}" stroke-width="2" opacity="0.28">')
w(f'<path d="{gear(140, 160, 230, 24, 22, 0.1)}"/><circle cx="140" cy="160" r="150"/><circle cx="140" cy="160" r="40"/>')
w(f'<path d="{gear(420, 40, 120, 14, 18, 0.3)}"/><circle cx="420" cy="40" r="70"/>')
w(f'<path d="{gear(1780, 960, 260, 28, 24, 0.2)}"/><circle cx="1780" cy="960" r="170"/><circle cx="1780" cy="960" r="50"/>')
w(f'<path d="{gear(1500, 1090, 130, 16, 18, 0.5)}"/><circle cx="1500" cy="1090" r="75"/>')
w("</g>")

# Worldlines: branching curves converging/diverging across the screen
def worldline(y0, amp, freq, phase, color, op, width):
    pts = []
    for x in range(-20, W + 21, 12):
        t = x / W
        y = y0 + amp * math.sin(freq * t * 2 * math.pi + phase) * (0.3 + t) + 40 * math.sin(t * 9 + phase * 2)
        pts.append(f"{x},{y:.1f}")
    w(f'<polyline points="{" ".join(pts)}" fill="none" stroke="{color}" stroke-width="{width}" opacity="{op}"/>')

palette = [BLUE, MAGENTA, CYAN, BLUE0]
for i in range(11):
    worldline(
        y0=H * 0.5 + random.uniform(-260, 260),
        amp=random.uniform(60, 190),
        freq=random.uniform(0.6, 1.6),
        phase=random.uniform(0, 6.28),
        color=palette[i % len(palette)],
        op=round(random.uniform(0.08, 0.2), 2),
        width=round(random.uniform(1, 2.2), 1),
    )

# Divergence meter
n = len(VALUE)
tube_w, tube_h, gap = 118, 250, 22
total = n * tube_w + (n - 1) * gap
x0 = (W - total) / 2
ty = H / 2 - tube_h / 2 - 40 + Y_SHIFT

w(f'<ellipse cx="{W/2}" cy="{ty + tube_h/2}" rx="{total*0.75}" ry="{tube_h*1.4}" fill="url(#halo)"/>')

# Base plate
w(f'<rect x="{x0-40}" y="{ty+tube_h-6}" width="{total+80}" height="46" rx="10" fill="url(#base)" stroke="{TERM_BLACK}" stroke-width="1.5"/>')
w(f'<rect x="{x0-40}" y="{ty+tube_h-6}" width="{total+80}" height="3" rx="1.5" fill="{ORANGE}" opacity="0.25"/>')

for i, ch in enumerate(VALUE):
    tx = x0 + i * (tube_w + gap)
    cx = tx + tube_w / 2
    # tube glass body (rounded top)
    r = tube_w / 2
    body = (f"M{tx},{ty+tube_h} L{tx},{ty+r} A{r},{r} 0 0 1 {tx+tube_w},{ty+r} "
            f"L{tx+tube_w},{ty+tube_h} Z")
    w(f'<path d="{body}" fill="{BG_DARK}" fill-opacity="0.55"/>')
    w(f'<path d="{body}" fill="url(#mesh)" opacity="0.6"/>')
    # unlit ghost digits stacked behind
    for g in "0123456789":
        if g != ch and ch != ".":
            w(f'<text x="{cx}" y="{ty+tube_h*0.74}" font-family="Noto Sans" font-weight="200" '
              f'font-size="178" text-anchor="middle" fill="none" stroke="{TERM_BLACK}" stroke-width="1" opacity="0.18">{g}</text>')
    # lit digit
    if ch == ".":
        w(f'<circle cx="{cx}" cy="{ty+tube_h*0.72}" r="9" fill="{ORANGE}" filter="url(#glow)"/>')
    else:
        w(f'<text x="{cx}" y="{ty+tube_h*0.74}" font-family="Noto Sans" font-weight="200" '
          f'font-size="178" text-anchor="middle" fill="none" stroke="{ORANGE}" stroke-width="3.2" '
          f'filter="url(#glow)">{ch}</text>')
        w(f'<text x="{cx}" y="{ty+tube_h*0.74}" font-family="Noto Sans" font-weight="200" '
          f'font-size="178" text-anchor="middle" fill="none" stroke="#ffe0c8" stroke-width="1.1">{ch}</text>')
    # glass highlight + outline
    w(f'<path d="{body}" fill="url(#glass)" stroke="#a9b1d6" stroke-opacity="0.22" stroke-width="1.5"/>')
    w(f'<path d="M{tx+12},{ty+tube_h-20} L{tx+12},{ty+r} A{r-12},{r-12} 0 0 1 {tx+r},{ty+12}" '
      f'fill="none" stroke="#c0caf5" stroke-opacity="0.18" stroke-width="3" stroke-linecap="round" filter="url(#soft)"/>')
    # socket
    w(f'<rect x="{tx+8}" y="{ty+tube_h-12}" width="{tube_w-16}" height="18" rx="4" fill="{BG_HL}" stroke="{TERM_BLACK}"/>')

# Captions
cap_y = ty + tube_h + 100
if not NO_CAPTION:
  w(f'<text x="{W/2}" y="{cap_y}" font-family="JetBrainsMono Nerd Font" font-weight="300" font-size="22" '
  f'letter-spacing="10" text-anchor="middle" fill="{COMMENT}">WORLDLINE DIVERGENCE  ·  STEINS GATE</text>')
  w(f'<line x1="{W/2-360}" y1="{cap_y+26}" x2="{W/2+360}" y2="{cap_y+26}" stroke="{BLUE0}" stroke-width="1" opacity="0.6"/>')
w(f'<text x="{W-60}" y="{H-50}" font-family="Noto Serif" font-style="italic" font-size="26" '
  f'text-anchor="end" fill="{BLUE}" opacity="0.45">El Psy Kongroo.</text>')

w("</svg>")
print("\n".join(out))
