#!/usr/bin/env bash
set -e

echo "▶ Bootstrapping system..."

OS="$(uname -s)"

install_ansible_linux() {
  if command -v apt >/dev/null; then
    sudo apt update
    sudo apt install -y ansible git curl
  elif command -v pacman >/dev/null; then
    sudo pacman -Sy --noconfirm ansible git curl
  fi
}

if [[ "$OS" == "Darwin" ]]; then
  if [[ "$EUID" -eq 0 ]]; then
    echo "✖ Do not run this script with sudo on macOS — Homebrew refuses to run as root." >&2
    echo "  Run it as your regular user; Ansible will ask for your sudo password when needed." >&2
    exit 1
  fi
  if ! command -v brew >/dev/null; then
    echo "▶ Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # A fresh Homebrew install is not on PATH yet in this shell
  if ! command -v brew >/dev/null; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  brew install ansible git curl
else
  install_ansible_linux
fi

echo "▶ Running Ansible..."
ansible-playbook ansible/playbook.yml --ask-become-pass
