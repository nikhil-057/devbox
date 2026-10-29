#!/usr/bin/env bash
set -euo pipefail

: "${DEVBOX_CONTAINER:=devbox}"

command -v docker &>/dev/null || { echo "docker is required but not installed"; exit 1; }
command -v git &>/dev/null || { echo "git is required but not installed"; exit 1; }

# HOST_HOME set => nested run from inside devbox; trust it. Else realpath $HOME.
if [ -z "${HOST_HOME:-}" ]; then
  [ -e "$HOME/repos" ] || { echo "Cannot resolve path for repos" >&2; exit 1; }
  [ -e "$HOME/.credentials" ] || { echo "Cannot resolve path for .credentials" >&2; exit 1; }
  [ -e "$HOME/.ssh" ] || { echo "Cannot resolve path for .ssh" >&2; exit 1; }
  [ -e "$HOME/.aws" ] || { echo "Cannot resolve path for .aws" >&2; exit 1; }
  [ -e "$HOME/OneDrive - Soho House Group" ] || { echo "Cannot resolve path for OneDrive (personal)" >&2; exit 1; }
  [ -e "$HOME/Soho House Group" ] || { echo "Cannot resolve path for Soho House Group (shared)" >&2; exit 1; }
  host_home_env="$(realpath "$HOME")"
  repos_src="$(realpath "$HOME/repos")"
  credentials_src="$(realpath "$HOME/.credentials")"
  ssh_src="$(realpath "$HOME/.ssh")"
  aws_src="$(realpath "$HOME/.aws")"
  onedrive_personal_src="$(realpath "$HOME/OneDrive - Soho House Group")"
  onedrive_shared_src="$(realpath "$HOME/Soho House Group")"
else
  host_home_env="$HOST_HOME"
  repos_src="$HOST_HOME/repos"
  credentials_src="$HOST_HOME/.credentials"
  ssh_src="$HOST_HOME/.ssh"
  aws_src="$HOST_HOME/.aws"
  onedrive_personal_src="$HOST_HOME/OneDrive - Soho House Group"
  onedrive_shared_src="$HOST_HOME/Soho House Group"
fi

# Non-default name: isolate /root volume and skip ports (live devbox holds them).
if [ "$DEVBOX_CONTAINER" = "devbox" ]; then
  nix_data_volume="nix-data"
  port_args=(-p 8001:8001 -p 1455:1455)
else
  nix_data_volume="nix-data-$DEVBOX_CONTAINER"
  port_args=()
fi

docker rm -f "$DEVBOX_CONTAINER" 2>/dev/null || true

docker create \
  --name "$DEVBOX_CONTAINER" \
  -e USER=root \
  -e HOME=/root \
  -e HOST_HOME="$host_home_env" \
  -v nix-store:/nix \
  -v "$nix_data_volume":/root \
  -v "$repos_src":/root/repos \
  -v "$credentials_src":/root/.credentials \
  -v "$ssh_src":/root/.ssh \
  -v "$aws_src":/root/.aws \
  -v "$onedrive_personal_src":"/root/onedrive/OneDrive - Soho House Group" \
  -v "$onedrive_shared_src":"/root/onedrive/Soho House Group" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  "${port_args[@]}" \
  debian:bookworm \
  sleep infinity

docker start "$DEVBOX_CONTAINER"

docker exec "$DEVBOX_CONTAINER" bash -c '
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
if [ -z "${DEVBOX_SKIP_CONNECT:-}" ]; then
  "$(dirname "$0")/connect.sh"
fi
