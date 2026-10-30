#!/usr/bin/env python3
# Usage: make-cursors.py <styles dir> <icons dir>
# Animated cursor themes of wayland-desktop (XCursor, sizes 24 / 32 / 48), two per style:
#   wd-<style>      the shapes in the colors of the style (theme.json) and a small animated mascot next to the arrow,
#                   the hand and the wait cursors (system: an orb, dev: a robot, ado: a blue rose, tty: a prompt, miku:
#                   twin-tails, photographer: a camera)
#   wd-<style>-art  the pointer, the hand and the wait cursors drawn as art, like emojis (miku: a leek and her chibi face,
#                   ado: a blue rose and rose-chan, system: glass and a ring, dev: pixels and a block cursor, tty:
#                   rose-pine and a prompt, photographer: cream and an aperture), the other shapes in its colors
import json
import math
import struct
import sys
from pathlib import Path

from PIL import Image, ImageDraw

SIZES = (24, 32, 48)
SCALE = 4
FRAMES = 8
DELAY = 110

# aliases of each drawn shape (the names apps ask for)
ALIASES = {
    "left_ptr": ["default", "arrow", "top_left_arrow", "left_arrow"],
    "hand2": ["pointer", "hand", "hand1", "pointing_hand", "e29285e634086352946a0e7090d73106"],
    "xterm": ["text", "ibeam", "vertical-text"],
    "watch": ["wait"],
    "left_ptr_watch": ["progress", "half-busy", "08e8e1c95fe2fc01f976f1e063a24ccd"],
    "fleur": ["move", "all-scroll", "grabbing", "closedhand", "dnd-move", "size_all"],
    "grab": ["openhand", "grab"],
    "sb_h_double_arrow": ["col-resize", "ew-resize", "e-resize", "w-resize", "h_double_arrow", "size_hor", "right_side",
                          "left_side", "split_h"],
    "sb_v_double_arrow": ["row-resize", "ns-resize", "n-resize", "s-resize", "v_double_arrow", "size_ver", "top_side",
                          "bottom_side", "split_v"],
    "fd_double_arrow": ["nwse-resize", "nw-resize", "se-resize", "size_fdiag", "top_left_corner", "bottom_right_corner"],
    "bd_double_arrow": ["nesw-resize", "ne-resize", "sw-resize", "size_bdiag", "top_right_corner", "bottom_left_corner"],
    "crosshair": ["cross", "tcross", "cell"],
    "not-allowed": ["crossed_circle", "no-drop", "forbidden", "circle"],
}

def rgb(color: str) -> tuple:
    color = color.lstrip("#")
    return tuple(int(color[i:i + 2], 16) for i in (0, 2, 4))

# =========================
# Shapes (drawn on a 32 x 32 grid, scaled)
# =========================
def poly(draw: ImageDraw.ImageDraw, points: list, fill: tuple, outline: tuple, width: int = 2) -> None:
    points = [(x * SCALE, y * SCALE) for x, y in points]
    draw.polygon(points, fill=fill, outline=outline, width=width * SCALE)

def arrow(draw: ImageDraw.ImageDraw, c: dict) -> None:
    poly(draw, [(2, 2), (2, 22), (7, 17.5), (10.5, 25), (13.5, 23.6), (10, 16.5), (16.5, 16.5)], c["bg"], c["accent"])

def hand(draw: ImageDraw.ImageDraw, c: dict) -> None:
    s = SCALE
    draw.rounded_rectangle((8 * s, 2 * s, 12 * s, 16 * s), radius=2 * s, fill=c["bg"], outline=c["accent"], width=2 * s)
    draw.rounded_rectangle((6 * s, 12 * s, 21 * s, 25 * s), radius=4 * s, fill=c["bg"], outline=c["accent"], width=2 * s)
    for x in (13, 16.5):
        draw.line(((x * s, 13 * s), (x * s, 17 * s)), fill=c["accent"], width=2 * s)

