"""Tatreez (Palestinian cross-stitch) pattern generator.

Generates symmetric cross-stitch motif bands as SVG (dependency free) and, when Pillow
is available, as PNG. Motifs are built on a stitch grid the way real tatreez is: every
cell is either empty or a cross of one thread colour, and patterns are mirrored on both
axes so they read as embroidery rather than pixel art.

Usage:
    python tools/tatreez.py --seed 3 --count 6

Outputs, per pattern i:
    game/assets/tatreez/band_<i>.svg   a repeating horizontal band, 1 cell = 1 stitch
    game/assets/tatreez/band_<i>.png   (if Pillow is installed) rasterised at --cell px per stitch
    game/assets/tatreez/band_<i>.json  the stitch grid and its order of stitching, for the
                                  in-game "stitching itself in" animation
"""
from __future__ import annotations

import argparse
import json
import os
import random

# Classic tatreez palette. Red on black or cream is the Gaza and Hebron register.
THREAD_RED = "#B5121B"
THREAD_DARK_RED = "#7A0C14"
THREAD_CREAM = "#F1E6D0"
THREAD_GREEN = "#2E5E3E"
THREAD_BLACK = "#15110F"
CLOTH_BLACK = "#15110F"
CLOTH_CREAM = "#F1E6D0"


def _mirror(cells: set[tuple[int, int]], w: int, h: int) -> set[tuple[int, int]]:
    """Mirror a quarter motif into all four quadrants of a w x h tile."""
    out = set()
    for x, y in cells:
        for mx in (x, w - 1 - x):
            for my in (y, h - 1 - y):
                out.add((mx, my))
    return out


