#!/usr/bin/env python3
import os
import re
import subprocess
import tempfile
import tomllib
from pathlib import Path

root = Path(__file__).resolve().parent.parent
home = Path.home()
state = Path(os.environ.get("XDG_STATE_HOME", home / ".local/state"))
owner = state / "agent-skills/profile-owner"
firstmate = home / "firstmate"

if owner.is_file() and owner.stat().st_size:
    print("firstmate-setup: profile is externally managed; 0 files changed")
    raise SystemExit(0)

if not firstmate.exists() and not firstmate.is_symlink():
    subprocess.run(
        [
            os.environ.get("MAC_SETUP_GIT_BIN", "git"),
            "clone",
            "--",
            "https://github.com/kunchenguid/firstmate.git",
            str(firstmate),
        ],
        check=True,
    )
if not (firstmate / "AGENTS.md").is_file():
    raise SystemExit("firstmate-setup: existing path is not a FirstMate checkout; preserved")

assets = [
    (
        root / "home/.codex/mac-firstmate.config.toml",
        Path(os.environ.get("CODEX_HOME", home / ".codex"))
        / "mac-firstmate.config.toml",
    ),
    *[
        (source, firstmate / source.relative_to(root / "home/firstmate"))
        for source in sorted((root / "home/firstmate").rglob("*"))
        if source.is_file()
    ],
]
changed = 0
for source, target in assets:
    if target.exists() or target.is_symlink():
        continue
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("xb") as output:
        output.write(source.read_bytes())
    target.chmod(0o600)
    changed += 1

config = Path(os.environ.get("CODEX_HOME", home / ".codex")) / "config.toml"
current = config.read_text() if config.exists() else ""
settings = tomllib.loads(current)
defaults_text = (root / "home/.codex/config.toml").read_text()
defaults = tomllib.loads(defaults_text)
if settings.get("model", defaults["model"]) == defaults["model"]:
    missing = defaults.keys() - settings.keys()
    additions = "".join(
        line + "\n"
        for line in defaults_text.splitlines()
        if (match := re.match(r"(\w+)\s*=", line)) and match.group(1) in missing
    )
    if additions:
        updated = additions + current
        tomllib.loads(updated)
        config.parent.mkdir(parents=True, exist_ok=True)
        if config.exists():
            backup = state / "mac-setup/codex-before-model-defaults.toml"
            backup.parent.mkdir(parents=True, exist_ok=True)
            if not backup.exists():
                backup.write_text(current)
                backup.chmod(0o600)
        fd, temporary = tempfile.mkstemp(prefix=".model-defaults-", dir=config.parent)
        with os.fdopen(fd, "w") as output:
            output.write(updated)
        os.chmod(temporary, 0o600)
        os.replace(temporary, config)
        changed += 1

print(f"firstmate-setup: {changed} defaults installed; existing preferences preserved")