def ibeam(draw: ImageDraw.ImageDraw, c: dict) -> None:
    s = SCALE
    for width, color in ((5, c["bg"]), (2, c["accent"])):
        draw.line(((16 * s, 6 * s), (16 * s, 26 * s)), fill=color, width=width * s)
        draw.line(((11 * s, 6 * s), (21 * s, 6 * s)), fill=color, width=width * s)
        draw.line(((11 * s, 26 * s), (21 * s, 26 * s)), fill=color, width=width * s)

def double_arrow(draw: ImageDraw.ImageDraw, c: dict, angle: float) -> None:
    shape = [(-12, 0), (-6, -6), (-6, -2.5), (6, -2.5), (6, -6), (12, 0), (6, 6), (6, 2.5), (-6, 2.5), (-6, 6)]
    cos, sin = math.cos(angle), math.sin(angle)
    poly(draw, [(16 + x * cos - y * sin, 16 + x * sin + y * cos) for x, y in shape], c["bg"], c["accent"])

def fleur(draw: ImageDraw.ImageDraw, c: dict) -> None:
    double_arrow(draw, c, 0)
    double_arrow(draw, c, math.pi / 2)

def crosshair(draw: ImageDraw.ImageDraw, c: dict) -> None:
    s = SCALE
    for width, color in ((5, c["bg"]), (2, c["accent"])):
        for a, b in (((16, 4), (16, 12)), ((16, 20), (16, 28)), ((4, 16), (12, 16)), ((20, 16), (28, 16))):
            draw.line(((a[0] * s, a[1] * s), (b[0] * s, b[1] * s)), fill=color, width=width * s)

def forbidden(draw: ImageDraw.ImageDraw, c: dict) -> None:
    s = SCALE
    draw.ellipse((5 * s, 5 * s, 27 * s, 27 * s), fill=c["bg"], outline=c["urgent"], width=3 * s)
    draw.line(((9 * s, 23 * s), (23 * s, 9 * s)), fill=c["urgent"], width=3 * s)

