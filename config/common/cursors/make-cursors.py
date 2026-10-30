#!/usr/bin/env python3
# Usage: make-cursors.py <styles dir> <icons dir>
# Animated cursor themes of wayland-desktop (XCursor, sizes 24 / 32 / 48), two per style:
#   wd-<style>      the shapes in the colors of the style (theme.json) and a small animated mascot next to the arrow,
#                   the hand and the wait cursors (system: an orb, dev: a robot, ado: a blue rose, tty: a prompt, miku:
#                   twin-tails, photographer: a camera)
#   wd-<style>-art  drawn as art: miku and ado as pixel chibis, a pose for each shape (peeking over the pointer, tapping
#                   with a leek / a microphone, asleep / puffing while it waits, shaken while a window moves, pulling
#                   the resize arrows, arms crossed when it is forbidden); the others draw every shape in the look of
#                   their style, the shape itself animated (system: glass with a light passing over it, dev: green
#                   pixels with a scan line, tty: iris turning to rose, photographer: cream with an amber edge and a
#                   glint; a finger tapping, fingers flexing, arrows stretching, a sign wobbling, a spinner of the style)
import json
import math
import struct
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

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

def xcursor(path: Path, images: list, hot: tuple, delay: int = DELAY, pixel: bool = False) -> None:
    """pixel: pixel art drawn on the 32 grid, kept sharp (its blocks of SCALE pixels) instead of smoothed"""
    chunks = []
    for size in SIZES:
        resample = (Image.NEAREST if size >= 32 else Image.BOX) if pixel else Image.LANCZOS
        for image in images:
            raw = image.resize((size, size), resample).tobytes()
            # premultiplied ARGB, little endian
            pixels = b"".join(struct.pack("<I", (raw[i + 3] << 24) | (raw[i] * raw[i + 3] // 255 << 16)
                                          | (raw[i + 1] * raw[i + 3] // 255 << 8) | (raw[i + 2] * raw[i + 3] // 255))
                              for i in range(0, len(raw), 4))
            header = struct.pack("<9I", 36, 0xFFFD0002, size, 1, size, size, round(hot[0] * size / 32),
                                 round(hot[1] * size / 32), delay if len(images) > 1 else 0)
            chunks.append((size, header + pixels))
    offset = 16 + 12 * len(chunks)
    toc = b""
    for size, data in chunks:
        toc += struct.pack("<3I", 0xFFFD0002, size, offset)
        offset += len(data)
    path.write_bytes(b"Xcur" + struct.pack("<3I", 16, 0x10000, len(chunks)) + toc + b"".join(data for _, data in chunks))

# =========================
# Art cursors of system, dev, tty and photographer: every shape in the look of the style, the shape itself animated
# =========================
ARROW = [(2, 2), (2, 22), (7, 17.5), (10.5, 25), (13.5, 23.6), (10, 16.5), (16.5, 16.5)]
# hot spots of the art shapes that differ from wd-<style>
ART_HOTSPOTS = {"hand2": (11.5, 2), "grab": (16, 16)}

def grid(points: list) -> list:
    return [(x * SCALE, y * SCALE) for x, y in points]

def box(x0: float, y0: float, x1: float, y1: float) -> tuple:
    return (x0 * SCALE, y0 * SCALE, x1 * SCALE, y1 * SCALE)

def rotated(points: list, angle: float, cx: float = 16, cy: float = 16) -> list:
    cos, sin = math.cos(angle), math.sin(angle)
    return [(cx + x * cos - y * sin, cy + x * sin + y * cos) for x, y in points]

def mix(a: tuple, b: tuple, k: float) -> tuple:
    return tuple(round(x + (y - x) * k) for x, y in zip(a, b))

def silhouette(style: str, shape: str, frame: int) -> tuple:
    """(mask, inner lines, fill level) of a shape at a frame: the shape itself moves - the finger taps, the fingers
    flex, the arrows stretch, the sign wobbles, the crosshair breathes, the arrow fills up while it waits, the spinner of
    the style turns"""
    k = frame / FRAMES
    wave = (1 - math.cos(k * 2 * math.pi)) / 2
    mask = Image.new("L", (32 * SCALE, 32 * SCALE), 0)
    d = ImageDraw.Draw(mask)
    lines = []
    level = None
    if shape in ("left_ptr", "left_ptr_watch"):
        d.polygon(grid(ARROW), fill=255)
        if shape == "left_ptr_watch":
            level = (frame + 1) / FRAMES
    elif shape == "hand2":
        press = (0, 0, 0, 0.6, 1.4, 0.6, 0, 0)[frame]
        d.rounded_rectangle(box(9, 2, 14, 17), radius=2.5 * SCALE, fill=255)
        d.rounded_rectangle(box(7.5, 11 + press, 23, 27), radius=4 * SCALE, fill=255)
        d.rounded_rectangle(box(4.5, 15 + press, 10, 22 + press), radius=2.6 * SCALE, fill=255)
        lines = [[(14, 12.5 + press), (14, 17 + press)], [(18.5, 12.5 + press), (18.5, 17 + press)]]
    elif shape == "grab":
        flex = wave * 1.6
        d.rounded_rectangle(box(8, 14, 24, 28), radius=4 * SCALE, fill=255)
        for x, top in ((8.3, 7), (12, 4.5), (15.7, 5), (19.4, 7.5)):
            d.rounded_rectangle(box(x, top + flex, x + 3.4, 17), radius=1.7 * SCALE, fill=255)
        d.polygon(grid(rotated([(-1.8, -4.5), (1.8, -4.5), (1.8, 4.5), (-1.8, 4.5)], -0.7, 7, 19)), fill=255)
    elif shape == "fleur":
        spread = wave * 1.5
        for quarter in range(4):
            arm = [(-1.4, 0), (1.4, 0), (1.4, -8.5 - spread), (4.2, -8.5 - spread), (0, -13.5 - spread),
                   (-4.2, -8.5 - spread), (-1.4, -8.5 - spread)]
            d.polygon(grid(rotated(arm, quarter * math.pi / 2)), fill=255)
    elif shape in AXES:
        out = wave * 1.6
        points = [(-12 - out, 0), (-6 - out, -6), (-6 - out, -2.5), (6 + out, -2.5), (6 + out, -6), (12 + out, 0),
                  (6 + out, 6), (6 + out, 2.5), (-6 - out, 2.5), (-6 - out, 6)]
        d.polygon(grid(rotated(points, math.atan2(AXES[shape][1], AXES[shape][0]))), fill=255)
    elif shape == "not-allowed":
        tilt = math.sin(k * 2 * math.pi) * 0.14
        d.ellipse(box(5, 5, 27, 27), outline=255, width=round(3.6 * SCALE))
        d.polygon(grid(rotated([(-10, -1.8), (10, -1.8), (10, 1.8), (-10, 1.8)], -math.pi / 4 + tilt)), fill=255)
    elif shape == "xterm":
        d.rectangle(box(14.8, 6, 17.2, 26), fill=255)
        d.rounded_rectangle(box(11, 4.5, 21, 7.3), radius=1.2 * SCALE, fill=255)
        d.rounded_rectangle(box(11, 24.7, 21, 27.5), radius=1.2 * SCALE, fill=255)
    elif shape == "crosshair":
        gap = 2.5 + wave * 1.5
        for quarter in range(4):
            d.polygon(grid(rotated([(-1.1, -gap), (1.1, -gap), (1.1, -12.5), (-1.1, -12.5)], quarter * math.pi / 2)),
                      fill=255)
        d.ellipse(box(15, 15, 17, 17), fill=255)
    elif shape == "watch" and style == "tty":
        # the dots of a terminal spinner, the lit one going round
        for i in range(8):
            lit = (i - frame) % 8
            r = (2.6, 2.1, 1.7, 1.4, 1.2, 1.2, 1.2, 1.2)[lit]
            x, y = 16 + math.cos(i * math.pi / 4) * 10, 16 + math.sin(i * math.pi / 4) * 10
            d.ellipse(box(x - r, y - r, x + r, y + r), fill=255)
    elif shape == "watch" and style == "photographer":
        # an aperture turning, one blade a loop
        d.ellipse(box(3.5, 3.5, 28.5, 28.5), outline=255, width=round(2.4 * SCALE))
        for i in range(6):
            a = (k + i) * math.pi / 3
            d.polygon(grid([(16 + math.cos(a) * 10.5, 16 + math.sin(a) * 10.5),
                            (16 + math.cos(a + 1.05) * 10.5, 16 + math.sin(a + 1.05) * 10.5),
                            (16 + math.cos(a + 0.6) * 3.2, 16 + math.sin(a + 0.6) * 3.2)]), fill=255)
            lines.append([(16 + math.cos(a + 0.6) * 3.2, 16 + math.sin(a + 0.6) * 3.2),
                          (16 + math.cos(a + 1.05) * 10.5, 16 + math.sin(a + 1.05) * 10.5)])
    elif shape == "watch":
        d.arc(box(4.5, 4.5, 27.5, 27.5), k * 360, k * 360 + 260, fill=255, width=round(4 * SCALE))
    return mask, lines, level

def skin(style: str, c: dict, mask: Image.Image, frame: int, lines: list, level: float) -> Image.Image:
    """the shape painted in the look of the style: system glass with a glow and a light passing over it, dev green
    pixels with a scan line going down, tty iris turning to rose and back, photographer cream with an amber edge and a
    glint; level: the part filled from the bottom (the rest dim)"""
    size = mask.size
    k = frame / FRAMES
    wave = (1 - math.cos(k * 2 * math.pi)) / 2
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    if style == "dev":
        # 24 cells: pixels of 2 at the 48 shown (the image is 96 wide, 4 a cell, kept sharp by xcursor)
        cells = mask.resize((24, 24), Image.BOX).point(lambda v: 255 if v > 100 else 0)
        image = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        image.paste((4, 7, 5, 255), (0, 0), cells.filter(ImageFilter.MaxFilter(3)).resize((96, 96), Image.NEAREST))
        fill = Image.new("RGBA", (24, 24), c["accent"] + (255,))
        paint = ImageDraw.Draw(fill)
        if level is not None:
            top, bottom = cells.getbbox()[1], cells.getbbox()[3]
            paint.rectangle((0, 0, 23, round(bottom - (bottom - top) * level) - 1), fill=mix(c["accent"], c["bg"], 0.65))
        paint.line((0, frame * 3, 23, frame * 3), fill=mix(c["accent"], (255, 255, 255), 0.55))
        image.paste(fill.resize((96, 96), Image.NEAREST), (0, 0), cells.resize((96, 96), Image.NEAREST))
        return image
    if style == "tty":
        top, bottom, line = mix(c["accent"], c["accent2"], wave), (110, 90, 160), mix(c["accent2"], c["accent"], wave)
    elif style == "photographer":
        top, bottom, line = (250, 246, 238), (214, 204, 186), c["accent"]
    else:
        top, bottom, line = (150, 205, 255), c["accent"], (240, 248, 255)
    edge = mask.filter(ImageFilter.MaxFilter(2 * round(1.4 * SCALE) + 1))
    if style == "system":
        halo = edge.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(5))
        image.paste(c["accent"] + (255,), (0, 0), halo.point(lambda v: round(v * (0.3 + 0.25 * wave))))
    image.paste(line + (255,), (0, 0), edge)
    fill = Image.new("RGBA", size)
    paint = ImageDraw.Draw(fill)
    for y in range(size[1]):
        paint.line(((0, y), (size[0], y)), fill=mix(top, bottom, y / size[1]) + (255,))
    if level is not None:
        y0, y1 = mask.getbbox()[1], mask.getbbox()[3]
        paint.rectangle((0, 0, size[0], y1 - (y1 - y0) * level), fill=mix(top, c["bg"], 0.6) + (255,))
    image.paste(fill, (0, 0), mask)
    draw = ImageDraw.Draw(image)
    for points in lines:
        draw.line(grid(points), fill=line + (255,), width=round(1.1 * SCALE))
    if style in ("system", "photographer"):
        # a light passing over the shape once a loop
        band = Image.new("L", size, 0)
        v = (-0.5 + 2 * k) * size[0] * 2
        ImageDraw.Draw(band).polygon([(v, 0), (v + size[0] * 0.4, 0), (0, v + size[0] * 0.4), (0, v)],
                                     fill=140 if style == "system" else 110)
        image.paste((255, 255, 255, 255) if style == "system" else (255, 238, 205, 255), (0, 0),
                    ImageChops.multiply(band, mask))
    return image

def art_frames(style: str, c: dict, shape: str) -> tuple:
    """(images, hot spot, delay) of a shape of the art theme of system, dev, tty and photographer"""
    images = []
    for frame in range(FRAMES):
        mask, lines, level = silhouette(style, shape, frame)
        images.append(skin(style, c, mask, frame, lines, level))
    return images, ART_HOTSPOTS.get(shape, HOTSPOTS[shape]), DELAY

# =========================
# Chibis of miku and ado (pixel art on the 32 x 32 grid, a pose for each shape)
# =========================
CHIBI = {
    "miku": {"hair": (64, 201, 192), "light": (150, 236, 228), "line": (18, 58, 66), "skin": (255, 236, 224),
             "eye": (24, 160, 168), "pupil": (14, 70, 84), "blush": (255, 150, 170), "tie": (232, 54, 142),
             "cloth": (196, 204, 212), "ledge": (232, 242, 244), "prop": (64, 201, 192), "arrow": (255, 120, 186),
             "slow": 200},
    "ado": {"hair": (42, 56, 136), "light": (88, 122, 220), "shade": (28, 34, 92), "line": (12, 14, 38), "skin": (255, 236, 228),
            "eye": (70, 216, 216), "pupil": (16, 76, 96), "blush": (255, 160, 176), "tie": (74, 116, 236),
            "cloth": (30, 30, 38), "ledge": (40, 44, 60), "prop": (74, 116, 236), "arrow": (150, 206, 255),
            "slow": 140},
}
WHITE = (255, 255, 255)
RED = (228, 50, 62)
MOUTH = (150, 40, 64)
GOLD = (255, 214, 80)
# the pointer of the chibi cursors: O its line, F its fill, L its light edge (the hot spot on the first O)
POINTER = ["O", "OO", "OLO", "OLFO", "OLFFO", "OLFFFO", "OLFFFFO", "OLFFFFFO", "OLFFFFFFO", "OLFFFFOOOO", "OLFOFFO",
           "OLO OFFO", "OO   OFFO", "      OO"]
# the axis of each resize arrow
AXES = {"sb_h_double_arrow": (1, 0), "sb_v_double_arrow": (0, 1), "fd_double_arrow": (1, 1), "bd_double_arrow": (1, -1)}
CHIBI_HOTSPOTS = {"left_ptr": (1, 1), "left_ptr_watch": (1, 1), "hand2": (2, 2)}

class Sprite:
    """A 32 x 32 frame of pixel art: shapes set pixel by pixel, then a dark line around them"""

    def __init__(self) -> None:
        self.image = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.image)

    def rect(self, x0: float, y0: float, x1: float, y1: float, color: tuple) -> None:
        self.draw.rectangle((x0, y0, x1, y1), fill=color)

    def oval(self, cx: float, cy: float, rx: float, ry: float, color: tuple) -> None:
        self.draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=color)

    def poly(self, points: list, color: tuple) -> None:
        self.draw.polygon(points, fill=color)

    def line(self, points: list, color: tuple, width: int = 1) -> None:
        self.draw.line(points, fill=color, width=width)

    def dots(self, points: list, color: tuple) -> None:
        for point in points:
            self.draw.point(point, fill=color)

    def rows(self, x: int, y: int, rows: list, colors: dict) -> None:
        """a small bitmap: one string a row, each letter a color of colors (the others left empty)"""
        for dy, row in enumerate(rows):
            for dx, key in enumerate(row):
                if key in colors:
                    self.draw.point((x + dx, y + dy), fill=colors[key])

    def outline(self, color: tuple) -> None:
        """the dark line around everything drawn until now (the 4 neighbours of each pixel)"""
        pixels = self.image.load()
        ring = [(x, y) for y in range(32) for x in range(32) if not pixels[x, y][3]
                and any(0 <= x + dx < 32 and 0 <= y + dy < 32 and pixels[x + dx, y + dy][3]
                        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
        for point in ring:
            pixels[point] = color + (255,)

    def base(self) -> Image.Image:
        return self.image.resize((32 * SCALE, 32 * SCALE), Image.NEAREST)

def eye(s: Sprite, p: dict, x: int, y: int, w: int, kind: str, side: int, frame: int) -> None:
    """one eye, its top left at (x, y), w wide; side -1 for the left one (its inner side on the right)"""
    if kind == "blink":
        s.line([(x - 1, y + 2), (x + w, y + 2)], p["pupil"])
    elif kind == "sleep":
        s.dots([(x - 1, y + 1)] + [(x + i, y + 2) for i in range(w)] + [(x + w, y + 1)], p["pupil"])
    elif kind == "strain":
        tip, back = (x + w, x - 1) if side < 0 else (x - 1, x + w)
        s.line([(back, y), (tip, y + 1), (back, y + 2)], p["pupil"])
    elif kind == "dizzy":
        ring = [(x - 1, y), (x, y), (x + 1, y), (x + 1, y + 1), (x + 1, y + 2), (x, y + 2), (x - 1, y + 2), (x - 1, y + 1)]
        s.dots(ring, p["pupil"])
        s.dots([ring[(frame * side) % 8]], WHITE)
        s.dots([(x, y + 1)], p["eye"])
    elif kind == "angry":
        inner, outer = (x + w, x - 1) if side < 0 else (x - 1, x + w)
        s.line([(outer, y - 1), (inner, y)], p["pupil"])
        s.rect(x, y + 1, x + w - 1, y + 2, p["eye"])
        s.dots([(inner + side, y + 2)], p["pupil"])
    else:
        s.rect(x, y, x + w - 1, y + 2, p["eye"])
        s.line([(x, y), (x + w - 1, y)], p["pupil"])
        s.dots([(x, y + 1)], WHITE)
        if kind == "wide":
            s.dots([(x + w - 1, y + 2)], WHITE)

def mouth(s: Sprite, cx: int, y: int, kind: str) -> None:
    if kind == "open":
        s.rect(cx - 1, y - 1, cx + 1, y + 1, MOUTH)
        s.dots([(cx, y + 1)], (255, 130, 150))
    elif kind == "shout":
        s.rect(cx - 2, y - 2, cx + 2, y + 1, MOUTH)
        s.rect(cx - 1, y, cx + 1, y + 1, (255, 110, 130))
    elif kind == "pout":
        s.dots([(cx - 1, y), (cx, y + 1), (cx + 1, y)], MOUTH)
    elif kind == "wavy":
        s.dots([(cx - 2, y), (cx - 1, y - 1), (cx, y), (cx + 1, y - 1), (cx + 2, y)], MOUTH)
    elif kind == "flat":
        s.line([(cx - 1, y), (cx + 1, y)], MOUTH)
    elif kind == "o":
        s.dots([(cx, y)], MOUTH)
    else:
        s.dots([(cx - 1, y), (cx, y + 1), (cx + 1, y)], MOUTH)

def head(s: Sprite, who: str, cx: int, cy: int, eyes: str = "open", face: str = "smile", tails: int = 0,
         frame: int = 0, puffed: bool = False) -> None:
    """the chibi head of miku (teal twin tails, two points on top) or ado (long dark blue hair, a bow under the chin),
    the middle of its face at (cx, cy); tails: how far the hair swings"""
    p = CHIBI[who]
    if who == "miku":
        for side in (-1, 1):
            x, y = cx + side * 8, cy - 5
            s.poly([(x, y - 1), (x + side * 4, y + 2), (x + side * 4 + tails, y + 9), (x + side * 3 + tails, y + 13),
                    (x + side + tails, y + 10), (x - side, y + 3)], p["hair"])
            s.line([(x + side * 2, y + 2), (x + side * 2 + tails, y + 9)], p["light"])
        s.oval(cx, cy - 2, 9, 8, p["hair"])
        for side in (-1, 1):
            s.poly([(cx + side * 8, cy - 6), (cx + side * 7, cy - 13), (cx + side * 3, cy - 9)], p["hair"])
            s.dots([(cx + side * 7, cy - 10), (cx + side * 6, cy - 9)], p["light"])
            s.rect(cx + side * 8 - 1, cy - 6, cx + side * 8 + 1, cy - 4, p["tie"])
        s.oval(cx, cy + 1, 7, 6, p["skin"])
        s.rect(cx - 7, cy - 6, cx + 7, cy - 3, p["hair"])
        for x0, x1, tip in ((-7, -3, -6), (-4, 1, -1), (0, 4, 2), (3, 7, 6)):
            s.poly([(cx + x0, cy - 3), (cx + x1, cy - 3), (cx + tip, cy + (1 if tip % 2 == 0 else 0))], p["hair"])
        for side in (-1, 1):
            s.rect(min(cx + side * 7, cx + side * 8), cy - 3, max(cx + side * 7, cx + side * 8), cy + 5, p["hair"])
        s.line([(cx - 5, cy - 6), (cx - 1, cy - 7)], p["light"])
        width, left = 2, cx - 4
    else:
        # the long hair flared over the shoulders, in strands, lighter blue at the ends
        for side in (-1, 1):
            x = cx + side * 7
            s.poly([(x, cy - 4), (x + side * 3, cy - 2), (x + side * 5 + tails, cy + 9), (x + side * 5 + tails, cy + 13),
                    (x + side * 3 + tails, cy + 11), (x + side * 2 + tails, cy + 14), (x + tails, cy + 11),
                    (x - side, cy + 13), (x - side * 2, cy + 6)], p["hair"])
            s.line([(x + side * 2, cy + 1), (x + side * 3 + tails, cy + 9)], p["shade"])
            s.line([(x, cy + 3), (x + tails, cy + 9)], p["shade"])
            for dx, top in ((4, 10), (2, 11), (-1, 11)):
                s.line([(x + side * dx + tails, cy + top), (x + side * dx + tails, cy + top + 2)], p["light"])
        s.oval(cx, cy - 2, 10, 8, p["hair"])
        # the jacket and the bow under the chin, its blue rose in the middle
        s.rect(cx - 5, cy + 7, cx + 5, cy + 9, p["cloth"])
        s.poly([(cx - 4, cy + 6), (cx - 1, cy + 8), (cx - 4, cy + 10)], (140, 140, 152))
        s.poly([(cx + 4, cy + 6), (cx + 1, cy + 8), (cx + 4, cy + 10)], (140, 140, 152))
        s.rect(cx - 1, cy + 7, cx + 1, cy + 9, p["tie"])
        s.oval(cx, cy + 1, 7 if puffed else 6, 6, p["skin"])
        s.rect(cx - 7, cy - 6, cx + 7, cy - 2, p["hair"])
        for x0, x1, tip in ((-7, -3, -5), (-4, 1, -1), (0, 4, 2), (3, 7, 6)):
            s.poly([(cx + x0, cy - 2), (cx + x1, cy - 2), (cx + tip, cy + 1)], p["hair"])
        for side in (-1, 1):
            s.rect(min(cx + side * 6, cx + side * 7), cy - 2, max(cx + side * 6, cx + side * 7), cy + 7, p["hair"])
        # the shine across the top of the head
        s.line([(cx - 6, cy - 5), (cx - 3, cy - 7), (cx + 1, cy - 7)], p["light"])
        s.dots([(cx + 3, cy - 7), (cx + 4, cy - 6)], p["light"])
        width, left = 3, cx - 5
    for side, x in ((-1, left), (1, 2 * cx - left - width + 1)):
        eye(s, p, x, cy + 1, width, eyes, side, frame)
    blush = [(cx - 6, cy + 4), (cx - 5, cy + 4), (cx + 5, cy + 4), (cx + 6, cy + 4)]
    if puffed:
        blush += [(cx - 6, cy + 5), (cx + 6, cy + 5)]
    s.dots(blush, p["blush"])
    mouth(s, cx, cy + 5, face)

def paw(s: Sprite, who: str, x: float, y: float, big: bool = False) -> None:
    s.rect(round(x) - 1, round(y) - 1, round(x) + big, round(y) + big, CHIBI[who]["skin"])

def zed(s: Sprite, x: int, y: int, big: bool) -> None:
    rows = ["XXXX", "  X ", " X  ", "XXXX"] if not big else ["XXXXX", "   X ", "  X  ", " X   ", "XXXXX"]
    s.rows(x, y, rows, {"X": WHITE})

def cloud(s: Sprite, x: float, y: float, r: float) -> None:
    s.oval(x, y, r, r * 0.8, WHITE)
    s.oval(x - r * 0.8, y + r * 0.3, r * 0.7, r * 0.6, WHITE)
    s.oval(x + r * 0.8, y + r * 0.3, r * 0.7, r * 0.6, WHITE)

def star(s: Sprite, x: int, y: int, big: bool) -> None:
    s.dots([(x, y), (x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)], GOLD)
    if big:
        s.dots([(x - 3, y), (x + 3, y), (x, y - 3), (x, y + 3), (x - 2, y - 2), (x + 2, y + 2), (x + 2, y - 2),
                (x - 2, y + 2)], GOLD)

def note(s: Sprite, x: int, y: int, color: tuple) -> None:
    s.rect(x, y + 3, x + 1, y + 4, color)
    s.line([(x + 1, y), (x + 1, y + 3)], color)
    s.dots([(x + 2, y), (x + 3, y + 1)], color)

def sweat(s: Sprite, x: int, y: int) -> None:
    s.dots([(x, y), (x - 1, y + 1), (x, y + 1), (x + 1, y + 1), (x, y + 2)], (150, 210, 255))

def anger(s: Sprite, x: int, y: int) -> None:
    s.dots([(x - 1, y - 2), (x - 1, y - 1), (x - 2, y - 1), (x + 1, y - 2), (x + 1, y - 1), (x + 2, y - 1),
            (x - 1, y + 2), (x - 1, y + 1), (x - 2, y + 1), (x + 1, y + 2), (x + 1, y + 1), (x + 2, y + 1)], RED)

def pointer(s: Sprite, p: dict) -> None:
    s.rows(1, 1, POINTER, {"O": p["line"], "F": p["prop"], "L": p["light"]})

def tap(s: Sprite, who: str, frame: int) -> None:
    """the hand: miku taps with a leek, ado with a microphone, its end on the hot spot"""
    p = CHIBI[who]
    turn = (0, -0.12, -0.24, -0.12, 0, 0, 0, 0)[frame]
    px, py = 15, 16
    vx, vy = -12.5, -13.5
    cos, sin = math.cos(turn), math.sin(turn)
    tx, ty = px + vx * cos - vy * sin, py + vx * sin + vy * cos
    along = lambda k: (tx + (px - tx) * k, ty + (py - ty) * k)
    hit = frame in (4, 5)
    if who == "miku":
        s.line([along(0.55), along(1.3)], (70, 170, 70), 3)
        s.line([along(0.9), (along(1.3)[0] + 3, along(1.3)[1] - 1)], (98, 196, 84), 2)
        s.line([along(0.05), along(0.45)], (248, 252, 242), 3)
        s.line([along(0.42), along(0.58)], (190, 232, 140), 3)
        s.dots([along(0.0)], (210, 196, 160))
    else:
        s.line([along(0.25), along(1.1)], (36, 36, 44), 2)
        s.oval(tx + 1.5, ty + 1.5, 2.5, 2.5, (176, 180, 192))
        s.dots([(round(tx + 1), round(ty + 1)), (round(tx + 2), round(ty + 2))], (110, 114, 126))
    head(s, who, 22, 22, "strain" if hit else ("blink" if frame == 7 else "open"), "open" if hit else
         ("shout" if who == "ado" and frame == 5 else "smile"), (0, 0, -1, -1, 1, 1, 0, 0)[frame], frame)
    paw(s, who, px, py)
    paw(s, who, px + 2, py + 2)
    if hit:
        star(s, 3, 3, frame == 5)
        if who == "ado":
            note(s, 9, 1 + (frame == 5), p["tie"])

def resize(s: Sprite, who: str, axis: tuple, frame: int) -> None:
    """pulling the two ends of the resize arrow"""
    p = CHIBI[who]
    pull = (0, 1, 2, 2, 1, 0, 0, 0)[frame]
    n = math.hypot(*axis)
    ux, uy = axis[0] / n, axis[1] / n
    length = (12.5 if axis[0] and axis[1] else 13) + pull * 0.6
    for side in (-1, 1):
        tip = (15.5 + side * ux * length, 15.5 + side * uy * length)
        base = (tip[0] - side * ux * 4, tip[1] - side * uy * 4)
        s.poly([tip, (base[0] - uy * 3.5, base[1] + ux * 3.5), (base[0] + uy * 3.5, base[1] - ux * 3.5)], p["prop"])
    s.line([(15.5 - ux * length, 15.5 - uy * length), (15.5 + ux * length, 15.5 + uy * length)], p["prop"], 3)
    head(s, who, 16, 17, "strain" if pull else "open", "open" if pull else "flat", 0, frame)
    # the heads of the arrow over her hair, light with a dark edge, her hands holding them
    for side in (-1, 1):
        tip = (15.5 + side * ux * length, 15.5 + side * uy * length)
        base = (tip[0] - side * ux * 5, tip[1] - side * uy * 5)
        s.poly([tip, (base[0] - uy * 4.5, base[1] + ux * 4.5), (base[0] + uy * 4.5, base[1] - ux * 4.5)], p["line"])
        tip = (tip[0] - side * ux * 1.5, tip[1] - side * uy * 1.5)
        base = (tip[0] - side * ux * 2.8, tip[1] - side * uy * 2.8)
        s.poly([tip, (base[0] - uy * 2.6, base[1] + ux * 2.6), (base[0] + uy * 2.6, base[1] - ux * 2.6)], p["arrow"])
        paw(s, who, 15.5 + side * ux * (length - 6), 15.5 + side * uy * (length - 6), True)
    if pull:
        sweat(s, 26, 7)

def chibi_frames(who: str, shape: str) -> tuple:
    """(images, hot spot, delay) of a shape of the chibi theme; None for the crosshair (kept from wd-<style>)"""
    if shape == "crosshair":
        return None
    p = CHIBI[who]
    images = []
    for frame in range(FRAMES):
        s = Sprite()
        swing = (0, 1, 1, 1, 0, -1, -1, -1)[frame]
        arrow = False
        if shape in ("left_ptr", "left_ptr_watch"):
            # peeking over a ledge under the pointer; waiting: asleep (miku) or puffing (ado)
            waiting = shape == "left_ptr_watch"
            cy = 19 + (frame in (3, 4, 5))
            if waiting and who == "miku":
                head(s, who, 20, cy, "sleep", "o", swing, frame)
                zed(s, 26, 8 - frame % 4, False)
            elif waiting:
                head(s, who, 20, cy, "angry", "pout", swing, frame, True)
                cloud(s, 11.5 - frame % 4 * 0.5, 9 - frame % 4 * 0.5, 1.5 + frame % 4 * 0.4)
                cloud(s, 29 + frame % 4 * 0.5, 9 - frame % 4 * 0.5, 1.5 + frame % 4 * 0.4)
            else:
                head(s, who, 20, cy, "blink" if frame == 6 else "open", "smile", swing, frame)
            s.rect(10, 27, 31, 30, p["ledge"])
            s.line([(10, 27), (31, 27)], p["prop"])
            paw(s, who, 15, 27)
            paw(s, who, 26, 27)
            arrow = True
        elif shape == "hand2":
            tap(s, who, frame)
        elif shape == "watch":
            if who == "miku":
                # asleep on her arms, a bubble growing, the z going up
                cy = 16 + (frame in (2, 3, 4, 5))
                head(s, who, 16, cy, "sleep", "o", swing // 2, frame)
                s.rect(5, 26, 27, 29, p["cloth"])
                paw(s, who, 11, 26)
                paw(s, who, 22, 26)
                r = (0, 1, 1, 2, 2, 3, 1, 0)[frame]
                if r:
                    s.draw.ellipse((19 - r, cy + 6 - r, 19 + r, cy + 6 + r), fill=(205, 240, 255))
                zed(s, 24, 7 - frame % 4, False)
                zed(s, 27, 1 + (frame % 4 > 1), True)
            else:
                # the angry puff: cheeks full, steam out of both sides
                head(s, who, 16, 17, "angry", "pout", 0, frame, True)
                k = frame % 4
                cloud(s, 6 - k * 0.7, 8 - k * 0.6, 1.8 + k * 0.5)
                cloud(s, 26 + k * 0.7, 8 - k * 0.6, 1.8 + k * 0.5)
                if frame % 4 < 2:
                    anger(s, 26, 19)
        elif shape in ("fleur", "grab"):
            if shape == "fleur":
                # shaken while a window moves: dizzy, the hair flying the other way
                dx = (0, 2, 0, -2)[frame % 4]
                head(s, who, 16 + dx, 17, "dizzy", "wavy", -dx, frame)
                if dx:
                    x = 3 if dx > 0 else 28
                    s.line([(x, 11), (x, 15)], WHITE)
                    s.line([(x, 18), (x, 22)], WHITE)
            else:
                # ready to grab: both hands up
                head(s, who, 16, 17, "wide", "open", swing, frame)
                up = frame % 4 < 2
                paw(s, who, 8, 24 - 2 * up, True)
                paw(s, who, 23, 24 - 2 * (not up), True)
        elif shape in AXES:
            resize(s, who, AXES[shape], frame)
        elif shape == "not-allowed":
            s.draw.ellipse((1, 1, 30, 30), outline=RED, width=2)
            s.line([(6, 25), (25, 6)], RED, 2)
            shake = (0, 1, 0, -1)[frame % 4]
            head(s, who, 16 + shake, 15, "angry", "shout" if who == "ado" else "pout", -shake, frame)
            s.line([(10 + shake, 22), (22 + shake, 27)], p["cloth"], 2)
            s.line([(10 + shake, 27), (22 + shake, 22)], p["cloth"], 2)
            paw(s, who, 10 + shake, 22)
            paw(s, who, 23 + shake, 22)
            if frame % 4 < 2:
                anger(s, 25, 6)
        elif shape == "xterm":
            if who == "miku":
                for side in (-1, 1):
                    x = 16 + side * 5
                    s.poly([(x, 4), (x + side * 3, 7), (x + side * 3 + swing, 13), (x + side + swing, 15), (x, 7)], p["hair"])
                    s.rect(x - 1, 3, x + 1, 5, p["tie"])
            s.rect(15, 5, 16, 26, p["hair"])
            s.rect(11, 4, 20, 5, p["hair"])
            s.rect(11, 26, 20, 27, p["hair"])
            if who == "ado":
                s.oval(15.5, 3, 2.5, 2.5, p["tie"])
                s.dots([(15, 3), (16, 2)], (190, 212, 255))
        s.outline(p["line"])
        if arrow:
            pointer(s, p)
        images.append(s.base())
    hot = CHIBI_HOTSPOTS.get(shape, (16, 16))
    return images, hot, p["slow"] if shape == "watch" else 120

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

# The art theme: its own shapes (miku and ado: all but the crosshair, kept from wd-<style> by Inherits)
def art_theme(style_dir: Path, icons: Path) -> None:
    data = json.loads((style_dir / "theme.json").read_text())
    c = {key: rgb(data[key]) for key in ("bg", "fg", "accent", "accent2", "urgent")}
    folder = icons / f"wd-{style_dir.name}-art" / "cursors"
    folder.mkdir(parents=True, exist_ok=True)
    chibi = style_dir.name in CHIBI
    for shape, aliases in ALIASES.items():
        made = chibi_frames(style_dir.name, shape) if chibi else art_frames(style_dir.name, c, shape)
        if not made:
            continue
        images, hot, delay = made
        xcursor(folder / shape, images, hot, delay, chibi or style_dir.name == "dev")
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
