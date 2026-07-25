#!/usr/bin/env python3
"""Render `gearup doctor` output into docs/gearup-doctor.svg.

A dependency-free way to keep the README screenshot in sync with the real
catalog. Usage from the repo root:

    ./gearup doctor > /tmp/doctor.txt   # (build first: make build)
    python3 docs/gen-doctor-svg.py

Produces a two-column, terminal-styled SVG that GitHub renders inline.
"""
import html

lines = open("/tmp/doctor.txt").read().splitlines()

# Parse into blocks: {header, [(mark, name, desc)]}, plus a trailing summary.
blocks, cur, summary = [], None, ""
for ln in lines:
    s = ln.rstrip()
    if not s.strip():
        continue
    if s.lstrip().startswith(("✓", "✗")):  # ✓ / ✗
        rest = s.strip()[1:].strip()
        parts = rest.split(None, 1)
        name = parts[0]
        desc = parts[1] if len(parts) > 1 else ""
        if cur is not None:
            cur["tools"].append((s.strip()[0], name, desc))
    elif "tool(s) missing" in s or "all cataloged" in s:
        summary = s.strip()
    else:
        cur = {"header": s.strip(), "tools": []}
        blocks.append(cur)


def h(b):
    return 1 + len(b["tools"]) + 1


total = sum(h(b) for b in blocks)
col1, col2, acc = [], [], 0
for b in blocks:
    if acc < total / 2:
        col1.append(b)
        acc += h(b)
    else:
        col2.append(b)

PAD, TOP, LH, COLW, FS = 22, 56, 18.5, 372, 13
cols = [col1, col2]
rows = max(sum(h(b) for b in c) for c in cols)
W = PAD * 2 + COLW * 2 + 24
H = int(TOP + rows * LH + 40)

GREEN, MISS, HEAD = "#3fb950", "#6e7681", "#58a6ff"
NAME, NAMEDIM, DESC = "#c9d1d9", "#6e7681", "#768390"


def esc(t):
    return html.escape(t, quote=True)


out = [
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
    f'viewBox="0 0 {W} {H}" font-family="ui-monospace,SFMono-Regular,Menlo,'
    f'Consolas,monospace" font-size="{FS}">',
    f'<rect x="0" y="0" width="{W}" height="{H}" rx="10" fill="#0d1117" stroke="#30363d"/>',
    '<circle cx="20" cy="20" r="6" fill="#ff5f56"/>'
    '<circle cx="40" cy="20" r="6" fill="#ffbd2e"/>'
    '<circle cx="60" cy="20" r="6" fill="#27c93f"/>',
    f'<text x="{W/2}" y="24" fill="#8b949e" text-anchor="middle">$ gearup doctor</text>',
    f'<line x1="0" y1="40" x2="{W}" y2="40" stroke="#30363d"/>',
]

for ci, col in enumerate(cols):
    x = PAD + ci * (COLW + 24)
    y = TOP
    for b in col:
        out.append(f'<text x="{x}" y="{y:.1f}" fill="{HEAD}" font-weight="700">{esc(b["header"])}</text>')
        y += LH
        for mark, name, desc in b["tools"]:
            ok = mark == "✓"
            mc = GREEN if ok else MISS
            nc = NAME if ok else NAMEDIM
            out.append(
                f'<text x="{x}" y="{y:.1f}">'
                f'<tspan fill="{mc}">{"✓" if ok else "✗"}</tspan>'
                f'<tspan fill="{nc}" xml:space="preserve">  {esc(name)}</tspan>'
                f'<tspan fill="{DESC}" xml:space="preserve">  {esc(desc)}</tspan>'
                f"</text>"
            )
            y += LH
        y += LH

out.append(f'<text x="{PAD}" y="{H-16}" fill="#8b949e"><tspan fill="#d29922">•</tspan> {esc(summary)}</text>')
out.append("</svg>")
open("docs/gearup-doctor.svg", "w").write("\n".join(out))
print(f"wrote docs/gearup-doctor.svg  {W}x{H}")
