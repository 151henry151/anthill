#!/usr/bin/env python3
"""Regenerate boot / loading splash PNGs (side-view ant + dunes + sky). Run from repo: python3 tools/generate_splash_assets.py"""
from __future__ import annotations

import math
import os
import sys

from PIL import Image, ImageDraw

# Paths relative to this script (game/anthill/tools/)
_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_OUT = os.path.join(_ROOT, "assets", "splash")


def _sky_gradient(px, w: int, h: int, y0: int) -> None:
    for y in range(y0):
        t = y / max(y0 - 1, 1)
        r = int(95 + t * 55)
        g = int(130 + t * 60)
        b = int(195 + t * 35)
        for x in range(w):
            px[x, y] = (r, g, b)


def _sand_base(draw: ImageDraw.ImageDraw, w: int, h: int, sand_top: int) -> None:
    draw.rectangle([0, sand_top, w - 1, h - 1], fill=(218, 186, 128))
    for k in range(10):
        cx = int(w * (0.05 + k * 0.09))
        cy = sand_top + 20 + (k % 3) * 10
        rw, rh = 100 + k * 12, 35 + (k % 2) * 14
        draw.ellipse([cx - rw // 2, cy - rh // 2, cx + rw // 2, cy + rh // 2], fill=(200, 165, 105))


def _mound(draw: ImageDraw.ImageDraw, mx: int, my: int) -> None:
    for layer in range(5):
        ly = my + layer * 14
        rw = 90 - layer * 12
        rh = 28
        draw.ellipse([mx - rw, ly, mx + rw, ly + rh], fill=(190, 155, 95))


def _leg(
    draw: ImageDraw.ImageDraw,
    attach: tuple[float, float],
    knee: tuple[float, float],
    foot: tuple[float, float],
    width: int,
    color: tuple[int, int, int],
) -> None:
    draw.line([attach, knee], fill=color, width=width)
    draw.line([knee, foot], fill=color, width=max(1, width - 1))


def draw_ant_profile(
    draw: ImageDraw.ImageDraw,
    hx: float,
    hy: float,
    s: float,
    facing: float = 1.0,
) -> None:
    """Side-view hymenopteran worker: gaster → petiole → thorax → head; six legs; geniculate antennae."""
    fx = facing  # +1 head right
    body = (22, 22, 24)
    leg_c = (16, 16, 18)
    ant_c = (14, 14, 16)

    # Gaster (metasoma)
    draw.ellipse(
        _ell(hx - 52 * s * fx, hy - 10 * s, hx - 6 * s * fx, hy + 20 * s),
        fill=body,
        outline=(10, 10, 12),
    )
    # Petiole (pinched waist)
    draw.ellipse(
        _ell(hx - 10 * s * fx, hy - 3 * s, hx + 10 * s * fx, hy + 8 * s),
        fill=body,
    )
    # Thorax + propodeum
    draw.ellipse(
        _ell(hx + 4 * s * fx, hy - 10 * s, hx + 48 * s * fx, hy + 16 * s),
        fill=body,
        outline=(10, 10, 12),
    )
    # Head
    draw.ellipse(
        _ell(hx + 44 * s * fx, hy - 8 * s, hx + 78 * s * fx, hy + 14 * s),
        fill=body,
        outline=(10, 10, 12),
    )
    # Compound eye (simple highlight)
    ex = hx + 62 * s * fx
    ey = hy + 1 * s
    draw.ellipse(_ell(ex - 5 * s, ey - 4 * s, ex + 2 * s, ey + 5 * s), fill=(48, 48, 52))

    # Mandibles
    mx = hx + 76 * s * fx
    draw.polygon(
        [
            (mx, hy + 2 * s),
            (mx + 10 * s * fx, hy - 2 * s),
            (mx + 8 * s * fx, hy + 6 * s),
        ],
        fill=body,
    )

    # Antennae: scape + elbow + funiculus
    base_x = hx + 70 * s * fx
    base_y = hy - 4 * s
    scape_end = (base_x + 14 * s * fx, base_y - 10 * s)
    draw.line([(base_x, base_y), scape_end], fill=ant_c, width=max(1, int(3 * s)))
    fun_end = (scape_end[0] + 18 * s * fx, base_y - 22 * s)
    draw.line([scape_end, fun_end], fill=ant_c, width=max(1, int(2 * s)))

    base_x2 = hx + 66 * s * fx
    scape2 = (base_x2 + 10 * s * fx, base_y + 2 * s)
    draw.line([(base_x2, base_y + 4 * s), scape2], fill=ant_c, width=max(1, int(2 * s)))
    draw.line([scape2, (scape2[0] + 14 * s * fx, base_y - 8 * s)], fill=ant_c, width=max(1, int(2 * s)))

    # Six legs (profile: overlapping pairs; clear front / mid / hind)
    sg = 1.0 if fx > 0 else -1.0
    # Hind (on gaster)
    _leg(draw, (hx - 32 * s * fx, hy + 12 * s), (hx - 48 * s * fx, hy + 28 * s), (hx - 38 * s * fx, hy + 42 * s), 3, leg_c)
    # Mid
    _leg(draw, (hx + 8 * s * fx, hy + 14 * s), (hx - 8 * s * fx, hy + 30 * s), (hx + 2 * s * fx, hy + 44 * s), 3, leg_c)
    # Front (thorax)
    _leg(draw, (hx + 28 * s * fx, hy + 12 * s), (hx + 12 * s * fx, hy + 28 * s), (hx + 22 * s * fx, hy + 42 * s), 3, leg_c)
    # Other side (slightly offset for depth)
    _leg(draw, (hx - 22 * s * fx, hy + 10 * s), (hx - 36 * s * fx, hy + 24 * s), (hx - 28 * s * fx, hy + 40 * s), 2, leg_c)
    _leg(draw, (hx + 18 * s * fx, hy + 11 * s), (hx + 4 * s * fx, hy + 26 * s), (hx + 14 * s * fx, hy + 40 * s), 2, leg_c)
    _leg(draw, (hx + 38 * s * fx, hy + 8 * s), (hx + 28 * s * fx, hy + 22 * s), (hx + 38 * s * fx, hy + 36 * s), 2, leg_c)


def _ell(x1: float, y1: float, x2: float, y2: float) -> tuple[float, float, float, float]:
    if x1 > x2:
        x1, x2 = x2, x1
    if y1 > y2:
        y1, y2 = y2, y1
    return (x1, y1, x2, y2)


def render(size: tuple[int, int], ant_scale: float, ant_xy: tuple[float, float]) -> Image.Image:
    w, h = size
    im = Image.new("RGB", (w, h))
    px = im.load()
    sand_top = int(h * 0.52)
    _sky_gradient(px, w, h, sand_top)
    dr = ImageDraw.Draw(im)
    _sand_base(dr, w, h, sand_top)
    _mound(dr, int(w * 0.72), sand_top + 8)
    draw_ant_profile(dr, ant_xy[0], ant_xy[1], ant_scale, 1.0)
    dr.rectangle([0, sand_top, w - 1, h - 1], outline=(180, 150, 95), width=2)
    return im


def render_2x(size: tuple[int, int], ant_scale: float, pos: tuple[float, float]) -> Image.Image:
    w2, h2 = size[0] * 2, size[1] * 2
    big = render((w2, h2), ant_scale * 2.0, (pos[0] * 2, pos[1] * 2))
    return big.resize(size, Image.Resampling.LANCZOS)


def main() -> None:
    os.makedirs(_OUT, exist_ok=True)
    boot = render_2x((960, 540), 1.15, (280.0, 288.0))
    hero = render_2x((640, 360), 0.95, (200.0, 198.0))
    boot.save(os.path.join(_OUT, "anthill_boot.png"), "PNG")
    hero.save(os.path.join(_OUT, "anthill_hero.png"), "PNG")
    print("Wrote:", os.path.join(_OUT, "anthill_boot.png"))
    print("Wrote:", os.path.join(_OUT, "anthill_hero.png"))


if __name__ == "__main__":
    main()
