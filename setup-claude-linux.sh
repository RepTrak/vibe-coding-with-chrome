#!/usr/bin/env bash

GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BOLD=$'\033[1m'
NC=$'\033[0m'

cd "$(dirname "$0")"

# Source nvm if present (needed in non-interactive shells)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo ""

# ── Already installed? ────────────────────────────────────────────────────────
if command -v claude &>/dev/null; then
  echo "${GREEN}[ok]${NC}  Claude Code is already installed."
  claude --version 2>/dev/null
  echo ""
  exit 0
fi

echo "${BOLD}Setting up Claude Code...${NC}"
echo ""

# ── Node.js ───────────────────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  echo "Node.js not found. Installing via nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm use --lts
  echo ""
else
  echo "${GREEN}[ok]${NC}  Node.js $(node --version) found."
fi

# ── Install ───────────────────────────────────────────────────────────────────
echo "Installing Claude Code (this may take a minute)..."
npm install -g @anthropic-ai/claude-code

# Symlink into /usr/local/bin so non-interactive shells (e.g. wsl bash) find it
CLAUDE_BIN=$(which claude 2>/dev/null)
if [[ -n "$CLAUDE_BIN" ]]; then
  sudo ln -sf "$CLAUDE_BIN" /usr/local/bin/claude 2>/dev/null || true
fi

echo ""

if ! command -v claude &>/dev/null; then
  echo "${YELLOW}Install may have failed. Try manually: npm install -g @anthropic-ai/claude-code${NC}"
  echo ""
  exit 1
fi

echo "${GREEN}[ok]${NC}  Claude Code installed successfully."
echo ""

# ── Authentication ────────────────────────────────────────────────────────────
echo "${BOLD}Authentication required.${NC}"
echo "Running 'claude' now to complete login."
echo "If a browser does not open automatically, copy the URL shown and paste it into Chrome."
echo ""
claude
echo ""
