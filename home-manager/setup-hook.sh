#!/usr/bin/env bash
set -euo pipefail
CWD="$(pwd)"
trap "cd $CWD" EXIT
cd "$(dirname "$0")"
mkdir -p ~/.config
rm -rf ~/.config/home-manager
ln -rsfv . ~/.config/home-manager
rm -f ~/.gitconfig
home-manager switch -b backup
