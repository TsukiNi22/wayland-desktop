#!/usr/bin/env python3
# Usage: make-cursors.py <styles dir> <icons dir>
# Animated cursor themes of wayland-desktop (wd-<style>, XCursor, sizes 24 / 32 / 48): the shapes in the colors of the
# style (theme.json) and a small animated mascot of the style next to the arrow, the hand and the wait cursors
# (system: an orb, dev: a robot, ado: a blue rose, tty: a prompt, miku: twin-tails, photographer: a camera)
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

def main() -> None:
    styles, icons = Path(sys.argv[1]), Path(sys.argv[2])
    for style_dir in sorted(p for p in styles.iterdir() if (p / "theme.json").exists()):
        theme(style_dir, icons)

if __name__ == "__main__":
    main()
