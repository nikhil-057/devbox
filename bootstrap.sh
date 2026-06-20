#!/usr/bin/env bash
set -euo pipefail

command -v docker &>/dev/null || { echo "docker is required but not installed"; exit 1; }
command -v git &>/dev/null || { echo "git is required but not installed"; exit 1; }

# Ensure required host directories exist
[ -e "$HOME/repos" ] || { echo "Cannot resolve path for repos" >&2; exit 1; }
[ -e "$HOME/.credentials" ] || { echo "Cannot resolve path for .credentials" >&2; exit 1; }
[ -e "$HOME/.ssh" ] || { echo "Cannot resolve path for .ssh" >&2; exit 1; }

# Tear down existing container if present
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
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 8001:8001 \
  -p 1455:1455 \
  debian:bookworm \
  sleep infinity

docker start devbox

docker exec devbox bash -c '
  set -euo pipefail
  apt-get update -qq
  apt-get install -y -qq curl xz-utils git
  rm -f /etc/bash.bashrc \
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

echo "Bootstrap complete. Entering devbox..."
docker exec -it devbox bash -l -c 'tmux new-session -s 0'
