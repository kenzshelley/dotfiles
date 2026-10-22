"""Apply consistent colors to cmux's native agent status icons."""

import json
import os
from pathlib import Path
import shlex
import socket


AGENTS = {"codex", "claude_code"}
AGENT_NAMES = {"codex": "Codex", "claude_code": "Claude"}


def session_model(agent, workspace, panel):
    """Read the model from the newest matching local agent transcript."""
    name = "claude" if agent == "claude_code" else agent
    path = Path.home() / ".cmuxterm" / (name + "-hook-sessions.json")
    try:
        records = json.loads(path.read_text()).get("sessions", {}).values()
        matches = [r for r in records if r.get("workspaceId") == workspace
                   and panel and r.get("surfaceId") == panel]
        if not matches:
            return None
        record = max(matches, key=lambda r: r.get("updatedAt", 0))
        transcript = Path(record["transcriptPath"])
        # Bound reads; prefer the most recent turn, falling back to the start
        # when a long tool response has pushed turn metadata out of the tail.
        with transcript.open("rb") as stream:
            size = transcript.stat().st_size
            stream.seek(max(0, size - 2 * 1024 * 1024))
            tail = stream.read()
            stream.seek(0)
            head = stream.read(min(size, 2 * 1024 * 1024))
        for chunk in (tail, head):
            for line in reversed(chunk.splitlines()):
                try:
                    entry = json.loads(line)
                except ValueError:
                    continue
                if agent == "codex" and entry.get("type") == "turn_context":
                    model = entry.get("payload", {}).get("model")
                elif agent == "claude_code" and entry.get("type") == "assistant":
                    model = entry.get("message", {}).get("model")
                else:
                    continue
                if isinstance(model, str) and model and model != "<synthetic>":
                    return model
    except (OSError, ValueError, KeyError, TypeError):
        return None
    return None


def status_color(value):
    """Choose a color without changing the agent's original status text."""
    value = value.casefold()
    if any(word in value for word in ("error", "failed", "failure")):
        return "#EF4444"
    if any(word in value for word in ("needs", "permission", "approval", "blocked", "waiting")):
        return "#F59E0B"
    if any(word in value for word in ("running", "working", "starting", "subagent", "background")):
        return "#3B82F6"
    if any(word in value for word in ("idle", "done", "finished", "complete", "ready")):
        return "#22C55E"
    return None


def colored_command(event):
    """Return a status update, or None for unrelated/already styled events."""
    payload = event.get("payload", {})
    if event.get("name") != "sidebar.metadata.updated" or payload.get("command") != "set_status":
        return None
    tokens = shlex.split(payload.get("args", ""))
    if not tokens or tokens[0] not in AGENTS:
        return None
    values, options = [], {}
    for token in tokens[1:]:
        if token.startswith("--"):
            key, separator, value = token.partition("=")
            if not separator:
                return None
            options[key] = value
        else:
            values.append(token)
    value = " ".join(values)
    color = status_color(value)
    if not color or not options.get("--tab"):
        return None
    label = AGENT_NAMES[tokens[0]]
    prefix = label + " · "
    detail = value[len(prefix):] if value.startswith(prefix) else value
    if detail == "Running" or detail.startswith("Running ·"):
        detail = "Working" + detail[len("Running"):]
    model = session_model(tokens[0], options["--tab"], options.get("--panel"))
    if model and model not in detail.split(" · "):
        detail += " · " + model
    display = prefix + detail
    if (options.get("--color") == color and options.get("--icon") == "circle.fill"
            and display == value):
        return None
    options.update({"--color": color, "--icon": "circle.fill"})
    # Retain pane ownership, work state, priority, usage text, and other options.
    return "set_status " + shlex.join(
        [tokens[0], display, *(key + "=" + value for key, value in options.items())]
    )


def send_command(command):
    """Send a legacy metadata command to the local cmux control socket."""
    address = os.environ.get("CMUX_SOCKET_PATH", str(Path.home() / ".local/state/cmux/cmux.sock"))
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(2)
        connection.connect(address)
        connection.sendall((command + "\n").encode())
        result = connection.recv(65536).decode().strip()
    if result.startswith("ERROR"):
        raise RuntimeError("cmux rejected the status update: " + result)
    return result


def has_duplicate_program_status(statuses):
    """Suppress a program row only when it repeats a visible agent row."""
    rows = statuses.splitlines()
    program = next((r.split("=", 1)[1] for r in rows if r.startswith("program_status=")), "")
    for key, labels in [("codex", ("codex",)), ("claude_code", ("claude", "claude code"))]:
        if any(r.startswith(key + "=") for r in rows):
            if any(program.casefold().startswith(label + " · ") for label in labels):
                return True
    return False


def main():
    """Consolidate native status events without changing agent lifecycle state."""
    event = json.loads(os.environ["CMUX_AUTOMATION_EVENT_JSON"])
    command = colored_command(event)
    if command:
        send_command(command)
    if event.get("name") == "program_status.changed":
        workspace = event.get("workspace_id")
    elif event.get("name") == "sidebar.metadata.updated":
        tokens = shlex.split(event.get("payload", {}).get("args", ""))
        if not tokens or tokens[0] not in AGENTS:
            return
        workspace = next((t.partition("=")[2] for t in tokens if t.startswith("--tab=")), None)
    else:
        return
    if workspace:
        target = " --tab=" + shlex.quote(workspace)
        if has_duplicate_program_status(send_command("list_status" + target)):
            send_command("clear_status program_status" + target)


if __name__ == "__main__":
    main()
