#!/usr/bin/env python3
"""Turn frames into clean silhouettes for the game, with classical image processing only.

Three jobs, all without machine learning:

  split   cut a generated sprite sheet (a grid of poses) into single frames
  key     turn frames into one-colour silhouettes with a transparent background
  strip   assemble finished frames into one horizontal strip plus a JSON sidecar

Usage from the repo root:

  python3 tools/roto.py split  sheet.png --cols 6 --rows 2 --out /tmp/frames
  python3 tools/roto.py key    /tmp/frames --out game/assets/characters/layla/walk --height 512
  python3 tools/roto.py strip  game/assets/characters/layla/walk --fps 12 --loop

`key` decides what is "figure" by one of three rules, tried in this order when not forced:
  --bg background.png   difference from a clean plate (filmed footage)
  --alpha               the frame already has transparency (generated PNG with a clear background)
  --lum N               everything darker than N (0-255) is figure (silhouette on a light ground)

It then removes specks, fills pin holes, crops every frame to the same box so the feet stay
planted, scales to --height, and writes name_0001.png ... with the figure as --colour (default
near-black) and the ground at alpha 0. A `hands.json` with the per-frame hand position can be
added by hand or by `--hand x,y` for a static one; the game reads it for carried items.
"""
from __future__ import annotations

import argparse
import json
import os
import sys

import numpy as np
from PIL import Image


def _load(path: str) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGBA"), dtype=np.uint8)


def _frames_in(folder: str) -> list[str]:
    names = sorted(
        f for f in os.listdir(folder)
        if f.lower().endswith((".png", ".jpg", ".jpeg", ".webp")) and not f.startswith(".")
        and f != "strip.png"
    )
    if not names:
        sys.exit(f"roto: no frames in {folder}")
    return [os.path.join(folder, f) for f in names]


def _erode(mask: np.ndarray, r: int) -> np.ndarray:
    out = mask.copy()
    for _ in range(r):
        m = out
        out = m & np.roll(m, 1, 0) & np.roll(m, -1, 0) & np.roll(m, 1, 1) & np.roll(m, -1, 1)
    return out


def _dilate(mask: np.ndarray, r: int) -> np.ndarray:
    out = mask.copy()
    for _ in range(r):
        m = out
        out = m | np.roll(m, 1, 0) | np.roll(m, -1, 0) | np.roll(m, 1, 1) | np.roll(m, -1, 1)
    return out


def _largest_components(mask: np.ndarray, keep_ratio: float = 0.02) -> np.ndarray:
    """Drop blobs smaller than keep_ratio of the biggest one (specks, stray marks)."""
    h, w = mask.shape
    labels = np.zeros((h, w), dtype=np.int32)
    sizes: list[int] = []
    current = 0
    ys, xs = np.nonzero(mask)
    todo = list(zip(ys.tolist(), xs.tolist()))
    seen = np.zeros((h, w), dtype=bool)
    for y0, x0 in todo:
        if seen[y0, x0]:
            continue
        current += 1
        stack = [(y0, x0)]
        seen[y0, x0] = True
        size = 0
        while stack:
            y, x = stack.pop()
            labels[y, x] = current
            size += 1
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    stack.append((ny, nx))
        sizes.append(size)
    if not sizes:
        return mask
    biggest = max(sizes)
    keep = {i + 1 for i, s in enumerate(sizes) if s >= biggest * keep_ratio}
    if keep_ratio >= 1.0:
        keep = {sizes.index(biggest) + 1}
    return np.isin(labels, list(keep))


def _fill_holes(mask: np.ndarray) -> np.ndarray:
    """Everything the background cannot reach from the image border becomes figure."""
    h, w = mask.shape
    outside = np.zeros((h, w), dtype=bool)
    stack = [(y, x) for x in range(w) for y in (0, h - 1) if not mask[y, x]]
    stack += [(y, x) for y in range(h) for x in (0, w - 1) if not mask[y, x]]
    for y, x in stack:
        outside[y, x] = True
    while stack:
        y, x = stack.pop()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not mask[ny, nx] and not outside[ny, nx]:
                outside[ny, nx] = True
                stack.append((ny, nx))
    return ~outside


