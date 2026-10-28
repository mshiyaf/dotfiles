"""Persist and apply safe AniMe Matrix settings through asusctl."""

from __future__ import annotations

import fcntl
import json
import math
import re
import subprocess
import sys
from pathlib import Path

ASUSCTL = "/usr/bin/asusctl"
STATE_FILE = Path.home() / ".local" / "state" / "noctalia" / "anime-matrix.json"
ASUSD_CONFIG = Path("/etc/asusd/anime.ron")
FONTS = {
    "mono": "/usr/share/fonts/TTF/DejaVuSansMono-Bold.ttf",
    "sans": "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf",
    "serif": "/usr/share/fonts/TTF/DejaVuSerif-Bold.ttf",
    "orbitron": "/usr/share/fonts/Orbitron Black.ttf",
    "space-mono": "/usr/share/fonts/noto/NotoSansMono-Bold.ttf",
    "jetbrains": "/usr/share/fonts/TTF/JetBrainsMonoNLNerdFontMono-Bold.ttf",
    "jetbrains-light": "/usr/share/fonts/TTF/JetBrainsMonoNLNerdFont-Thin.ttf",
    "mono-italic": "/usr/share/fonts/TTF/DejaVuSansMono-BoldOblique.ttf",
    "espacion": "/usr/share/fonts/ESPACION.ttf",
}
PRESETS = {
    "rog-static": (
        "Static ROG",
        "image",
        "/usr/share/asusd/anime/asus/rog/Kaleidoscope2.png",
    ),
    "rog-glitch": (
        "ROG Glitch",
        "gif",
        "/usr/share/asusd/anime/asus/rog/ROG glitch.gif",
    ),
    "controller": (
        "Controller",
        "gif",
        "/usr/share/asusd/anime/asus/gaming/Controller.gif",
    ),
    "clock": ("Clock", "image", None),
    "custom-text": ("Custom text", "image", None),
    "custom-image": ("Custom image", "image", None),
}
DEFAULT = {
    "enabled": False,
    "brightness": "low",
    "preset": "rog-static",
    "off_when_unplugged": True,
    "off_when_suspended": True,
    "off_when_lid_closed": True,
    "clock_font": "mono",
    "custom_text": "ROG",
    "custom_font": "mono",
    "clock_rotation": 0,
    "custom_rotation": 0,
    "custom_image": "",
    "scale": 1.0,
    "x": 0.0,
    "y": 0.0,
    "show_date": True,
    "clock_style": "digital",
    "duration": 3.0,
    "scenes": [],
}


def validate(value: dict) -> dict:
    """Validate both quick controls and Studio documents before hardware writes."""
    if value["brightness"] not in {"off", "low", "med", "high"}:
        raise ValueError("invalid brightness")
    if value["preset"] not in PRESETS:
        raise ValueError("invalid preset")
    if value["clock_font"] not in FONTS or value["custom_font"] not in FONTS:
        raise ValueError("invalid font")
    for key, low, high in (
        ("clock_rotation", -360, 360),
        ("custom_rotation", -360, 360),
        ("scale", 0.1, 3),
        ("x", -100, 100),
        ("y", -100, 100),
        ("duration", 0.2, 30),
    ):
        number = value[key]
        if (
            isinstance(number, bool)
            or not isinstance(number, (int, float))
            or not math.isfinite(number)
            or not low <= number <= high
        ):
            raise ValueError(f"invalid {key}: expected {low} to {high}")
    for key in (
        "enabled",
        "off_when_unplugged",
        "off_when_suspended",
        "off_when_lid_closed",
        "show_date",
    ):
        if not isinstance(value[key], bool):
            raise TypeError(f"invalid {key}")
    if value["clock_style"] not in {"digital", "stacked", "rog"}:
        raise ValueError("invalid clock style")
    if not isinstance(value["custom_text"], str) or len(value["custom_text"]) > 128:
        raise ValueError("text must be at most 128 characters")
    if not isinstance(value["custom_image"], str):
        raise TypeError("invalid image path")
    if not isinstance(value["scenes"], list) or len(value["scenes"]) > 12:
        raise ValueError("a sequence supports up to 12 clips")
    for index, scene in enumerate(value["scenes"]):
        if not isinstance(scene, dict) or scene.get("scenes"):
            raise ValueError("invalid sequence clip")
        value["scenes"][index] = validate({**DEFAULT, **scene, "scenes": []})
    return value


