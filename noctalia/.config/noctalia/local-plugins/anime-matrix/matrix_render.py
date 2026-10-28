"""Shared physical LED sampler and asusctl diagonal PNG/GIF exporter.

Mapping follows rog-anime 6.5.0 diagonal.rs and image.rs at upstream commit
ec09e7629da3e4081d9c342e7f323e30158cccfd. PNG coordinates are not lid coordinates.
"""

from __future__ import annotations

import math
from datetime import datetime
from functools import lru_cache
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def device_model() -> str:
    board = Path("/sys/class/dmi/id/board_name").read_text().upper()
    if any(part in board for part in ("GA401I", "GA401Q")):
        return "GA401"
    if any(part in board for part in ("GA402R", "GA402X", "GA402N")):
        return "GA402"
    raise ValueError(f"Unsupported AniMe Matrix board: {board.strip()}")


def pixel_size(model: str) -> tuple[int, int]:
    if model not in {"GA401", "GA402"}:
        raise ValueError(f"Unsupported Matrix model: {model}")
    return 74, 39 if model == "GA402" else 36


@lru_cache(maxsize=2)
def matrix_points(model: str) -> tuple:
    """Return (PNG x, PNG y, physical x, physical y) for each addressable LED."""
    _, height = pixel_size(model)
    points = []
    for row in range(61 if model == "GA402" else 55):
        if model == "GA402":
            x0 = (row + 1) // 2 if row < 12 else row - 5
            bottom = 5 - row // 2 if row < 12 else 0
            length = 34 if row < 12 else 39 - row // 2
            first = 0 if row < 12 else (row + 1) // 2 - 5
            pitch = 0.283 / 0.77
        else:
            x0 = row // 2 if row < 7 else row - 3
            bottom = 3 - (row + 1) // 2 if row < 7 else 0
            length = (32 if row == 0 else 33) if row < 7 else 36 - (row + 1) // 2
            first = 0 if row < 5 else (row + 1) // 2 - 3
            pitch = 0.3 / 0.8
        for column in range(length):
            points.append(
                (
                    x0 + column,
                    height - 1 - bottom - column,
                    first + column - 0.5 * (row % 2),
                    row * pitch,
                )
            )
    return tuple(points)


@lru_cache(maxsize=4)
def asset_frames(path: str, modified: int) -> tuple:
    """Flatten transparency against black and retain GIF timing/disposal."""
    frames, durations = [], []
    with Image.open(path) as source:
        if source.format not in {"PNG", "GIF"}:
            raise ValueError("Choose a PNG image or animated GIF")
        if source.n_frames > 600:
            raise ValueError("Use an animation with at most 600 frames")
        for index in range(source.n_frames):
            source.seek(index)
            frame = source.convert("RGBA")
            frame.thumbnail((256, 160))
            background = Image.new("RGBA", frame.size, (0, 0, 0, 255))
            background.alpha_composite(frame)
            frames.append(background.convert("L"))
            durations.append(max(20, source.info.get("duration", 100)))
    if len(frames) > 1 and sum(durations) > 30000:
        raise ValueError("Use an animation at most 30 seconds long")
    return tuple(frames), tuple(durations)


def source_path(value: dict) -> Path | None:
    from controller import PRESETS

    if value["preset"] in {"clock", "custom-text"}:
        return None
    path = (
        value["custom_image"]
        if value["preset"] == "custom-image"
        else PRESETS[value["preset"]][2]
    )
    if not path:
        raise ValueError("Choose a PNG or GIF asset first")
    return Path(path).expanduser()


@lru_cache(maxsize=16)
def lettering(text: str, font_path: str, style: str, date: str) -> Image.Image:
    font = ImageFont.truetype(font_path, 180)
    small = ImageFont.truetype(font_path, 82)
    lines = text.split(":") if style == "stacked" else [text]
    width = (
        math.ceil(max(*(font.getlength(line) for line in lines), small.getlength(date)))
        + 200
    )
    center = width / 2
    canvas = Image.new("L", (width, 650))
    draw = ImageDraw.Draw(canvas)
    for index, line in enumerate(lines):
        draw.text((center, 150 + index * 185), line, font=font, fill=255, anchor="mm")
    if date:
        draw.text(
            (center, 300 if len(lines) == 1 else 500),
            date,
            font=small,
            fill=235,
            anchor="mm",
        )
    if style == "rog":
        draw.line((100, 240, width - 100, 240), fill=160, width=4)
    return canvas.crop(canvas.getbbox() or (0, 0, 1, 1))


