#!/usr/bin/env python3
"""Focus the Agent or Space sidebar entry assigned an M-letter label."""

import argparse
import json
import os
import subprocess


def herdr(*args):
    return subprocess.run(
        [os.environ.get("HERDR_BIN_PATH", "herdr"), *args],
        check=True,
        capture_output=True,
        text=True,
    ).stdout


def focus_letter(resource, letter):
    position = 10 + ord(letter) - ord("a")
    if resource == "agent":
        agents = json.loads(herdr("agent", "list"))["result"]["agents"]
        if len(agents) < position:
            return
        target = agents[position - 1]["pane_id"]
    else:
        spaces = json.loads(herdr("workspace", "list"))["result"]["workspaces"]
        target = next(
            (space["workspace_id"] for space in spaces if space["number"] == position),
            None,
        )
        if target is None:
            return
    herdr(resource, "focus", target)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("resource", choices=("agent", "workspace"))
    parser.add_argument("letter", choices=tuple("abcdefghijklmnopqrstuvwxyz"))
    args = parser.parse_args()
    focus_letter(args.resource, args.letter)


if __name__ == "__main__":
    main()
