"""Running commands: quiet queries, and logged steps that stream to the terminal."""

from __future__ import annotations

import shlex
import subprocess
import sys
from pathlib import Path

STATE_DIR = Path("/tmp/install-host")
LOG_FILE = STATE_DIR / "install.log"
ANSWERS_FILE = STATE_DIR / "answers.json"


class CommandFailed(Exception):
    def __init__(self, cmd: list[str], returncode: int, output: str = ""):
        self.cmd = cmd
        self.returncode = returncode
        self.output = output
        super().__init__(f"{shlex.join(cmd)} failed (exit {returncode})")


def log(message: str) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    with LOG_FILE.open("a") as f:
        f.write(message.rstrip("\n") + "\n")


def capture(cmd: list[str], *, check: bool = True, input: str | None = None) -> str:
    """Run a query and return its stdout. stderr goes to the log, and into the
    exception on failure (the caller shows it, e.g. a nix eval error)."""
    proc = subprocess.run(cmd, capture_output=True, text=True, input=input)
    if proc.stderr:
        log(f"$ {shlex.join(cmd)}\n{proc.stderr}")
    if check and proc.returncode != 0:
        raise CommandFailed(cmd, proc.returncode, proc.stderr)
    return proc.stdout


def ok(cmd: list[str]) -> bool:
    return subprocess.run(cmd, capture_output=True).returncode == 0


def run(cmd: list[str], *, check: bool = True) -> int:
    """Run an install step outside the TUI: output streams to the terminal and
    the log (nix's -L logs and progress included)."""
    log(f"$ {shlex.join(cmd)}")
    print(f"\033[1m$ {shlex.join(cmd)}\033[0m", flush=True)
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    assert proc.stdout is not None
    with LOG_FILE.open("ab") as logf:
        for chunk in iter(lambda: proc.stdout.read1(4096), b""):  # type: ignore[union-attr]
            sys.stdout.buffer.write(chunk)
            sys.stdout.flush()
            logf.write(chunk)
    proc.wait()
    if check and proc.returncode != 0:
        raise CommandFailed(cmd, proc.returncode)
    return proc.returncode


def interactive(cmd: list[str]) -> int:
    """Hand the terminal to a program (nmtui, passwd, a shell)."""
    log(f"$ {shlex.join(cmd)}  (interactive)")
    return subprocess.run(cmd).returncode
