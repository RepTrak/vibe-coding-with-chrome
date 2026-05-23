#!/usr/bin/env zsh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

cd "$(dirname "$0")"

DEPS=(python3 ttyd tmux)
MISSING=()

echo ""
echo "${BOLD}Checking dependencies...${NC}"
echo ""

for dep in "${DEPS[@]}"; do
  if command -v "$dep" &>/dev/null; then
    echo "  ${GREEN}[ok]${NC}  $dep"
  else
    echo "  ${RED}[--]${NC}  $dep"
    MISSING+=("$dep")
  fi
done

echo ""

if [[ ${#MISSING[@]} -eq 0 ]]; then
  echo "${GREEN}All dependencies present. Run ./start-server.sh to start.${NC}"
  echo ""
  exit 0
fi

# Check Homebrew
HAS_BREW=false
if command -v brew &>/dev/null; then
  HAS_BREW=true
else
  echo "${YELLOW}Note: Homebrew not found.${NC}"
  echo "      Install it from https://brew.sh before auto-installing missing tools."
  echo ""
fi

for dep in "${MISSING[@]}"; do
  install_cmd="brew install $dep"
  echo "${YELLOW}Missing: $dep${NC}"
  echo "  Install command:  ${BOLD}$install_cmd${NC}"
  echo -n "  Install $dep now? [y/N] "
  read -r choice
  echo ""

  if [[ "$choice" =~ ^[Yy]$ ]]; then
    if [[ $HAS_BREW == false ]]; then
      echo "  ${RED}Cannot auto-install — Homebrew is not available.${NC}"
      echo "  Install Homebrew first, then re-run this script."
    else
      echo "  Running: $install_cmd"
      brew install "$dep"
      if command -v "$dep" &>/dev/null; then
        echo "  ${GREEN}[ok]  $dep installed successfully.${NC}"
      else
        echo "  ${RED}Install may have failed. Try manually: $install_cmd${NC}"
      fi
    fi
  else
    echo "  Skipped. Run when ready:  $install_cmd"
  fi
  echo ""
done

# Final status check
ALL_OK=true
for dep in "${DEPS[@]}"; do
  command -v "$dep" &>/dev/null || ALL_OK=false
done

if [[ $ALL_OK == true ]]; then
  echo "${GREEN}All dependencies installed. Run ./start-server.sh to start.${NC}"
else
  echo "${YELLOW}Some dependencies are still missing. Re-run ./setup-server.sh when ready.${NC}"
fi
echo ""
