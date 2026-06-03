#!/usr/bin/env bash
set -euo pipefail
CWD="$(pwd)"
trap "cd $CWD" EXIT
cd "$(dirname "$0")/.."
rm -rf ./npins
nix-shell \
  -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz \
  -p npins \
  --run "
    npins init --bare;
    npins add github nixos nixpkgs --branch nixos-unstable;
    npins add github nix-community home-manager --branch master;
    npins add github nix-community nixvim --branch main;
  "
