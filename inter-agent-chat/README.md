# Inter-Agent Terminal Chat

https://github.com/user-attachments/assets/cc76dcab-f64e-4efe-8d0e-f8baf1efd5f1

Have you ever run Claude Code in multiple terminals and wished they could just talk to each other directly by typing through each other's terminals? Well now they can.

## How it works

Uses Linux's `TIOCSTI` ioctl to inject characters directly into another terminal's input buffer. Lightweight, just 6 lines of Python, no dependencies. Messages land in the receiving agent's terminal as real user input.

You could build this with a VS Code extension or an HTTP server, but that's infrastructure. TIOCSTI works with plain SSH pseudo-terminals across fully independent terminal windows running on a remote VM in 6 lines of code.

Linux only. Kernel 6.2+ disables it by default (needs sudo or `sysctl dev.tty.legacy_tiocsti=1`).

## Requirements

- **Linux only.**
- **sudo required.** Linux kernel 6.2+ restricts TIOCSTI by default. Run with sudo or set `sysctl dev.tty.legacy_tiocsti=1`.
- **Multiple Claude Code agents** running in visible terminal sessions

## Setup

Have your LLM do it the lazy way, or:

1. Copy `SKILL.md` to `~/.claude/skills/inter-agent-chat/SKILL.md`
2. Copy `register-pts.sh` to `~/.claude/hooks/register-pts.sh` and make it executable:
   ```bash
   mkdir -p ~/.claude/hooks
   cp register-pts.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/register-pts.sh
   ```
3. Add a SessionStart hook to your settings:

```json
// ~/.claude/settings.json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/register-pts.sh",
        "timeout": 10
      }]
    }]
  }
}
```

Agent names are determined by `$AGENT_NAME` env var if set, otherwise `basename $PWD`. Works with both git worktrees (each worktree has a unique directory name) and multi-agent setups from the same directory (set `AGENT_NAME` per agent).

## Features

- **Direct messaging** — `[@agentB] message`
- **Multi-recipient** — `[@agentA @agentC] message`
- **Broadcast** — `[@all] message`
- **Human escalation** — `[@user] I need guidance`
- **Kill switch** — `[@stop]` halts all inter-agent chatter immediately

## Limitations

- **Each agent needs a unique name.** Defaults to `basename $PWD`. For multiple agents in the same directory, set `AGENT_NAME` env var per agent.
- **`time.sleep(0)` between characters is required.** Without a thread yield, the terminal detects rapid input over several hundred chars as a paste. Tested reliably up to 32K characters.
- **Doesn't work with Claude Code remote control.**
- **No collision guard.** Nothing stops two agents from writing to the same terminal at once. With three or more agents, the risk of garbled input goes up. Low but potential risk of unintended consequences.

## Security

A dev tool for a single user running multiple agents on a private VM. Not a production system or meant to replace agent teams.

TIOCSTI is inherently privileged. PTS registry is per-user. Agent PTS paths are stored in `/run/user/$UID/agent-pts/`, a per-user runtime directory. The registration hook validates that PTS paths match `/dev/pts/[0-9]+` before writing to the registry, preventing path traversal or shell injection.

No authentication between agents. Any process running as your user that can write to your PTS registry can impersonate an agent.

Prompt injection via messages. Messages arrive in the receiving agent's context window as user input. A compromised agent could send messages that manipulate the receiving agent's behavior. This is inherent to the TIOCSTI approach, there is nothing to distinguish "real user" from "injected message."

No session cleanup. Stale PTS registrations persist in `/run/user/$UID/agent-pts/` after sessions end. The registry directory is cleared on reboot (a tmpfs). For manual cleanup: `rm /run/user/$(id -u)/agent-pts/*`.

## License

MIT
