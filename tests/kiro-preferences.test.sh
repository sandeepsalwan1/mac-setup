#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

python3 - "$ROOT" <<'PY'
import json
import os
from pathlib import Path
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
nix = (root / "home.nix").read_text()
body = nix.split("mergeKiroSettings = preferences: target: ''\n", 1)[1].split("\n  '';", 1)[0]
jq = shlex.quote(shutil.which("jq"))

def activate(target, preferences):
    script = body.replace("${lib.escapeShellArg target}", shlex.quote(str(target)))
    script = script.replace("${preferences}", shlex.quote(str(preferences)))
    script = script.replace("${pkgs.jq}/bin/jq", jq)
    return subprocess.run(["bash", "-eu", "-c", script], capture_output=True, text=True)

with tempfile.TemporaryDirectory(prefix="kiro-preferences-") as directory:
    home = Path(directory)
    for name, relative in [
        ("ide", "Library/Application Support/Kiro/User/settings.json"),
        ("cli", ".kiro/settings/cli.json"),
    ]:
        preferences = root / "home/kiro" / f"{name}-settings.json"
        desired = json.loads(preferences.read_text())
        target = home / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        original = {"theme": "keep", "custom": {"nested": True}}
        original.update({key: not value if isinstance(value, bool) else "old" for key, value in desired.items()})
        if name == "ide":
            original["kiroAgent.configureMCP"] = "Enabled"
        target.write_text(json.dumps(original))
        before = target.read_bytes()
        assert activate(target, preferences).returncode == 0
        installed = json.loads(target.read_text())
        if name == "ide":
            assert installed["kiroAgent.configureMCP"] == "Disabled"
        assert installed["theme"] == "keep" and installed["custom"] == {"nested": True}
        assert all(installed[key] == value for key, value in desired.items())
        backup = Path(str(target) + ".pre-mac-setup")
        assert backup.read_bytes() == before
        assert stat.S_IMODE(target.stat().st_mode) == 0o600
        assert stat.S_IMODE(backup.stat().st_mode) == 0o600
        unchanged = target.stat().st_mtime_ns
        assert activate(target, preferences).returncode == 0
        assert target.stat().st_mtime_ns == unchanged and backup.read_bytes() == before
        target.write_text("{broken")
        assert activate(target, preferences).returncode != 0
        assert target.read_text() == "{broken" and backup.read_bytes() == before
        assert not list(target.parent.glob(target.name + ".mac-setup.*"))
        target.unlink()
        assert activate(target, preferences).returncode == 0
        assert json.loads(target.read_text()) == desired

    permissions = nix.split('home.activation.kiroPermissions = lib.hm.dag.entryAfter [ "linkGeneration" ] \'\'\n', 1)[1].split("\n  '';", 1)[0]
    permissions = permissions.replace("${./home/kiro/permissions.yaml}", shlex.quote(str(root / "home/kiro/permissions.yaml")))
    target = home / ".kiro/settings/permissions.yaml"
    previous = "rules:\n  - capability: all\n    effect: allow\n"
    target.write_text(previous)
    env = {**os.environ, "HOME": str(home)}
    assert subprocess.run(["bash", "-eu", "-c", permissions], env=env).returncode == 0
    assert target.read_bytes() == (root / "home/kiro/permissions.yaml").read_bytes()
    assert Path(str(target) + ".pre-mac-setup").read_text() == previous
    assert stat.S_IMODE(target.stat().st_mode) == 0o600
    unchanged = target.stat().st_mtime_ns
    assert subprocess.run(["bash", "-eu", "-c", permissions], env=env).returncode == 0
    assert target.stat().st_mtime_ns == unchanged
    custom = "rules:\n  - capability: all\n    effect: deny\n"
    target.write_text(custom)
    assert subprocess.run(["bash", "-eu", "-c", permissions], env=env).returncode == 0
    assert target.read_text() == custom
    assert Path(str(target) + ".pre-mac-setup").read_text() == previous

print("ok - portable Kiro activation preserves custom settings, backs up privately, and is idempotent")
PY