def motif_cypress(rng: random.Random, size: int) -> set[tuple[int, int]]:
    """Saru (cypress tree): a tapering stack of chevrons with a trunk."""
    cells = set()
    c = size // 2
    for row in range(size - 3):
        half = max(0, (row // 2)) if row < size // 2 else max(0, ((size - 4 - row) // 2))
        half = min(half, c - 1)
        for dx in range(-half, half + 1):
            if (dx + row) % 2 == 0:
                cells.add((c + dx, row + 1))
    for row in range(size - 3, size - 1):
        cells.add((c, row))
    return cells


def motif_star(rng: random.Random, size: int) -> set[tuple[int, int]]:
    """Eight-pointed star built from a mirrored quarter."""
    q = set()
    half = size // 2
    for y in range(half):
        for x in range(half):
            d = abs(x - (half - 1)) + abs(y - (half - 1))
            on_diag = x == y
            on_axis = x == half - 1 or y == half - 1
            if d <= half // 2 or (on_diag and d <= half) or (on_axis and d <= half - 1):
                q.add((x, y))
    return _mirror(q, size, size)


def motif_chevron_band(rng: random.Random, size: int) -> set[tuple[int, int]]:
    """Feathers (rish): stacked chevrons running along the band."""
    cells = set()
    step = rng.choice([3, 4])
    for x in range(size):
        y = abs((x % (2 * step)) - step)
        for k in range(0, size, step + 2):
            yy = y + k
            if 0 <= yy < size:
                cells.add((x, yy))
    return cells


def motif_diamond_lattice(rng: random.Random, size: int) -> set[tuple[int, int]]:
    """Lozenges with a filled heart, a very common border."""
    cells = set()
    c = size // 2
    r = c - 1
    for y in range(size):
        for x in range(size):
            d = abs(x - c) + abs(y - c)
            if d == r or d <= 1:
                cells.add((x, y))
    return cells


def motif_moons(rng: random.Random, size: int) -> set[tuple[int, int]]:
    """Qamar (moon) discs: mirrored quarter arcs."""
    q = set()
    half = size // 2
    rad = half - 1
    for y in range(half):
        for x in range(half):
            dx = (half - 1) - x + 0.5
            dy = (half - 1) - y + 0.5
            d2 = dx * dx + dy * dy
            if (rad - 1.2) ** 2 <= d2 <= (rad + 0.3) ** 2 or d2 <= 1.6:
                q.add((x, y))
    return _mirror(q, size, size)


MOTIFS = [motif_cypress, motif_star, motif_chevron_band, motif_diamond_lattice, motif_moons]


def build_band(rng: random.Random, tile: int, repeats: int) -> dict:
    """A band = a row of `repeats` tiles, each a motif, with a thin border line above and below."""
    main = rng.choice(MOTIFS)
    alt = rng.choice(MOTIFS)
    h = tile + 4
    w = tile * repeats
    grid = [[None for _ in range(w)] for _ in range(h)]
    for i in range(repeats):
        motif = main if i % 2 == 0 else (main if rng.random() < 0.6 else alt)
        colour = THREAD_RED if motif is main else THREAD_GREEN
        cells = motif(rng, tile)
        for (x, y) in cells:
            gx, gy = i * tile + x, y + 2
            if 0 <= gx < w and 0 <= gy < h:
                grid[gy][gx] = colour
    for x in range(w):
        if x % 2 == 0:
            grid[0][x] = THREAD_DARK_RED
            grid[h - 1][x] = THREAD_DARK_RED
    # Stitching order: left to right, top to bottom within each tile, so the band grows across.
    order = []
    for i in range(repeats):
        for y in range(h):
            for x in range(i * tile, (i + 1) * tile):
                if grid[y][x]:
                    order.append([x, y])
    return {"width": w, "height": h, "tile": tile, "grid": grid, "order": order,
            "motifs": [main.__name__, alt.__name__]}


def band_svg(band: dict, cell: int, cloth: str) -> str:
    w, h = band["width"] * cell, band["height"] * cell
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">',
             f'<rect width="{w}" height="{h}" fill="{cloth}"/>']
    sw = max(1.0, cell * 0.22)
    inset = cell * 0.12
    for y, row in enumerate(band["grid"]):
        for x, colour in enumerate(row):
            if not colour:
                continue
            x0, y0 = x * cell + inset, y * cell + inset
            x1, y1 = (x + 1) * cell - inset, (y + 1) * cell - inset
            parts.append(f'<path d="M{x0:.1f} {y0:.1f}L{x1:.1f} {y1:.1f}M{x1:.1f} {y0:.1f}L{x0:.1f} {y1:.1f}" '
                         f'stroke="{colour}" stroke-width="{sw:.1f}" stroke-linecap="round" fill="none"/>')
    parts.append("</svg>")
    return "\n".join(parts)


def band_png(band: dict, cell: int, cloth: str, path: str) -> bool:
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return False
    scale = 4  # supersample for smooth thread edges
    c = cell * scale
    w, h = band["width"] * c, band["height"] * c
    img = Image.new("RGB", (w, h), cloth)
    draw = ImageDraw.Draw(img)
    sw = max(1, int(c * 0.22))
    inset = int(c * 0.12)
    for y, row in enumerate(band["grid"]):
        for x, colour in enumerate(row):
            if not colour:
                continue
            x0, y0 = x * c + inset, y * c + inset
            x1, y1 = (x + 1) * c - inset, (y + 1) * c - inset
            draw.line([(x0, y0), (x1, y1)], fill=colour, width=sw)
            draw.line([(x1, y0), (x0, y1)], fill=colour, width=sw)
    img = img.resize((w // scale, h // scale), Image.LANCZOS)
    img.save(path)
    return True


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="game/assets/tatreez")
    ap.add_argument("--seed", type=int, default=3)
    ap.add_argument("--count", type=int, default=6)
    ap.add_argument("--tile", type=int, default=15, help="stitches per motif tile (odd works best)")
    ap.add_argument("--repeats", type=int, default=8)
    ap.add_argument("--cell", type=int, default=8, help="pixels per stitch in the PNG and SVG")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    rng = random.Random(args.seed)
    made = []
    for i in range(args.count):
        band = build_band(rng, args.tile, args.repeats)
        cloth = CLOTH_BLACK if i % 2 == 0 else CLOTH_CREAM
        base = os.path.join(args.out, f"band_{i}")
        with open(base + ".svg", "w", encoding="utf-8") as f:
            f.write(band_svg(band, args.cell, cloth))
        with open(base + ".json", "w", encoding="utf-8") as f:
            json.dump({k: v for k, v in band.items() if k != "grid"} | {"cloth": cloth,
                      "stitches": [[x, y, band["grid"][y][x]] for x, y in band["order"]]}, f)
        png = band_png(band, args.cell, cloth, base + ".png")
        made.append((base, band["motifs"], png))
    for base, motifs, png in made:
        print(f"{base}: {motifs[0]} + {motifs[1]}  png={'yes' if png else 'no (Pillow missing)'}")


if __name__ == "__main__":
    main()