def render(
    value: dict, model: str, elapsed: float = 0, now: datetime | None = None
) -> Image.Image:
    """Sample one design into the exact grayscale raster consumed by pixel-image."""
    from controller import FONTS

    now = now or datetime.now().astimezone()
    path = source_path(value)
    if path is not None:
        frames, durations = asset_frames(str(path), path.stat().st_mtime_ns)
        tick = (elapsed * 1000) % sum(durations)
        index = 0
        while tick >= durations[index] and index < len(frames) - 1:
            tick -= durations[index]
            index += 1
        content = frames[index]
    else:
        clock = value["preset"] == "clock"
        content = lettering(
            now.strftime("%H:%M") if clock else value["custom_text"] or "ROG",
            FONTS[value["clock_font"] if clock else value["custom_font"]],
            value["clock_style"] if clock else "text",
            now.strftime("%a · %d %b").upper() if clock and value["show_date"] else "",
        )
    # Physical units: one horizontal LED pitch, supersampled for antialiasing.
    factor = min(24 / content.width, 11 / content.height) * value["scale"] * 16
    size = (
        max(1, round(content.width * factor)),
        max(1, round(content.height * factor)),
    )
    content = content.resize(size, Image.Resampling.LANCZOS)
    angle = (
        value["clock_rotation"]
        if value["preset"] == "clock"
        else value["custom_rotation"]
    )
    content = content.rotate(-angle, Image.Resampling.BICUBIC, expand=True)
    points = matrix_points(model)
    max_x = max(p[2] for p in points)
    max_y = max(p[3] for p in points)
    center_x = max_x * 0.64 + value["x"] / 100 * max_x
    center_y = max_y * 0.37 + value["y"] / 100 * max_y
    left = center_x * 16 - content.width / 2
    top = center_y * 16 - content.height / 2
    output = Image.new("L", pixel_size(model))
    for x, y, px, py in points:
        sx, sy = round(px * 16 - left), round(py * 16 - top)
        if 0 <= sx < content.width and 0 <= sy < content.height:
            output.putpixel((x, y), content.getpixel((sx, sy)))
    return output


def export(value: dict, model: str, directory: Path) -> tuple[str, Path]:
    """Export a still or 10fps loop; never change hardware from the renderer."""
    from controller import DEFAULT

    scenes = [{**DEFAULT, **scene} for scene in value["scenes"]] or [value]
    animated = bool(value["scenes"])
    for scene in scenes:
        path = source_path(scene)
        if path:
            frames, durations = asset_frames(str(path), path.stat().st_mtime_ns)
            if len(frames) > 1:
                animated = True
                if not value["scenes"]:
                    scene = dict(scene)
                    scene["duration"] = sum(durations) / 1000
                    scenes = [scene]
    if not animated:
        path = directory / "anime-matrix-effect.png"
        render(scenes[0], model).save(path)
        return "pixel-image", path
    frames, timings = [], []
    now = datetime.now().astimezone()
    for scene in scenes:
        remaining = round(scene["duration"] * 1000)
        for index in range(math.ceil(remaining / 100)):
            frames.append(render(scene, model, index / 10, now))
            timing = min(100, remaining)
            timings.append(timing)
            remaining -= timing
    path = directory / "anime-matrix-effect.gif"
    # No transparency + disposal=2 forces full opaque frames in Pillow.
    # asusctl's pixel-gif decoder ignores disposal, so deltas would leave ghosts.
    frames[0].save(
        path,
        save_all=True,
        append_images=frames[1:],
        duration=timings,
        loop=0,
        optimize=False,
        disposal=2,
    )
    return "pixel-gif", path
