# /// script
# requires-python = ">=3.11"
# dependencies = ["tomlkit==0.13.3"]
# ///
"""Reversible Noctalia history/media privacy, without reading clipboard contents."""

import argparse
import fcntl
import json
import os
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path

import tomlkit

PLUGIN = "mshiyaf/privacy"
ALL_PLAYERS = "org.mpris.MediaPlayer2."
STATE = (
    Path(
        os.environ.get("NOCTALIA_STATE_HOME")
        or os.environ.get("XDG_STATE_HOME")
        or Path.home() / ".local/state"
    )
    / "noctalia"
)
SETTINGS = STATE / "settings.toml"
RECOVERY = STATE / "privacy.json"
FIELDS = (("shell", "clipboard_enabled"), ("shell", "mpris", "blacklist"))


def run(*args):
    result = subprocess.run(
        args, capture_output=True, text=True, check=True, timeout=20
    )
    if result.stdout.startswith("error:"):
        raise RuntimeError(result.stdout.strip())
    return result.stdout


def atomic_write(path, text):
    # Preserve a settings symlink, matching Noctalia's own writer.
    path = path.resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as file:
        temporary = Path(file.name)
        try:
            file.write(text)
            file.flush()
            os.fsync(file.fileno())
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)


def get(document, path):
    for key in path:
        if key not in document:
            return None
        document = document[key]
    return document


def put(document, path, value):
    for key in path[:-1]:
        if key not in document:
            document[key] = tomlkit.table()
        document = document[key]
    if value is None:
        document.pop(path[-1], None)
    else:
        document[path[-1]] = value


def other_recorder_running():
    for process in Path("/proc").glob("[0-9]*"):
        try:
            if process.stat().st_uid != os.getuid():
                continue
            args = (process / "cmdline").read_bytes().split(b"\0")
            if (
                args
                and Path(os.fsdecode(args[0])).name == "wl-paste"
                and b"--watch" in args
                and any(b"cliphist" in arg for arg in args)
            ):
                return True
        except (FileNotFoundError, PermissionError, ProcessLookupError):
            continue
    return False


def status(recovery):
    config = tomllib.loads(run("noctalia", "config", "export", "full"))
    enabled = recovery.get("enabled", False)
    protected = (
        enabled
        and get(config, FIELDS[0]) is False
        and ALL_PLAYERS in (get(config, FIELDS[1]) or [])
        and not other_recorder_running()
    )
    return {
        "ok": True,
        "enabled": enabled,
        "protected": protected,
        "error": "Privacy settings were overridden or another recorder is running"
        if enabled and not protected
        else "",
    }


def apply(action, recovery):
    if action == "status":
        return status(recovery)
    enabled = recovery.get("enabled", False)
    desired = not enabled if action == "toggle" else action == "on"
    if not desired and not enabled:
        return status(recovery)
    if desired and other_recorder_running():
        raise RuntimeError(
            "Stop the redundant wl-paste/cliphist recorder before enabling privacy"
        )
    document = tomlkit.parse(SETTINGS.read_text() if SETTINGS.exists() else "")
    if desired:
        if not enabled:
            recovery = {
                "enabled": True,
                "saved": [get(document, path) for path in FIELDS],
            }
            # Write recovery first so a failed reload/restart never loses original settings.
            atomic_write(RECOVERY, json.dumps(recovery))
        put(document, FIELDS[0], False)
        put(document, FIELDS[1], [ALL_PLAYERS])
    else:
        config = tomllib.loads(run("noctalia", "config", "export", "full"))
        if get(config, FIELDS[0]) is not False:
            raise RuntimeError(
                "History was enabled externally. Turn privacy on again before leaving it safely"
            )
        # Disabled history retains one live item in memory. Clear that item BEFORE
        # restoring retention, otherwise it gets merged into the saved history.
        # Own an empty selection: --clear alone lets Noctalia reclaim the old copy.
        # wl-copy's background selection owner must not retain capture pipes.
        subprocess.run(
            ["wl-copy", "--type", "text/plain", ""],
            check=True,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=20,
        )
        run("noctalia", "msg", "clipboard-clear")
        for path, value in zip(FIELDS, recovery["saved"], strict=True):
            put(document, path, value)
    put(document, ("plugin_settings", PLUGIN, "private_mode"), desired)
    # Closing drops the Media tab's cached title/art before filtering players.
    run("noctalia", "msg", "panel-close")
    atomic_write(SETTINGS, tomlkit.dumps(document))
    run("noctalia", "msg", "config-reload")
    if not desired:
        recovery = {"enabled": False}
        atomic_write(RECOVERY, json.dumps(recovery))
    result = status(recovery)
    if desired and not result["protected"]:
        raise RuntimeError(result["error"])
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("status", "on", "off", "toggle"))
    args = parser.parse_args()
    STATE.mkdir(parents=True, exist_ok=True)
    with (STATE / "privacy.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        recovery = (
            json.loads(RECOVERY.read_text())
            if RECOVERY.exists()
            else {"enabled": False}
        )
        try:
            result = apply(args.action, recovery)
        except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
            result = {
                "ok": False,
                "enabled": recovery.get("enabled", False),
                "protected": False,
                "error": str(error),
            }
        print(json.dumps(result))
        return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
