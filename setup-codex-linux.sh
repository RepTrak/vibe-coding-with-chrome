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
if command -v codex &>/dev/null; then
  echo "${GREEN}[ok]${NC}  Codex CLI is already installed."
  echo ""
  exit 0
fi

echo "${BOLD}Setting up Codex CLI...${NC}"
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
echo "Installing Codex CLI (this may take a minute)..."
npm install -g @openai/codex

# Symlink into /usr/local/bin so non-interactive shells (e.g. wsl bash) find it
CODEX_BIN=$(which codex 2>/dev/null)
if [[ -n "$CODEX_BIN" ]]; then
  sudo ln -sf "$CODEX_BIN" /usr/local/bin/codex 2>/dev/null || true
fi

echo ""

if ! command -v codex &>/dev/null; then
  echo "${YELLOW}Install may have failed. Try manually: npm install -g @openai/codex${NC}"
  echo ""
  exit 1
fi

echo "${GREEN}[ok]${NC}  Codex CLI installed successfully."
echo ""

# ── API key ───────────────────────────────────────────────────────────────────
echo "${BOLD}API key required.${NC}"
echo -n "Enter your OpenAI API key (or press Enter to set it later): "
read -r api_key
echo ""

if [[ -n "$api_key" ]]; then
  if grep -q "OPENAI_API_KEY" ~/.bashrc 2>/dev/null; then
    echo "${YELLOW}OPENAI_API_KEY already exists in ~/.bashrc — update it manually if needed.${NC}"
  else
    echo "export OPENAI_API_KEY=$api_key" >> ~/.bashrc
    echo "${GREEN}[ok]${NC}  API key saved to ~/.bashrc"
    echo "      Restart your terminal or run: source ~/.bashrc"
  fi
else
  echo "Skipped. To set it later, add this line to ~/.bashrc:"
  echo "  export OPENAI_API_KEY=your-key-here"
fi
echo ""
