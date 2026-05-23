#!/usr/bin/env zsh

if pgrep -f "vibe-server-start.py" &>/dev/null; then
  echo "vibe-server-start.py is still running. Stop it first (press q + Enter), then re-run this script."
  exit 1
fi

SESSION="main"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
  echo "Session '$SESSION' killed."
else
  echo "No tmux session named '$SESSION' found."
fi
