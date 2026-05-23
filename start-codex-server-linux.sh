#!/usr/bin/env bash
cd "$(dirname "$0")"

if ! command -v codex &>/dev/null; then
  echo "codex is not installed or not in PATH."
  echo "Install Codex CLI first: https://github.com/openai/codex"
  exit 1
fi

python3 server/vibe-server-start.py codex resume
