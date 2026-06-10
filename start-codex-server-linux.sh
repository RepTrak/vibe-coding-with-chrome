#!/usr/bin/env bash
cd "$(dirname "$0")"

# Source nvm so codex is in PATH even in non-interactive shells
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v python3 &>/dev/null; then
  echo "python3 is not installed. Run the setup script first."
  exit 1
fi

if ! command -v codex &>/dev/null; then
  echo "codex is not installed or not in PATH."
  echo "Install Codex CLI first: https://github.com/openai/codex"
  exit 1
fi

python3 server/vibe-server-start.py codex resume