# =========================
# Mascots (centered on cx, cy, size r, animated by frame 0-7)
# =========================
def mascot(draw: ImageDraw.ImageDraw, style: str, c: dict, cx: float, cy: float, r: float, frame: int) -> None:
    s = SCALE
    k = frame / FRAMES * 2 * math.pi
    bob = math.sin(k) * r * 0.12
    cx, cy, r = cx * s, (cy + bob) * s, r * s
    eye = max(1, r * 0.13)

    def eyes(y: float, color: tuple = (255, 255, 255)) -> None:
        for dx in (-0.32, 0.32):
            draw.ellipse((cx + dx * r - eye, y - eye, cx + dx * r + eye, y + eye), fill=color)

    if style == "ado":
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=c["accent"], outline=(11, 26, 92), width=s)
        for i in range(3):
            q = r * (0.75 - i * 0.22)
            draw.arc((cx - q, cy - q - r * 0.15, cx + q, cy + q - r * 0.15), 30 + i * 60 + frame * 20, 280 + i * 60 + frame * 20,
                     fill=(11, 26, 92), width=max(1, s))
        eyes(cy + r * 0.35)
    elif style == "miku":
        swing = math.sin(k) * r * 0.5
        for side in (-1, 1):
            draw.line(((cx + side * r * 0.8, cy - r * 0.3), (cx + side * (r * 1.3 + swing * side), cy + r * 1.4)),
                      fill=c["accent"], width=int(r * 0.55))
        draw.ellipse((cx - r * 0.85, cy - r * 0.85, cx + r * 0.85, cy + r * 0.85), fill=(240, 220, 210))
        draw.chord((cx - r * 0.9, cy - r * 0.95, cx + r * 0.9, cy + r * 0.5), 180, 360, fill=c["accent"])
        eyes(cy + r * 0.15, c["accent"])
    elif style == "dev":
        draw.rounded_rectangle((cx - r, cy - r * 0.8, cx + r, cy + r), radius=r * 0.25, fill=c["bg"], outline=c["accent"], width=s)
        draw.line(((cx, cy - r * 0.8), (cx, cy - r * 1.4)), fill=c["accent"], width=s)
        light = c["accent2"] if frame % 4 < 2 else c["bg"]
        draw.ellipse((cx - r * 0.25, cy - r * 1.65, cx + r * 0.25, cy - r * 1.15), fill=light)
        eyes(cy + r * 0.05, c["accent"])
    elif style == "tty":
        draw.rounded_rectangle((cx - r * 1.2, cy - r * 0.8, cx + r * 1.2, cy + r * 0.8), radius=r * 0.3, fill=c["bg"],
                               outline=c["accent"], width=s)
        draw.line(((cx - r * 0.7, cy - r * 0.35), (cx - r * 0.3, cy), (cx - r * 0.7, cy + r * 0.35)), fill=c["accent2"],
                  width=max(1, s))
        if frame % 4 < 2:
            draw.rectangle((cx, cy + r * 0.2, cx + r * 0.6, cy + r * 0.38), fill=c["fg"])
    elif style == "photographer":
        draw.rounded_rectangle((cx - r * 1.1, cy - r * 0.6, cx + r * 1.1, cy + r * 0.8), radius=r * 0.2, fill=c["bg"],
                               outline=c["accent"], width=s)
        draw.rectangle((cx - r * 0.4, cy - r * 0.85, cx + r * 0.2, cy - r * 0.6), fill=c["accent"])
        draw.ellipse((cx - r * 0.45, cy - r * 0.35, cx + r * 0.45, cy + r * 0.55), outline=c["accent"], width=s)
        if frame == 0:
            draw.ellipse((cx + r * 0.55, cy - r * 0.55, cx + r * 0.95, cy - r * 0.15), fill=(255, 255, 230))
    else:
        glow = int(80 + 80 * (1 + math.sin(k)) / 2)
        draw.ellipse((cx - r * 1.2, cy - r * 1.2, cx + r * 1.2, cy + r * 1.2), fill=c["accent"] + (glow,))
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=c["accent"])
        draw.ellipse((cx - r * 0.55, cy - r * 0.6, cx - r * 0.1, cy - r * 0.2), fill=(255, 255, 255, 180))
        eyes(cy + r * 0.25, c["bg"])

