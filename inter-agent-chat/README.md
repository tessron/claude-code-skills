# Inter-Agent Terminal Chat

<video src="https://github.com/user-attachments/assets/ddba1df4-a8b6-4152-82c4-bb2bc3d095ae" controls width="100%"></video>

Have you ever run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in multiple terminals and wished they could just talk to each other directly by typing through the other terminals? Well now they can!

## How it works

Uses Linux's `TIOCSTI` ioctl to push characters directly into another terminal's input buffer. Super lightweight, ~5 lines of Python, zero dependencies. Messages land in the receiving agent's context window as real user input. No polling, no sockets, no server, no multiplexer.

**Why TIOCSTI?** It works with plain SSH pseudo-terminals across fully independent terminal windows running on a remote VM with nothing in between.

Linux only. Kernel 6.2+ disables it by default (needs sudo or `sysctl dev.tty.legacy_tiocsti=1`).

## Requirements

- **Linux only** (macOS removed TIOCSTI; Windows doesn't have it)
- **sudo required** -- Linux kernel 6.2+ restricts TIOCSTI by default (`dev.tty.legacy_tiocsti = 0`). Either run with sudo or set `sysctl dev.tty.legacy_tiocsti=1`.
- **Multiple Claude Code agents** running in visible terminal sessions

## Setup

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

Agent names are determined by `$AGENT_NAME` env var if set, otherwise `basename $PWD`. This works transparently with both git worktrees (each worktree has a unique directory name) and multi-agent setups from the same directory (set `AGENT_NAME` per agent).

## Features

- **Direct messaging** — `[@agentB] message`
- **Multi-recipient** — `[@agentA @agentC] message`
- **Broadcast** — `[@all] message`
- **Human escalation** — `[@user] I need guidance`
- **Kill switch** — `[@stop]` halts all inter-agent chatter immediately

## Limitations

- **Each agent needs a unique name** -- defaults to `basename $PWD` (works naturally with git worktrees). For multiple agents in the same directory, set `AGENT_NAME` env var per agent.
- **`time.sleep(0)` between characters is required** -- without a thread yield, the terminal detects rapid input over several hundred chars as a paste and the message won't submit. Tested reliably up to 32K characters.
- Linux only, requires sudo on modern kernels

## Status

This project is provided as-is and might not be actively maintained. PRs are not accepted. Feel free to fork it and make it your own.

## License

MIT
