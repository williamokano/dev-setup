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
  if ! command -v brew >/dev/null; then
    echo "▶ Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew install ansible git curl
else
  install_ansible_linux
fi

echo "▶ Running Ansible..."
ansible-playbook ansible/playbook.yml --ask-become-pass
