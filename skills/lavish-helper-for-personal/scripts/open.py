#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Open a local or server Lavish artifact in Mac Chrome.")
    parser.add_argument("file", type=Path, nargs="?")
    parser.add_argument("--cli", nargs=argparse.REMAINDER, help="run a Lavish command with this machine's server settings")
    parser.add_argument("--no-open", action="store_true", help="prepare and check the session without opening a tab")
    parser.add_argument("--reopen", action="store_true", help="reopen a review the user ended")
    parser.add_argument("--config", type=Path, default=Path.home() / ".config/lavish-helper.json")
    args = parser.parse_args()

    try:
        config = json.loads(args.config.read_text()) if args.config.exists() else {}
        if not isinstance(config, dict):
            raise ValueError("The helper configuration must be a JSON object.")
        server_port = config.get("server_port")
        if server_port is not None and (
            type(server_port) is not int or not 0 < server_port < 65536
        ):
            raise ValueError("server_port must be a TCP port number.")
        executable = shutil.which("lavish-axi")
        command = [executable] if executable else ["npx", "-y", "lavish-axi"]
        environment = dict(os.environ, LAVISH_AXI_HOST="127.0.0.1", LAVISH_AXI_LINK_HOST="127.0.0.1")
        if server_port is not None:
            environment["LAVISH_AXI_PORT"] = str(server_port)
        if args.cli:
            return subprocess.run([*command, *args.cli], env=environment).returncode
        if args.file is None:
            parser.error("Provide an HTML file or --cli followed by a Lavish command.")
        artifact = args.file.expanduser().resolve(strict=True)
        if not artifact.is_file():
            raise ValueError("The artifact must be an HTML file.")
        browser_command = config.get("browser_command")
        if browser_command is None and sys.platform == "darwin":
            browser_command = ["open", "-g", "-a", "Google Chrome"]
        if not args.no_open and (
            not isinstance(browser_command, list)
            or not browser_command
            or any(not isinstance(item, str) or not item for item in browser_command)
        ):
            raise ValueError("Configure the Mac browser_command in ~/.config/lavish-helper.json.")
        browser_base = config.get("browser_base_url")
        if browser_base is not None:
            base = urllib.parse.urlsplit(browser_base)
            if (
                base.scheme != "http"
                or base.hostname not in ("localhost", "127.0.0.1")
                or not base.port
                or base.username is not None
                or base.password is not None
                or base.path not in ("", "/")
                or base.query
                or base.fragment
            ):
                raise ValueError("browser_base_url must be the Mac's loopback HTTP tunnel URL.")

        command.extend([str(artifact), "--no-open"])
        if args.reopen:
            command.append("--reopen")
        launched = subprocess.run(command, env=environment, text=True, capture_output=True, timeout=45)
        if launched.returncode:
            print((launched.stderr or launched.stdout).strip(), file=sys.stderr)
            return launched.returncode
        if re.search(r'(?m)^\s*status:\s*["\']?user-ended\b', launched.stdout):
            print(launched.stdout.rstrip(), file=sys.stderr)
            return 3
        match = re.search(
            r'(?m)^\s*url:\s*["\']?(http://(?:127\.0\.0\.1|localhost):\d+/session/[A-Za-z0-9_-]+)',
            launched.stdout,
        )
        if match is None:
            raise ValueError("Lavish did not return a loopback session URL.")
        server_url = match.group(1)
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        with opener.open(server_url, timeout=5) as response:
            if response.status != 200:
                raise ValueError(f"Lavish returned HTTP {response.status}.")
        browser_url = server_url
        if browser_base is not None:
            browser_url = browser_base.rstrip("/") + urllib.parse.urlsplit(server_url).path
        print(f"file: {artifact}")
        print(f"browser_url: {browser_url}", flush=True)
        if args.no_open:
            return 0
        opened = subprocess.run([*browser_command, browser_url], timeout=60)
        if opened.returncode:
            print("The Mac browser route failed. Repair its existing tunnel or transport.", file=sys.stderr)
            return opened.returncode
        print("opened_in: Google Chrome")
        return 0
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"lavish-personal: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