def state() -> dict:
    try:
        saved = json.loads(STATE_FILE.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        saved = {}
    current = {**DEFAULT, **{key: saved[key] for key in DEFAULT if key in saved}}
    try:
        config = ASUSD_CONFIG.read_text()
    except OSError:
        return current
    fields = {
        "display_enabled": ("enabled", lambda value: value == "true"),
        "display_brightness": ("brightness", lambda value: value.lower()),
        "off_when_unplugged": ("off_when_unplugged", lambda value: value == "true"),
        "off_when_suspended": ("off_when_suspended", lambda value: value == "true"),
        "off_when_lid_closed": ("off_when_lid_closed", lambda value: value == "true"),
    }
    for config_key, (state_key, parse) in fields.items():
        match = re.search(rf"^\s*{config_key}:\s*([^,\s]+)", config, re.MULTILINE)
        if match:
            current[state_key] = parse(match.group(1))
    return current


def save(value: dict) -> None:
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(value, indent=2) + "\n")


def run(*args: str) -> None:
    result = subprocess.run(
        [ASUSCTL, "anime", *args],
        capture_output=True,
        text=True,
        check=False,
        timeout=15,
    )
    if result.returncode:
        raise RuntimeError((result.stderr or result.stdout or "asusctl failed").strip())


def play(effect: tuple[str, Path] | None) -> None:
    # A GIF CLI owns playback and blocks until its loops finish. Give it one
    # named user unit, so closing Studio does not stop it or leave rival writers.
    stopped = subprocess.run(
        ["systemctl", "--user", "stop", "anime-matrix-playback.service"],
        capture_output=True,
        text=True,
        check=False,
        timeout=15,
    )
    if stopped.returncode and "not loaded" not in stopped.stderr:
        raise RuntimeError(stopped.stderr.strip())
    if effect is None:
        return
    mode, path = effect
    if mode == "pixel-image":
        run(mode, "--path", str(path))
    else:
        result = subprocess.run(
            [
                "systemd-run",
                "--user",
                "--unit=anime-matrix-playback",
                "--collect",
                "--quiet",
                "--",
                ASUSCTL,
                "anime",
                mode,
                "--path",
                str(path),
                "--loops",
                "0",
            ],
            capture_output=True,
            text=True,
            check=False,
            timeout=15,
        )
        if result.returncode:
            raise RuntimeError(
                result.stderr.strip() or "Could not start Matrix playback"
            )


def apply(value: dict) -> None:
    # Render before changing device settings so a bad asset leaves the lid alone.
    effect = export_effect(value) if value["enabled"] else None
    run(
        "--enable-display",
        str(value["enabled"]).lower(),
        "--brightness",
        value["brightness"],
        "--enable-powersave-anim",
        "false",
        "--off-when-unplugged",
        str(value["off_when_unplugged"]).lower(),
        "--off-when-suspended",
        str(value["off_when_suspended"]).lower(),
        "--off-when-lid-closed",
        str(value["off_when_lid_closed"]).lower(),
    )
    if not value["enabled"]:
        play(None)
        run("--clear")
        return
    play(effect)


def export_effect(value: dict) -> tuple[str, Path]:
    from matrix_render import device_model, export

    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    return export(value, device_model(), STATE_FILE.parent)


def main() -> None:
    action = sys.argv[1] if len(sys.argv) > 1 else "status"
    current = state()
    if action == "status":
        print(json.dumps({"ok": True, "state": current}))
        return
    if action == "refresh":
        scenes = current["scenes"] or [current]
        if current["enabled"] and any(scene["preset"] == "clock" for scene in scenes):
            validate(current)
            play(export_effect(current))
        print(json.dumps({"ok": True, "state": current}))
        return
    if action != "apply":
        raise ValueError("unknown action")

    changes = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
    if not isinstance(changes, dict):
        raise TypeError("invalid settings")
    for key, value in changes.items():
        if key in current:
            current[key] = value
    # Choosing a quick preset exits Studio sequence mode; power-only changes do not.
    if "preset" in changes and "scenes" not in changes:
        current["scenes"] = []
    validate(current)

    apply(current)
    save(current)
    print(json.dumps({"ok": True, "state": current}))


if __name__ == "__main__":
    try:
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with STATE_FILE.with_suffix(".lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            main()
    except (
        OSError,
        ValueError,
        TypeError,
        KeyError,
        RuntimeError,
        subprocess.SubprocessError,
    ) as error:
        print(json.dumps({"ok": False, "error": str(error)}))
        sys.exit(1)
