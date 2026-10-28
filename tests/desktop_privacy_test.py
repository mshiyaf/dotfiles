"""Privacy CLI contract, using a disposable clipboard and shell transport."""

import json
import os
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTROLLER = ROOT / "noctalia/.config/noctalia/local-plugins/privacy/controller.py"
TRANSPORT = """#!/usr/bin/env python3
import json, os, pathlib, sys, tomllib
root = pathlib.Path(os.environ["XDG_STATE_HOME"]) / "noctalia"
path = root / "transport.json"
state = json.loads(path.read_text())
settings = tomllib.loads((root / "settings.toml").read_text())
shell = settings.get("shell", {})
enabled = shell.get("clipboard_enabled", True)
args = sys.argv[1:]
if pathlib.Path(sys.argv[0]).name == "wl-copy":
    # Noctalia can reclaim the selection when --clear removes its owner.
    if "--clear" not in args:
        state["selection"] = ""
elif args[:2] == ["config", "export"]:
    print('[shell]\\nclipboard_enabled = ' + str(enabled).lower())
    print('[shell.mpris]\\nblacklist = ' + json.dumps(shell.get("mpris", {}).get("blacklist", [])))
elif args[:2] == ["msg", "config-reload"]:
    if enabled:
        state["history"] += state["live"]
        if state["selection"]:
            state["history"].append(state["selection"])
    state["enabled"] = enabled
elif args[:2] == ["msg", "clipboard-clear"]:
    state["live"] = []
    if state["enabled"]:
        state["history"] = []
elif args[:2] != ["msg", "panel-close"]:
    sys.exit(1)
path.write_text(json.dumps(state))
"""


class DesktopPrivacyTests(unittest.TestCase):
    def test_private_text_and_images_never_enter_saved_history_after_resume(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            state = root / "noctalia"
            state.mkdir()
            (root / "bin").mkdir()
            settings = state / "settings.toml"
            settings.write_text(
                '# Keep this comment.\n[shell]\nfont_family = "Noto Sans"\n'
                '[shell.mpris]\nblacklist = ["old-player"]\n'
            )
            for command in ("noctalia", "wl-copy"):
                executable = root / "bin" / command
                executable.write_text(TRANSPORT)
                executable.chmod(0o755)
            env = {
                **os.environ,
                "XDG_STATE_HOME": str(root),
                "NOCTALIA_STATE_HOME": str(root),
                "PATH": f"{root / 'bin'}:{os.environ['PATH']}",
            }
            transport = state / "transport.json"
            transport.write_text(
                json.dumps(
                    {
                        "history": ["saved earlier"],
                        "live": [],
                        "selection": "saved earlier",
                        "enabled": True,
                    }
                )
            )

            def run(action, check=True):
                result = subprocess.run(
                    ["uv", "run", "--script", str(CONTROLLER), action],
                    env=env,
                    text=True,
                    capture_output=True,
                    check=check,
                )
                return json.loads(result.stdout)

            self.assertFalse(run("status")["enabled"])
            self.assertTrue(run("on")["protected"])
            data = json.loads(transport.read_text())
            self.assertFalse(data["enabled"])
            data["live"] = ["private text", "private image/png"]
            data["selection"] = "private text"
            transport.write_text(json.dumps(data))
            run("on")
            self.assertEqual(
                json.loads(transport.read_text())["selection"], "private text"
            )

            # A GUI change must be reported as a protection failure, not a green tile.
            original = settings.read_text()
            settings.write_text(
                original.replace(
                    "clipboard_enabled = false", "clipboard_enabled = true"
                )
            )
            self.assertFalse(run("status")["protected"])
            self.assertFalse(run("off", check=False)["ok"])
            settings.write_text(original)
            self.assertTrue(run("status")["protected"])

            # Keep unrelated settings changed while private, including their comments.
            settings.write_text(settings.read_text() + '\n[theme]\nmode = "light"\n')
            self.assertFalse(run("off")["enabled"])
            data = json.loads(transport.read_text())
            self.assertTrue(data["enabled"])
            self.assertEqual(data["selection"], "")
            self.assertEqual(data["history"], ["saved earlier"])
            restored = tomllib.loads(settings.read_text())
            self.assertNotIn("clipboard_enabled", restored["shell"])
            self.assertEqual(restored["shell"]["mpris"]["blacklist"], ["old-player"])
            self.assertEqual(restored["theme"]["mode"], "light")
            self.assertIn("# Keep this comment.", settings.read_text())
            run("off")
            self.assertEqual(
                json.loads(transport.read_text())["history"], ["saved earlier"]
            )


if __name__ == "__main__":
    unittest.main()
