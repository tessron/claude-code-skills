#!/bin/bash
# Register this agent's pts device for inter-agent chat
# Called by Claude Code SessionStart hook

mkdir -p /tmp/agent-pts

# Determine agent name: AGENT_NAME env var > directory name
if [ -z "$AGENT_NAME" ]; then
    AGENT_NAME="$(basename "$PWD")"
fi

# Get the pts of the parent shell (Claude Code's terminal)
PARENT_PID=$(ps -o ppid= -p $$ | tr -d ' ')
MY_TTY=$(ps -o tty= -p $PARENT_PID 2>/dev/null | tr -d ' ')

# Walk up process tree to find the pts
if [ -z "$MY_TTY" ] || [ "$MY_TTY" = "?" ]; then
    GRANDPARENT_PID=$(ps -o ppid= -p $PARENT_PID 2>/dev/null | tr -d ' ')
    MY_TTY=$(ps -o tty= -p $GRANDPARENT_PID 2>/dev/null | tr -d ' ')
fi

if [ -n "$MY_TTY" ] && [ "$MY_TTY" != "?" ]; then
    echo "/dev/$MY_TTY" > /tmp/agent-pts/$AGENT_NAME
fi

# Return context so the agent knows its identity
cat <<EOF
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Inter-agent chat: registered as $AGENT_NAME on /dev/$MY_TTY"}}
EOF
