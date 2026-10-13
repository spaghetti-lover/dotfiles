#!/usr/bin/env python3
import fcntl
import json
import os
from pathlib import Path
import subprocess


def herdr(*args):
    return subprocess.run(
        [os.environ["HERDR_BIN_PATH"], *args],
        check=True,
        capture_output=True,
        text=True,
    ).stdout


def index_label(position):
    if position < 1:
        return None
    if position <= 9:
        return str(position)
    if position <= 35:
        return f"M-{chr(ord('a') + position - 10)}"
    return None


def set_label(resource, resource_id, position, tokens):
    label = index_label(position)
    if tokens.get("shortcut") == label:
        return
    change = (
        ["--token", f"shortcut={label}"]
        if label else ["--clear-token", "shortcut"]
    )
    herdr(
        resource, "report-metadata", resource_id,
        "--source", "dotfiles:agent-numbers", *change,
    )


def main():
    # Hooks can overlap, so read and update both lists under one lock.
    state_dir = Path(os.environ["HERDR_PLUGIN_STATE_DIR"])
    state_dir.mkdir(parents=True, exist_ok=True)
    with (state_dir / "refresh.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        agents = json.loads(herdr("agent", "list"))["result"]["agents"]
        for position, agent in enumerate(agents, start=1):
            set_label("pane", agent["pane_id"], position, agent.get("tokens") or {})

        spaces = json.loads(herdr("workspace", "list"))["result"]["workspaces"]
        for space in spaces:
            set_label(
                "workspace", space["workspace_id"], space["number"],
                space.get("tokens") or {},
            )


if __name__ == "__main__":
    main()
