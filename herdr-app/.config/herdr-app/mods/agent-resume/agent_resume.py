#!/usr/bin/env python3
"""Remember which agent session each Herdr terminal runs, and bring them back.

  hook claude|codex|agy   Session hook: note this session on the terminal.
  watch PID TERMINAL      Started by the hook: forget the session if the agent quits.
  resume                  Type the resume command into terminals that lost their agent.
  status                  Show what resume would do, without doing it.
  install-hooks           Add the hook to Codex and Antigravity's machine-local files.

Behaviour follows the "Agent resume" recipe, reduced to these three agents and a
key press. Launch flags are not kept, so resuming can't re-enable a permission
bypass. Standard library only.
"""

import fcntl
import json
import os
import re
import select
import shlex
import shutil
import subprocess
import sys
import time
from pathlib import Path

LABEL = "agent-resume"
RESUME = {
    "claude": ["claude", "--resume"],
    "codex": ["codex", "resume"],
    "agy": ["agy", "--conversation"],
}
AGENT_NAMES = {"claude", "codex", "agy", "antigravity"}
SHELLS = {"bash", "dash", "fish", "ksh", "sh", "zsh"}
SESSION_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{7,127}$")
UNTYPABLE_RE = re.compile(r"['\\\x00-\x1f\x7f]")
HOOK_MARK = "agent_resume.py"
SCRIPT = "~/.config/herdr-app/mods/agent-resume/agent_resume.py"


def runtime_dir():
    base = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
    path = Path(base) / f"herdr-agent-resume-{os.getuid()}"
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    return path


def log(message):
    state = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    path = state / "herdr-agent-resume.log"
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.exists() and path.stat().st_size > 256 * 1024:
            path.write_text("")
        with path.open("a") as out:
            out.write(f"{time.strftime('%F %T')} {message}\n")
    except OSError:
        pass


def hc(*args, timeout=3, plain=False):
    env = dict(os.environ)
    if plain:
        # From inside a terminal, hc send wraps text in an agent-to-agent envelope.
        env.pop("HC_TERMINAL_ID", None)
        env.pop("HC_SCOPE", None)
    return subprocess.run(["hc", *args], capture_output=True, text=True, timeout=timeout, env=env)


def hc_json(*args):
    result = hc(*args, "--json")
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"hc {args[0]} exited {result.returncode}")
    return json.loads(result.stdout)


def boot_id():
    return Path("/proc/sys/kernel/random/boot_id").read_text().strip()


def proc_stat(pid):
    """Return (name, parent pid), reading past spaces and parentheses in the name."""
    text = Path(f"/proc/{pid}/stat").read_text()
    name = text[text.index("(") + 1 : text.rindex(")")]
    return name, int(text[text.rindex(")") + 2 :].split()[1])


def proc_names(pid):
    names = {proc_stat(pid)[0]}
    try:
        argv = Path(f"/proc/{pid}/cmdline").read_bytes().split(b"\0")
    except OSError:
        return names
    # Interpreted launchers (node codex.js) name the agent in the first arguments.
    names.update(os.path.basename(arg.decode(errors="replace")) for arg in argv[:2] if arg)
    return names


def ancestors():
    pid, chain = os.getppid(), []
    while pid > 1:
        chain.append(pid)
        try:
            pid = proc_stat(pid)[1]
        except (OSError, ValueError):
            break
    return chain


def is_nested(below_agent):
    """True if another agent runs under a tool shell of this one (`claude -p` from a tool).

    A launcher and its native binary sit directly on each other, so agent-named
    processes touching the foreground agent are the same agent. `below_agent` runs
    from the hook's parent up to, not including, the foreground agent.
    """
    inside_tool = False
    for pid in reversed(below_agent):
        is_agent = bool(proc_names(pid) & AGENT_NAMES)
        if is_agent and inside_tool:
            return True
        inside_tool = inside_tool or not is_agent
    return False