# =========================
# XCursor files
# =========================
def frames(style: str, c: dict, shape: str, hot: tuple) -> list:
    """List of (32 x 32 base image, delay) for a shape, animated when a mascot comes with it"""
    animated = shape in ("left_ptr", "hand2", "watch", "left_ptr_watch")
    images = []
    for frame in range(FRAMES if animated else 1):
        image = Image.new("RGBA", (32 * SCALE, 32 * SCALE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image, "RGBA")
        if shape == "watch":
            mascot(draw, style, c, 16, 16, 8, frame)
        else:
            {"left_ptr": arrow, "left_ptr_watch": arrow, "hand2": hand, "xterm": ibeam, "fleur": fleur, "grab": hand,
             "crosshair": crosshair, "not-allowed": forbidden,
             "sb_h_double_arrow": lambda d, c: double_arrow(d, c, 0),
             "sb_v_double_arrow": lambda d, c: double_arrow(d, c, math.pi / 2),
             "fd_double_arrow": lambda d, c: double_arrow(d, c, math.pi / 4),
             "bd_double_arrow": lambda d, c: double_arrow(d, c, -math.pi / 4)}[shape](draw, c)
            if animated:
                mascot(draw, style, c, 24.5, 24.5, 4.5 if shape != "left_ptr_watch" else 5, frame)
        images.append(image)
    return images

def xcursor(path: Path, images: list, hot: tuple) -> None:
    chunks = []
    for size in SIZES:
        for image in images:
            raw = image.resize((size, size), Image.LANCZOS).tobytes()
            # premultiplied ARGB, little endian
            pixels = b"".join(struct.pack("<I", (raw[i + 3] << 24) | (raw[i] * raw[i + 3] // 255 << 16)
                                          | (raw[i + 1] * raw[i + 3] // 255 << 8) | (raw[i + 2] * raw[i + 3] // 255))
                              for i in range(0, len(raw), 4))
            header = struct.pack("<9I", 36, 0xFFFD0002, size, 1, size, size, round(hot[0] * size / 32),
                                 round(hot[1] * size / 32), DELAY if len(images) > 1 else 0)
            chunks.append((size, header + pixels))
    offset = 16 + 12 * len(chunks)
    toc = b""
    for size, data in chunks:
        toc += struct.pack("<3I", 0xFFFD0002, size, offset)
        offset += len(data)
    path.write_bytes(b"Xcur" + struct.pack("<3I", 16, 0x10000, len(chunks)) + toc + b"".join(data for _, data in chunks))

# =========================
# Art cursors (drawn on the same 32 x 32 grid)
# =========================
ARROW = [(2, 2), (2, 22), (7, 17.5), (10.5, 25), (13.5, 23.6), (10, 16.5), (16.5, 16.5)]

def grid(points: list) -> list:
    return [(x * SCALE, y * SCALE) for x, y in points]

def gradient_polygon(image: Image.Image, points: list, top: tuple, bottom: tuple, outline: tuple,
                     width: float = 1.5) -> None:
    """A polygon filled with a vertical gradient (top to bottom of the grid), outlined"""
    size = image.size
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).polygon(grid(points), fill=255)
    shade = Image.new("RGBA", size)
    shading = ImageDraw.Draw(shade)
    for y in range(size[1]):
        k = y / size[1]
        shading.line(((0, y), (size[0], y)), fill=tuple(int(a + (b - a) * k) for a, b in zip(top, bottom)) + (255,))
    image.paste(shade, (0, 0), mask)
    ImageDraw.Draw(image, "RGBA").polygon(grid(points), outline=outline, width=round(width * SCALE))

def glow(image: Image.Image, points: list, color: tuple) -> None:
    ImageDraw.Draw(image, "RGBA").polygon(grid(points), outline=color + (70,), width=4 * SCALE)

def blob(draw: ImageDraw.ImageDraw, cx: float, cy: float, rx: float, ry: float, fill: tuple, outline=None,
         width: float = 1) -> None:
    draw.ellipse(((cx - rx) * SCALE, (cy - ry) * SCALE, (cx + rx) * SCALE, (cy + ry) * SCALE), fill=fill,
                 outline=outline, width=round(width * SCALE) if outline else 0)

def stroke(draw: ImageDraw.ImageDraw, points: list, color: tuple, width: float) -> None:
    draw.line(grid(points), fill=color, width=max(1, round(width * SCALE)), joint="curve")
    for x, y in (points[0], points[-1]):
        blob(draw, x, y, width / 2, width / 2, color)

def leek(draw: ImageDraw.ImageDraw, x0: float, y0: float, x1: float, y1: float, frame: int) -> None:
    """A leek from its white root (x0, y0) to its green leaves (x1, y1), the leaves swaying"""
    dx, dy = x1 - x0, y1 - y0
    along = lambda k, side=0.0: (x0 + dx * k - dy * side, y0 + dy * k + dx * side)
    sway = math.sin(frame / FRAMES * 2 * math.pi) * 0.12
    # the outline, then the white stalk, its light green middle, the leaves
    stroke(draw, [along(0), along(0.62)], (24, 70, 48), 6.2)
    for i, spread in enumerate((-0.16, 0.02, 0.2)):
        tip = along(1.0, spread + sway * (1 + i * 0.4))
        stroke(draw, [along(0.58), along(0.8, spread * 0.6 + sway * 0.5), tip], (24, 70, 48), 4.6)
    stroke(draw, [along(0.02), along(0.42)], (248, 252, 242), 4.4)
    stroke(draw, [along(0.4), along(0.6)], (190, 232, 140), 4.4)
    for i, spread in enumerate((-0.16, 0.02, 0.2)):
        tip = along(1.0, spread + sway * (1 + i * 0.4))
        stroke(draw, [along(0.58), along(0.8, spread * 0.6 + sway * 0.5), tip], (70, 170, 70) if i != 1 else (98, 196, 84), 2.8)
    for side in (-0.05, 0.05):
        stroke(draw, [along(0, 0), along(-0.06, side)], (210, 196, 160), 0.8)

def note(draw: ImageDraw.ImageDraw, x: float, y: float, size: float, color: tuple) -> None:
    blob(draw, x, y, size * 0.55, size * 0.42, color)
    stroke(draw, [(x + size * 0.45, y), (x + size * 0.45, y - size * 1.5), (x + size * 1.1, y - size * 1.1)], color, size * 0.32)

def chibi(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, frame: int) -> None:
    """Miku as an emoji: her face, her bangs, her twin tails swinging, the pink ties"""
    teal, dark, pink = (57, 197, 187), (16, 96, 92), (225, 40, 133)
    swing = math.sin(frame / FRAMES * 2 * math.pi) * r * 0.25
    for side in (-1, 1):
        stroke(draw, [(cx + side * r * 0.75, cy - r * 0.35), (cx + side * (r * 1.15 + swing * side), cy + r * 0.6),
                      (cx + side * (r * 1.05 + swing * side * 1.4), cy + r * 1.35)], dark, r * 0.62)
        stroke(draw, [(cx + side * r * 0.75, cy - r * 0.35), (cx + side * (r * 1.15 + swing * side), cy + r * 0.6),
                      (cx + side * (r * 1.05 + swing * side * 1.4), cy + r * 1.35)], teal, r * 0.42)
        blob(draw, cx + side * r * 0.78, cy - r * 0.38, r * 0.2, r * 0.2, pink)
    blob(draw, cx, cy, r, r, (255, 236, 226), dark, 0.9)
    # the bangs, three points over the forehead
    draw.chord(((cx - r) * SCALE, (cy - r) * SCALE, (cx + r) * SCALE, (cy + r * 0.2) * SCALE), 180, 360, fill=teal)
    for k in (-0.55, 0, 0.55):
        draw.polygon(grid([(cx + (k - 0.28) * r, cy - r * 0.42), (cx + (k + 0.28) * r, cy - r * 0.42), (cx + k * r, cy + r * 0.05)]),
                     fill=teal)
    blink = frame == 5
    for side in (-1, 1):
        if blink:
            stroke(draw, [(cx + side * r * 0.5 - r * 0.15, cy + r * 0.25), (cx + side * r * 0.5 + r * 0.15, cy + r * 0.25)], dark, r * 0.1)
        else:
            blob(draw, cx + side * r * 0.42, cy + r * 0.25, r * 0.17, r * 0.24, (24, 140, 136))
            blob(draw, cx + side * r * 0.42 - r * 0.05, cy + r * 0.17, r * 0.06, r * 0.06, (255, 255, 255))
    stroke(draw, [(cx - r * 0.14, cy + r * 0.6), (cx, cy + r * 0.68), (cx + r * 0.14, cy + r * 0.6)], pink, r * 0.09)

def rose(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, turn: float) -> None:
    """A blue rose seen from above: rings of petals lighter toward the heart, a spiral bud, turning with turn"""
    for ring, (count, size, color) in enumerate(((6, 1.0, (24, 46, 150)), (5, 0.74, (52, 96, 220)), (3, 0.5, (120, 160, 250)))):
        for i in range(count):
            a = turn * (1 + ring * 0.6) + i * 2 * math.pi / count + ring * 0.5
            px, py = cx + math.cos(a) * r * size * 0.5, cy + math.sin(a) * r * size * 0.5
            blob(draw, px, py, r * size * 0.42, r * size * 0.42, color, (12, 26, 92), 0.5)
    blob(draw, cx, cy, r * 0.24, r * 0.24, (190, 212, 255))
    draw.arc(((cx - r * 0.2) * SCALE, (cy - r * 0.2) * SCALE, (cx + r * 0.2) * SCALE, (cy + r * 0.2) * SCALE),
             math.degrees(turn), math.degrees(turn) + 270, fill=(30, 60, 170), width=max(1, round(r * 0.08 * SCALE)))

def rose_chan(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, frame: int) -> None:
    """rose-chan as an emoji: the blue face of the Ado emotes, its rose on top, blinking"""
    blob(draw, cx, cy, r, r, (91, 140, 255), (11, 26, 92), 0.9)
    blob(draw, cx - r * 0.3, cy - r * 0.35, r * 0.35, r * 0.25, (198, 220, 255, 150))
    rose(draw, cx - r * 0.55, cy - r * 0.85, r * 0.55, frame * 0.3)
    for side in (-1, 1):
        if frame in (4, 5):
            stroke(draw, [(cx + side * r * 0.4 - r * 0.15, cy + r * 0.15), (cx + side * r * 0.4 + r * 0.15, cy + r * 0.15)],
                   (11, 26, 92), r * 0.1)
        else:
            blob(draw, cx + side * r * 0.4, cy + r * 0.12, r * 0.14, r * 0.2, (11, 26, 92))
        blob(draw, cx + side * r * 0.62, cy + r * 0.45, r * 0.16, r * 0.1, (255, 150, 200, 140))
    stroke(draw, [(cx - r * 0.2, cy + r * 0.48), (cx, cy + r * 0.6), (cx + r * 0.2, cy + r * 0.48)], (11, 26, 92), r * 0.09)

def tip(draw: ImageDraw.ImageDraw, color: tuple, outline: tuple) -> None:
    """the small point of the art hand cursors (their hot spot, top left)"""
    draw.polygon(grid([(2, 2), (10, 5), (5, 10)]), fill=color, outline=outline, width=SCALE)

def spinner(draw: ImageDraw.ImageDraw, style: str, c: dict, cx: float, cy: float, r: float, frame: int) -> None:
    """the wait animation of the art theme"""
    k = frame / FRAMES * 2 * math.pi
    if style == "miku":
        leek(draw, cx - math.cos(k) * r, cy - math.sin(k) * r, cx + math.cos(k) * r, cy + math.sin(k) * r, frame)
        for i, color in enumerate(((225, 40, 133), (57, 197, 187))):
            a = -k + i * math.pi
            note(draw, cx + math.cos(a) * r * 0.95, cy + math.sin(a) * r * 0.95, r * 0.28, color)
    elif style == "ado":
        rose(draw, cx, cy, r, k)
    elif style == "dev":
        draw.rectangle(((cx - r) * SCALE, (cy - r * 0.8) * SCALE, (cx + r) * SCALE, (cy + r * 0.8) * SCALE),
                       fill=(4, 7, 5), outline=c["accent"], width=SCALE)
        a = (frame % 4) * math.pi / 4
        stroke(draw, [(cx - math.cos(a) * r * 0.5, cy - math.sin(a) * r * 0.5), (cx + math.cos(a) * r * 0.5, cy + math.sin(a) * r * 0.5)],
               c["accent"], r * 0.18)
    elif style == "tty":
        for i in range(8):
            a = i / 8 * 2 * math.pi
            lit = (i - frame) % 8
            color = c["accent"] if lit == 0 else (c["accent2"] if lit < 3 else c["fg"])
            blob(draw, cx + math.cos(a) * r * 0.7, cy + math.sin(a) * r * 0.7, r * (0.2 if lit == 0 else 0.13),
                 r * (0.2 if lit == 0 else 0.13), color + ((255,) if lit < 3 else (110,)))
    elif style == "photographer":
        blob(draw, cx, cy, r, r, (20, 18, 16), c["accent"], 1)
        for i in range(6):
            a = k * 0.5 + i * math.pi / 3
            draw.polygon(grid([(cx + math.cos(a) * r * 0.9, cy + math.sin(a) * r * 0.9),
                               (cx + math.cos(a + 1.2) * r * 0.9, cy + math.sin(a + 1.2) * r * 0.9),
                               (cx + math.cos(a + 0.6) * r * 0.25, cy + math.sin(a + 0.6) * r * 0.25)]),
                         fill=(60, 52, 40), outline=c["accent"], width=max(1, SCALE // 2))
    else:
        draw.arc(((cx - r) * SCALE, (cy - r) * SCALE, (cx + r) * SCALE, (cy + r) * SCALE), math.degrees(k), math.degrees(k) + 250,
                 fill=c["accent"], width=round(r * 0.3 * SCALE))
        draw.arc(((cx - r * 0.55) * SCALE, (cy - r * 0.55) * SCALE, (cx + r * 0.55) * SCALE, (cy + r * 0.55) * SCALE),
                 -math.degrees(k) * 1.5, -math.degrees(k) * 1.5 + 200, fill=c["accent2"], width=round(r * 0.22 * SCALE))

def art_pointer(image: Image.Image, draw: ImageDraw.ImageDraw, style: str, c: dict, frame: int) -> None:
    if style == "miku":
        leek(draw, 2.6, 2.6, 27, 27, frame)
        if frame % 4 < 2:
            note(draw, 25, 11, 3, (225, 40, 133))
    elif style == "ado":
        gradient_polygon(image, ARROW, (60, 100, 230), (16, 30, 110), (170, 200, 255))
        rose(draw, 21, 21, 7.5, frame / FRAMES * math.pi * 0.5)
    elif style == "dev":
        # a pixel arrow, then the block cursor of a terminal blinking next to it
        rows = ["X", "XX", "XGX", "XGGX", "XGGGX", "XGGGGX", "XGGGGGX", "XGGGGGGX", "XGGGGXXXX", "XGGXGX", "XGX XGX",
                "XX  XGX", "X    XX"]
        for y, row in enumerate(rows):
            for x, cell in enumerate(row):
                if cell != " ":
                    draw.rectangle(((2 + x * 1.8) * SCALE, (2 + y * 1.8) * SCALE, (3.8 + x * 1.8) * SCALE, (3.8 + y * 1.8) * SCALE),
                                   fill=(4, 7, 5) if cell == "X" else c["accent"])
        if frame % 4 < 2:
            draw.rectangle((20 * SCALE, 20 * SCALE, 26 * SCALE, 28 * SCALE), fill=c["accent"])
    elif style == "tty":
        gradient_polygon(image, ARROW, c["accent"], (154, 120, 200), c["accent2"])
        stroke(draw, [(19, 20), (23, 23.5), (19, 27)], c["accent2"] if frame % 4 < 2 else c["fg"], 2)
    elif style == "photographer":
        gradient_polygon(image, ARROW, (250, 246, 238), (214, 204, 186), c["accent"])
        blob(draw, 22, 23, 3, 3, (217, 76, 60) if frame % 4 < 2 else (90, 40, 30))
    else:
        glow(image, ARROW, c["accent"])
        gradient_polygon(image, ARROW, (150, 205, 255), c["accent"], (240, 248, 255))

def art_hand(image: Image.Image, draw: ImageDraw.ImageDraw, style: str, c: dict, frame: int) -> None:
    if style == "miku":
        tip(draw, (57, 197, 187), (16, 96, 92))
        chibi(draw, 17, 16, 8.5, frame)
    elif style == "ado":
        tip(draw, (91, 140, 255), (11, 26, 92))
        rose_chan(draw, 17.5, 17.5, 9, frame)
    else:
        art_pointer(image, draw, style, c, frame)
        draw.ellipse((17 * SCALE, 17 * SCALE, 29 * SCALE, 29 * SCALE), outline=c["accent"], width=SCALE)

def art_frames(style: str, c: dict, shape: str) -> list:
    """The art shapes (animated: the pointer, the hand, the wait cursors); None for the shapes kept from wd-<style>"""
    if shape not in ("left_ptr", "hand2", "watch", "left_ptr_watch"):
        return None
    images = []
    for frame in range(FRAMES):
        image = Image.new("RGBA", (32 * SCALE, 32 * SCALE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image, "RGBA")
        if shape == "watch":
            spinner(draw, style, c, 16, 16, 11, frame)
        elif shape == "hand2":
            art_hand(image, draw, style, c, frame)
        else:
            art_pointer(image, draw, style, c, frame)
            if shape == "left_ptr_watch":
                spinner(draw, style, c, 24, 24, 5.5, frame)
        images.append(image)
    return images

ART_HOTSPOTS = {"left_ptr": (2, 2), "left_ptr_watch": (2, 2), "hand2": (2, 2), "watch": (16, 16)}

HOTSPOTS = {"left_ptr": (2, 2), "left_ptr_watch": (2, 2), "hand2": (10, 2), "grab": (13, 13), "xterm": (16, 16),
            "watch": (16, 16), "fleur": (16, 16), "crosshair": (16, 16), "not-allowed": (16, 16),
            "sb_h_double_arrow": (16, 16), "sb_v_double_arrow": (16, 16), "fd_double_arrow": (16, 16),
            "bd_double_arrow": (16, 16)}

def theme(style_dir: Path, icons: Path) -> None:
    data = json.loads((style_dir / "theme.json").read_text())
    c = {key: rgb(data[key]) for key in ("bg", "fg", "accent", "accent2", "urgent")}
    folder = icons / f"wd-{style_dir.name}" / "cursors"
    folder.mkdir(parents=True, exist_ok=True)
    for shape, aliases in ALIASES.items():
        xcursor(folder / shape, frames(style_dir.name, c, shape, HOTSPOTS[shape]), HOTSPOTS[shape])
        for alias in aliases:
            link = folder / alias
            if link.is_symlink() or link.exists():
                link.unlink()
            if alias != shape:
                link.symlink_to(shape)
    (folder.parent / "index.theme").write_text(f"[Icon Theme]\nName=wd-{style_dir.name}\n"
                                               f"Comment=wayland-desktop {data['name']} cursors\nInherits=Adwaita\n")

# The art theme: its own pointer, hand and wait cursors, the other shapes from wd-<style> (Inherits)
def art_theme(style_dir: Path, icons: Path) -> None:
    data = json.loads((style_dir / "theme.json").read_text())
    c = {key: rgb(data[key]) for key in ("bg", "fg", "accent", "accent2", "urgent")}
    folder = icons / f"wd-{style_dir.name}-art" / "cursors"
    folder.mkdir(parents=True, exist_ok=True)
    for shape, aliases in ALIASES.items():
        images = art_frames(style_dir.name, c, shape)
        if not images:
            continue
        xcursor(folder / shape, images, ART_HOTSPOTS[shape])
        for alias in aliases:
            link = folder / alias
            if link.is_symlink() or link.exists():
                link.unlink()
            if alias != shape:
                link.symlink_to(shape)
    (folder.parent / "index.theme").write_text(f"[Icon Theme]\nName=wd-{style_dir.name}-art\n"
                                               f"Comment=wayland-desktop {data['name']} art cursors\n"
                                               f"Inherits=wd-{style_dir.name}\n")

def main() -> None:
    styles, icons = Path(sys.argv[1]), Path(sys.argv[2])
    for style_dir in sorted(p for p in styles.iterdir() if (p / "theme.json").exists()):
        theme(style_dir, icons)
        art_theme(style_dir, icons)

if __name__ == "__main__":
    main()
