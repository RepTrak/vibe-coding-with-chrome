#!/usr/bin/env zsh
cd "$(dirname "$0")"

if ! command -v python3 &>/dev/null; then
  echo "python3 is not installed. Run ./setup-server.sh first."
  exit 1
fi

python3 server/vibe-server-start.py