def read_session(agent, data):
    if agent == "agy":
        folders = data.get("workspacePaths") or []
        return data.get("conversationId"), folders[0] if folders else None, data.get("transcriptPath")
    return data.get("session_id"), data.get("cwd"), data.get("transcript_path")


def note_session(agent):
    terminal = os.environ.get("HC_TERMINAL_ID")
    if not terminal or agent not in RESUME:
        return
    data = json.loads(sys.stdin.read() or "{}")
    session, cwd, transcript = read_session(agent, data)
    if not session or not cwd or not SESSION_RE.match(session):
        return
    if data.get("agent_id"):  # A Claude subagent.
        return
    thread = os.environ.get("CODEX_THREAD_ID")
    if agent == "codex" and thread and thread != session:  # A Codex sub-thread.
        return

    info = hc_json("get", terminal)
    agent_pid = (info.get("foreground") or {}).get("pid")
    chain = ancestors()
    # The agent must be the terminal's foreground program: not inside tmux or ssh.
    if not agent_pid or agent_pid not in chain or info.get("pid") not in chain:
        return
    if is_nested(chain[: chain.index(agent_pid)]):
        return

    label = {
        "agent": agent,
        "session": session,
        "cwd": cwd,
        "transcript": transcript,
        "pid": agent_pid,
        "shell": info["pid"],
        "boot": boot_id(),
        "at": int(time.time()),
    }
    hc("label", terminal, f"{LABEL}={json.dumps(label, separators=(',', ':'))}")
    subprocess.Popen(
        [sys.executable, os.path.realpath(__file__), "watch", str(agent_pid), terminal],
        stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def watch(pid, terminal):
    """Forget the session when the agent quits but its shell lives on."""
    lock = open(runtime_dir() / f"watch-{pid}", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return  # Already watched.
    try:
        wait_for_exit(pid)
        time.sleep(2)
        info = hc_json("get", terminal)
        label = read_label(info)
        if label and label.get("pid") == pid and info.get("state") == "live" and info.get("pid") == label.get("shell"):
            hc("label", terminal, f"{LABEL}=")
    finally:
        (runtime_dir() / f"watch-{pid}").unlink(missing_ok=True)


def wait_for_exit(pid):
    try:
        fd = os.pidfd_open(pid)
    except ProcessLookupError:
        return
    select.select([fd], [], [])
    os.close(fd)


def read_label(info):
    raw = (info.get("labels") or {}).get(LABEL)
    if not raw:
        return None
    try:
        label = json.loads(raw)
    except ValueError:
        return None
    return label if isinstance(label, dict) and label.get("agent") in RESUME else None


def is_lost(label, info):
    return label.get("boot") != boot_id() or label.get("shell") != info.get("pid")


def at_shell(info):
    foreground = info.get("foreground") or {}
    return foreground.get("pid") == info.get("pid") or foreground.get("name") in SHELLS


def place(info):
    return (info.get("labels") or {}).get("where") or info["address"]


def plan():
    """Return (ready, waiting, problems) for every terminal that lost its agent."""
    ready, waiting, problems, seen = [], [], [], set()
    terminals = hc_json("ls")["terminals"]
    infos = [hc_json("get", t["address"]) for t in terminals if "/" not in t["address"]]
    live = {
        (label["agent"], label["session"])
        for info in infos
        if (label := read_label(info)) and not is_lost(label, info)
    }
    labeled = [(read_label(info), info) for info in infos if read_label(info)]
    for label, info in sorted(labeled, key=lambda pair: pair[0].get("at", 0), reverse=True):
        key = (label["agent"], label["session"])
        if not is_lost(label, info) or key in seen or key in live:
            continue
        seen.add(key)
        cwd, transcript = label.get("cwd") or "", label.get("transcript")
        if not SESSION_RE.match(label["session"]):
            problems.append(f"{place(info)}: its session id can't be typed")
        elif not os.path.isdir(cwd):
            problems.append(f"{place(info)}: its folder is gone")
        elif UNTYPABLE_RE.search(cwd):
            problems.append(f"{place(info)}: its folder name can't be typed")
        elif transcript and not os.path.exists(transcript):
            problems.append(f"{place(info)}: no saved conversation")
        elif not info.get("foreground"):
            waiting.append((label, info))
        elif not at_shell(info):
            problems.append(f"{place(info)}: something else is running there")
        else:
            ready.append((label, info))
    return ready, waiting, problems


def resume_command(label):
    words = [*RESUME[label["agent"]], label["session"]]
    return f"cd {shlex.quote(label['cwd'])} && {' '.join(words)}"


def last_line(address):
    result = hc("read", address, plain=True)
    lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    return lines[-2] if len(lines) > 1 else "no output"


def resume():
    lock = open(runtime_dir() / "resume", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return {"busy": True}

    ready, waiting, problems = plan()
    deadline = time.time() + 12
    # Restored shells take a moment to appear.
    while waiting and time.time() < deadline:
        time.sleep(0.5)
        ready, waiting, problems = plan()
    problems += [f"{place(info)}: its shell didn't start" for _, info in waiting]

    if ready:
        time.sleep(1.5)  # Give restored shells time to reach their prompt.
    sent = []
    for label, info in ready:
        result = hc("send", info["address"], resume_command(label), plain=True)
        if result.returncode == 0:
            sent.append((label, info))
        else:
            problems.append(f"{place(info)}: {result.stderr.strip() or 'could not type into it'}")
        time.sleep(0.15)

    resumed = []
    if sent:
        time.sleep(5)
    for label, info in sent:
        current = hc_json("get", info["address"])
        now = read_label(current)
        if at_shell(current) and now and is_lost(now, current):
            problems.append(f"{place(info)}: exited right away: {last_line(info['address'])}")
        else:
            resumed.append(place(info))
    return {"resumed": resumed, "problems": problems}


def status():
    ready, waiting, problems = plan()
    return {
        "would_resume": [f"{place(info)}: {resume_command(label)}" for label, info in ready],
        "waiting": [place(info) for _, info in waiting],
        "problems": problems,
    }


def add_hook(path, update):
    if not path.parent.is_dir():
        return f"skipped {path}: not installed"
    config = json.loads(path.read_text()) if path.exists() else {}
    if HOOK_MARK in json.dumps(config):
        return f"unchanged {path}"
    if path.exists():
        shutil.copy2(path, path.with_name(f"{path.name}.agent-resume-backup"))
    update(config)
    path.write_text(json.dumps(config, indent=2) + "\n")
    return f"updated {path}"


def hook_entry(agent):
    command = f'if [ -n "${{HC_TERMINAL_ID:-}}" ]; then python3 {SCRIPT} hook {agent}; fi'
    return {"type": "command", "command": command, "timeout": 10}


def install_hooks():
    def codex(config):
        # Codex trusts hooks by position, so only ever append.
        config.setdefault("hooks", {}).setdefault("SessionStart", []).append({"hooks": [hook_entry("codex")]})

    def agy(config):
        config[LABEL] = {"SessionStart": [hook_entry("agy")], "PreInvocation": [hook_entry("agy")]}

    home = Path.home()
    return [add_hook(home / ".codex/hooks.json", codex), add_hook(home / ".gemini/config/hooks.json", agy)]


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else ""
    if command == "hook":
        agent = sys.argv[2] if len(sys.argv) > 2 else ""
        # A hook must never get in the agent's way.
        try:
            note_session(agent)
        except Exception as error:  # noqa: BLE001
            log(f"hook {agent}: {error!r}")
        if agent == "agy":
            print("{}")  # Antigravity reads a hook's stdout as JSON.
    elif command == "watch":
        try:
            watch(int(sys.argv[2]), sys.argv[3])
        except Exception as error:  # noqa: BLE001
            log(f"watch: {error!r}")
    elif command == "resume":
        print(json.dumps(resume()))
    elif command == "status":
        print(json.dumps(status(), indent=2))
    elif command == "install-hooks":
        print("\n".join(install_hooks()))
    else:
        print(__doc__, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
