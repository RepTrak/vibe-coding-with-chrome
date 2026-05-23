#!/usr/bin/env bash

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BOLD=$'\033[1m'
NC=$'\033[0m'

cd "$(dirname "$0")"

# Detect package manager
detect_pkg_manager() {
  if command -v apt-get &>/dev/null; then echo "apt"
  elif command -v dnf &>/dev/null;    then echo "dnf"
  elif command -v yum &>/dev/null;    then echo "yum"
  elif command -v pacman &>/dev/null; then echo "pacman"
  elif command -v zypper &>/dev/null; then echo "zypper"
  else echo ""
  fi
}

pkg_install_cmd() {
  local dep=$1 mgr=$2
  case $mgr in
    apt)    echo "sudo apt-get install -y $dep" ;;
    dnf)    echo "sudo dnf install -y $dep" ;;
    yum)    echo "sudo yum install -y $dep" ;;
    pacman) echo "sudo pacman -S --noconfirm $dep" ;;
    zypper) echo "sudo zypper install -y $dep" ;;
    *)      echo "" ;;
  esac
}

# ttyd is in apt repos on Ubuntu 21.10+; otherwise snap is the safest fallback.
# On Arch, prefer yay/paru (AUR helpers) if available, then snap, then manual.
ttyd_install_cmd() {
  local mgr=$1
  if [[ $mgr == "apt" ]]; then
    echo "sudo apt-get install -y ttyd"
  elif [[ $mgr == "pacman" ]]; then
    if command -v yay &>/dev/null; then echo "yay -S ttyd"
    elif command -v paru &>/dev/null; then echo "paru -S ttyd"
    elif command -v snap &>/dev/null; then echo "sudo snap install ttyd --classic"
    else echo ""
    fi
  elif command -v snap &>/dev/null; then
    echo "sudo snap install ttyd --classic"
  else
    echo ""
  fi
}

PKG_MGR=$(detect_pkg_manager)
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
  echo "${GREEN}All dependencies present. Run ./start-server-linux.sh to start.${NC}"
  echo ""
  exit 0
fi

if [[ -z $PKG_MGR ]]; then
  echo "${YELLOW}No supported package manager detected (apt/dnf/yum/pacman/zypper).${NC}"
  echo "Please install missing dependencies manually."
  echo ""
fi

for dep in "${MISSING[@]}"; do
  if [[ $dep == "ttyd" ]]; then
    cmd=$(ttyd_install_cmd "$PKG_MGR")
  else
    cmd=$(pkg_install_cmd "$dep" "$PKG_MGR")
  fi

  echo "${YELLOW}Missing: $dep${NC}"
  if [[ -n $cmd ]]; then
    echo "  Install command:  ${BOLD}$cmd${NC}"
    echo -n "  Install $dep now? [y/N] "
    read -r choice
    echo ""

    if [[ "$choice" =~ ^[Yy]$ ]]; then
      echo "  Running: $cmd"
      eval "$cmd"
      if command -v "$dep" &>/dev/null; then
        echo "  ${GREEN}[ok]  $dep installed successfully.${NC}"
      else
        # snap installs may not be on PATH until the terminal is restarted
        if [[ $cmd == *"snap"* ]]; then
          echo "  ${YELLOW}snap install completed. If '$dep' is not found, restart your terminal and re-run this script.${NC}"
        else
          echo "  ${RED}Install may have failed. Try manually: $cmd${NC}"
        fi
      fi
    else
      echo "  Skipped. Run when ready:  $cmd"
    fi
  else
    echo "  ${YELLOW}No automatic install available for $dep on this system.${NC}"
    if [[ $dep == "ttyd" ]]; then
      echo "  Download a binary from: https://github.com/tsl0922/ttyd/releases"
    fi
  fi
  echo ""
done

# Final status
ALL_OK=true
for dep in "${DEPS[@]}"; do
  command -v "$dep" &>/dev/null || ALL_OK=false
done

if [[ $ALL_OK == true ]]; then
  echo "${GREEN}All dependencies installed. Run ./start-server-linux.sh to start.${NC}"
else
  echo "${YELLOW}Some dependencies are still missing. Re-run ./setup-server-linux.sh when ready.${NC}"
fi
echo ""