def _mask_for(frame: np.ndarray, args: argparse.Namespace, plate: np.ndarray | None) -> np.ndarray:
    if args.key:
        key = np.array([int(args.key[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.int16)
        diff = np.abs(frame[:, :, :3].astype(np.int16) - key).sum(axis=2)
        return diff > args.diff
    if plate is not None:
        diff = np.abs(frame[:, :, :3].astype(np.int16) - plate[:, :, :3].astype(np.int16)).sum(axis=2)
        return diff > args.diff
    if args.alpha or (not args.lum and frame[:, :, 3].min() < 250):
        return frame[:, :, 3] > 128
    lum = (0.299 * frame[:, :, 0] + 0.587 * frame[:, :, 1] + 0.114 * frame[:, :, 2])
    threshold = args.lum if args.lum else 110
    return lum < threshold


def cmd_split(args: argparse.Namespace) -> None:
    sheet = Image.open(args.sheet).convert("RGBA")
    w, h = sheet.size
    cw, ch = w // args.cols, h // args.rows
    os.makedirs(args.out, exist_ok=True)
    n = 0
    for r in range(args.rows):
        for c in range(args.cols):
            n += 1
            tile = sheet.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch))
            tile.save(os.path.join(args.out, f"{args.name}_{n:04d}.png"))
    print(f"roto: split {args.sheet} into {n} tiles of {cw}x{ch} in {args.out}")


def cmd_key(args: argparse.Namespace) -> None:
    paths = _frames_in(args.frames)
    plate = _load(args.bg) if args.bg else None
    frames = [Image.open(p).convert("RGBA") for p in paths]
    # Previews of the same page can arrive at different pixel sizes; bring them to the largest.
    big = max(frames, key=lambda im: im.width * im.height).size
    frames = [im if im.size == big else im.resize(big, Image.LANCZOS) for im in frames]
    masks: list[np.ndarray] = []
    for im in frames:
        f = np.asarray(im, dtype=np.uint8)
        if plate is not None and plate.shape != f.shape:
            sys.exit("roto: background plate must match the frame size")
        m = _mask_for(f, args, plate)
        for region in args.erase:
            x0, y0, x1, y1 = (float(v) for v in region.split(","))
            hh, ww = m.shape
            m[int(y0 * hh):int(y1 * hh), int(x0 * ww):int(x1 * ww)] = False
        m = _dilate(_erode(m, args.clean), args.clean)          # open: drop specks
        m = _erode(_dilate(m, args.fill), args.fill)            # close: fill pin holes
        m = _largest_components(m, 1.0 if args.largest else 0.02)
        if args.solid:
            m = _fill_holes(m)
        masks.append(m)
    ys = [np.nonzero(m.any(axis=1))[0] for m in masks]
    xs = [np.nonzero(m.any(axis=0))[0] for m in masks]
    if any(len(y) == 0 for y in ys):
        sys.exit("roto: a frame keyed to nothing; adjust --lum, --diff or --alpha")
    if args.per_frame:
        # each frame on its own box, bottom-centred into one canvas: for jumps and poses whose
        # rise the game supplies itself
        boxes = [m[int(y[0]):int(y[-1]) + 1, int(x[0]):int(x[-1]) + 1] for m, y, x in zip(masks, ys, xs)]
        cw = max(b.shape[1] for b in boxes) + 2 * args.pad
        chh = max(b.shape[0] for b in boxes) + 2 * args.pad
        padded: list[np.ndarray] = []
        for b in boxes:
            canvas = np.zeros((chh, cw), dtype=bool)
            ox = (cw - b.shape[1]) // 2
            oy = chh - args.pad - b.shape[0]
            canvas[oy:oy + b.shape[0], ox:ox + b.shape[1]] = b
            padded.append(canvas)
        masks = padded
        ys = [np.nonzero(m.any(axis=1))[0] for m in masks]
        xs = [np.nonzero(m.any(axis=0))[0] for m in masks]
    # one crop box for the whole animation, anchored at the lowest foot
    top = min(int(y[0]) for y in ys)
    bottom = max(int(y[-1]) for y in ys)
    left = min(int(x[0]) for x in xs)
    right = max(int(x[-1]) for x in xs)
    pad = args.pad
    os.makedirs(args.out, exist_ok=True)
    colour = tuple(int(args.colour[i:i + 2], 16) for i in (0, 2, 4))
    box_h = bottom - top + 1 + 2 * pad
    scale = args.height / box_h if args.height else 1.0
    sizes = []
    for i, m in enumerate(masks, start=1):
        crop = m[max(top - pad, 0):bottom + pad + 1, max(left - pad, 0):right + pad + 1]
        rgba = np.zeros((*crop.shape, 4), dtype=np.uint8)
        if args.key:
            src = np.asarray(frames[i - 1], dtype=np.uint8)
            if args.per_frame:
                sys.exit("roto: --key and --per-frame cannot be combined")
            win = src[max(top - pad, 0):bottom + pad + 1, max(left - pad, 0):right + pad + 1, :3]
            rgba[crop, :3] = win[crop]
            rgba[crop, 3] = 255
        else:
            rgba[crop] = (*colour, 255)
        im = Image.fromarray(rgba, "RGBA")
        if scale != 1.0:
            im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
        im.save(os.path.join(args.out, f"{args.name}_{i:04d}.png"))
        sizes.append(im.size)
    meta = {"frames": len(masks), "size": list(sizes[0]), "source": os.path.abspath(args.frames)}
    if args.hand:
        hx, hy = (int(v) for v in args.hand.split(","))
        meta["hand"] = [[hx, hy] for _ in masks]
    with open(os.path.join(args.out, "frames.json"), "w", encoding="utf-8") as fh:
        json.dump(meta, fh, indent=2)
    print(f"roto: keyed {len(masks)} frames to {sizes[0][0]}x{sizes[0][1]} in {args.out}")


def cmd_strip(args: argparse.Namespace) -> None:
    paths = _frames_in(args.frames)
    ims = [Image.open(p).convert("RGBA") for p in paths]
    w = max(i.width for i in ims)
    h = max(i.height for i in ims)
    strip = Image.new("RGBA", (w * len(ims), h), (0, 0, 0, 0))
    for n, im in enumerate(ims):
        strip.paste(im, (n * w + (w - im.width) // 2, h - im.height))
    out = args.out or os.path.join(args.frames, "strip.png")
    strip.save(out)
    side = {"frames": len(ims), "frame_w": w, "frame_h": h, "fps": args.fps, "loop": bool(args.loop),
            "stand_ratio": args.stand_ratio}
    hands_path = os.path.join(args.frames, "frames.json")
    if os.path.exists(hands_path):
        with open(hands_path, encoding="utf-8") as fh:
            side["hand"] = json.load(fh).get("hand")
    with open(os.path.splitext(out)[0] + ".json", "w", encoding="utf-8") as fh:
        json.dump(side, fh, indent=2)
    print(f"roto: strip of {len(ims)} frames {w}x{h} at {out}")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("split")
    s.add_argument("sheet")
    s.add_argument("--cols", type=int, required=True)
    s.add_argument("--rows", type=int, required=True)
    s.add_argument("--out", required=True)
    s.add_argument("--name", default="frame")
    s.set_defaults(fn=cmd_split)

    k = sub.add_parser("key")
    k.add_argument("frames")
    k.add_argument("--out", required=True)
    k.add_argument("--name", default="frame")
    k.add_argument("--bg", help="clean background plate (filmed footage)")
    k.add_argument("--alpha", action="store_true", help="use the frame's own alpha")
    k.add_argument("--lum", type=int, default=0, help="figure is darker than this (0-255)")
    k.add_argument("--diff", type=int, default=60, help="plate difference threshold")
    k.add_argument("--clean", type=int, default=1, help="opening radius (specks)")
    k.add_argument("--fill", type=int, default=2, help="closing radius (pin holes)")
    k.add_argument("--pad", type=int, default=8)
    k.add_argument("--height", type=int, default=0, help="scale the crop box to this height")
    k.add_argument("--colour", default="0b0a14", help="silhouette colour, hex")
    k.add_argument("--hand", help="static hand position x,y in output pixels")
    k.add_argument("--per-frame", dest="per_frame", action="store_true", help="crop each frame to its own box and bottom-align (jumps)")
    k.add_argument("--key", help="colour-key mode: pixels near this hex colour become transparent and the rest keep their own colours (coloured props)")
    k.add_argument("--erase", action="append", default=[], metavar="X0,Y0,X1,Y1",
                   help="blank this region (fractions of the frame) before keying; repeatable")
    k.add_argument("--solid", action="store_true", help="fill enclosed holes (grey detail inside a silhouette)")
    k.add_argument("--largest", action="store_true", help="keep only the single biggest blob (a figure and what it holds)")
    k.set_defaults(fn=cmd_key)

    t = sub.add_parser("strip")
    t.add_argument("frames")
    t.add_argument("--out")
    t.add_argument("--fps", type=int, default=12)
    t.add_argument("--loop", action="store_true")
    t.add_argument("--stand-ratio", dest="stand_ratio", type=float, default=1.0,
                   help="height of this frame's whole figure relative to the standing figure (crawl 0.5, seated 0.65)")
    t.set_defaults(fn=cmd_strip)

    args = ap.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
