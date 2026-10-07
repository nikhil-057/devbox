#!/usr/bin/env bash
set -euo pipefail

command -v docker &>/dev/null || { echo "docker is required but not installed"; exit 1; }
command -v git &>/dev/null || { echo "git is required but not installed"; exit 1; }

[ -e "$HOME/repos" ] || { echo "Cannot resolve path for repos" >&2; exit 1; }
[ -e "$HOME/.credentials" ] || { echo "Cannot resolve path for .credentials" >&2; exit 1; }
[ -e "$HOME/.ssh" ] || { echo "Cannot resolve path for .ssh" >&2; exit 1; }
[ -e "$HOME/OneDrive - Soho House Group" ] || { echo "Cannot resolve path for OneDrive (personal)" >&2; exit 1; }
[ -e "$HOME/Soho House Group" ] || { echo "Cannot resolve path for Soho House Group (shared)" >&2; exit 1; }

docker rm -f devbox 2>/dev/null || true

docker create \
  --name devbox \
  -e USER=root \
  -e HOME=/root \
  -e HOST_HOME="$HOME" \
  -v nix-store:/nix \
  -v nix-data:/root \
  -v $(realpath "$HOME/repos"):/root/repos \
  -v $(realpath "$HOME/.credentials"):/root/.credentials \
  -v $(realpath "$HOME/.ssh"):/root/.ssh \
  -v "$(realpath "$HOME/OneDrive - Soho House Group")":"/root/onedrive/OneDrive - Soho House Group" \
  -v "$(realpath "$HOME/Soho House Group")":"/root/onedrive/Soho House Group" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 8001:8001 \
  -p 1455:1455 \
  debian:bookworm \
  sleep infinity

docker start devbox

docker exec devbox bash -c '
  set -euo pipefail
  apt-get update -qq
  apt-get install -y -qq curl git xz-utils
  rm -f \
    /etc/bash.bashrc \
    /etc/bash.bashrc.backup-before-nix \
    /etc/bashrc.backup-before-nix \
    /etc/zshrc.backup-before-nix
  sh <(curl -L https://nixos.org/nix/install) --daemon --yes
  sed -i '/GSSAPIAuthentication/d' /etc/ssh/ssh_config
  . /etc/profile
  nix-channel --remove nixpkgs || true
  rm -f ~/.ssh/config ~/.ssh/config.backup
  cd ~/repos/devbox
  ./setup/hm.sh
'

echo "Bootstrap complete..."
"$(dirname "$0")/connect.sh"
