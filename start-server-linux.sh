#!/usr/bin/env bash
cd "$(dirname "$0")"

if ! command -v python3 &>/dev/null; then
  echo "python3 is not installed. Run the setup script first."
  exit 1
fi

python3 server/vibe-server-start.py
