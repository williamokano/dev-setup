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

# Optional: SSH key for cloning private repos (e.g. dotfiles) when it is not
# the default ~/.ssh/id_* key. Passphrase-protected keys are supported — the
# passphrase is asked here, once, and the key is served from ssh-agent so
# Ansible never needs to prompt.
#
#   DEV_SETUP_SSH_KEY=~/.ssh/id_personal ./bootstrap.sh
if [[ -n "${DEV_SETUP_SSH_KEY:-}" ]]; then
  DEV_SETUP_SSH_KEY="${DEV_SETUP_SSH_KEY/#\~/$HOME}"
  if [[ ! -f "$DEV_SETUP_SSH_KEY" ]]; then
    echo "✖ SSH key not found: $DEV_SETUP_SSH_KEY" >&2
    exit 1
  fi

  # rc=2 means no agent is reachable (rc=1 is just "agent has no keys")
  agent_rc=0
  ssh-add -l >/dev/null 2>&1 || agent_rc=$?
  if [[ $agent_rc -eq 2 ]]; then
    eval "$(ssh-agent -s)" >/dev/null
  fi

  key_fingerprint="$(ssh-keygen -lf "$DEV_SETUP_SSH_KEY" | awk '{print $2}')"
  if ! ssh-add -l 2>/dev/null | grep -qF "$key_fingerprint"; then
    echo "▶ Loading SSH key $DEV_SETUP_SSH_KEY into ssh-agent..."
    if [[ "$OS" == "Darwin" ]]; then
      # Store the passphrase in the macOS Keychain so future runs don't ask
      ssh-add --apple-use-keychain "$DEV_SETUP_SSH_KEY" 2>/dev/null \
        || ssh-add "$DEV_SETUP_SSH_KEY"
    else
      ssh-add "$DEV_SETUP_SSH_KEY"
    fi
  fi

  export DEV_SETUP_SSH_KEY
fi

echo "▶ Running Ansible..."
ansible-playbook ansible/playbook.yml --ask-become-pass
