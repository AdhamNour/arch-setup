#!/usr/bin/env python3
"""Render Plymouth assets for the steins-gate theme: one image per nixie-tube state.

Writes SVGs next to this script and converts them with rsvg-convert:
  tube-0..9.png, tube-dot.png, tube-off.png, base.png, caption.png, caption-final.png
"""
import os
import subprocess

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "steins-gate")
os.makedirs(OUT, exist_ok=True)

BG_DARK, BG_HL, TERM_BLACK, COMMENT = "#16161e", "#292e42", "#414868", "#565f89"
ORANGE, BLUE0, BLUE = "#ff9e64", "#3d59a1", "#7aa2f7"

TW, TH = 118, 250          # tube size (same as the wallpaper)
PAD = 30                   # room for the glow
CW, CH = TW + 2 * PAD, TH + 2 * PAD + 12


def render(name, svg, w, h):
    src = os.path.join(OUT, name + ".svg")
    with open(src, "w") as f:
        f.write(svg)
    subprocess.run(["rsvg-convert", "-w", str(w), "-h", str(h), src,
                    "-o", os.path.join(OUT, name + ".png")], check=True)
    os.remove(src)


def tube(lit):
    x, y, r = PAD, PAD, TW / 2
    cx = x + TW / 2
    body = (f"M{x},{y+TH} L{x},{y+r} A{r},{r} 0 0 1 {x+TW},{y+r} L{x+TW},{y+TH} Z")
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{CW}" height="{CH}" viewBox="0 0 {CW} {CH}">',
           f'''<defs>
  <linearGradient id="glass" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#c0caf5" stop-opacity="0.10"/>
    <stop offset="0.25" stop-color="#c0caf5" stop-opacity="0.02"/>
    <stop offset="0.8" stop-color="#c0caf5" stop-opacity="0.01"/>
    <stop offset="1" stop-color="#c0caf5" stop-opacity="0.07"/>
  </linearGradient>
  <filter id="glow" filterUnits="userSpaceOnUse" x="0" y="0" width="{CW}" height="{CH}">
    <feGaussianBlur in="SourceGraphic" stdDeviation="12" result="b1"/>
    <feGaussianBlur in="SourceGraphic" stdDeviation="4" result="b2"/>
    <feMerge><feMergeNode in="b1"/><feMergeNode in="b1"/><feMergeNode in="b2"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
  <pattern id="mesh" width="9" height="9" patternUnits="userSpaceOnUse">
    <path d="M0 4.5 L4.5 0 L9 4.5 L4.5 9 Z" fill="none" stroke="{TERM_BLACK}" stroke-width="0.8" opacity="0.55"/>
  </pattern>
</defs>''',
           f'<path d="{body}" fill="{BG_DARK}" fill-opacity="0.8"/>',
           f'<path d="{body}" fill="url(#mesh)" opacity="0.6"/>']
    digit_y = y + TH * 0.74
    text = ('font-family="Noto Sans" font-weight="200" font-size="178" text-anchor="middle" fill="none"')
    if lit != ".":
        for g in "0123456789":
            if g != lit:
                out.append(f'<text x="{cx}" y="{digit_y}" {text} stroke="{TERM_BLACK}" stroke-width="1" opacity="0.18">{g}</text>')
    if lit == ".":
        out.append(f'<circle cx="{cx}" cy="{y+TH*0.72}" r="9" fill="{ORANGE}" filter="url(#glow)"/>')
    elif lit is not None:
        out.append(f'<text x="{cx}" y="{digit_y}" {text} stroke="{ORANGE}" stroke-width="3.2" filter="url(#glow)">{lit}</text>')
        out.append(f'<text x="{cx}" y="{digit_y}" {text} stroke="#ffe0c8" stroke-width="1.1">{lit}</text>')
    out.append(f'<path d="{body}" fill="url(#glass)" stroke="#a9b1d6" stroke-opacity="0.22" stroke-width="1.5"/>')
    out.append(f'<path d="M{x+12},{y+TH-20} L{x+12},{y+r} A{r-12},{r-12} 0 0 1 {x+r},{y+12}" '
               f'fill="none" stroke="#c0caf5" stroke-opacity="0.18" stroke-width="3" stroke-linecap="round"/>')
    out.append(f'<rect x="{x+8}" y="{y+TH-12}" width="{TW-16}" height="18" rx="4" fill="{BG_HL}" stroke="{TERM_BLACK}"/>')
    out.append("</svg>")
    return "\n".join(out)


for d in "0123456789":
    render(f"tube-{d}", tube(d), CW, CH)
render("tube-dot", tube("."), CW, CH)
render("tube-off", tube(None), CW, CH)

# Base plate under the 8 tubes (tube pitch = TW + 22)
BW = 8 * TW + 7 * 22 + 80
render("base", f'''<svg xmlns="http://www.w3.org/2000/svg" width="{BW}" height="50">
<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="{BG_HL}"/><stop offset="1" stop-color="{BG_DARK}"/></linearGradient></defs>
<rect x="1" y="1" width="{BW-2}" height="46" rx="10" fill="url(#g)" stroke="{TERM_BLACK}" stroke-width="1.5"/>
<rect x="1" y="1" width="{BW-2}" height="3" rx="1.5" fill="{ORANGE}" opacity="0.25"/>
</svg>''', BW, 50)

cap = ('font-family="JetBrainsMono Nerd Font" font-weight="300" font-size="22" letter-spacing="10" '
       'text-anchor="middle"')
render("caption", f'''<svg xmlns="http://www.w3.org/2000/svg" width="900" height="40">
<text x="450" y="28" {cap} fill="{COMMENT}">WORLDLINE DIVERGENCE</text></svg>''', 900, 40)
render("caption-final", f'''<svg xmlns="http://www.w3.org/2000/svg" width="900" height="40">
<text x="450" y="28" {cap} fill="{BLUE}">STEINS GATE</text></svg>''', 900, 40)

print("assets in", OUT)
