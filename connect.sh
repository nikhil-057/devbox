#!/usr/bin/env bash
set -euo pipefail

: "${DEVBOX_CONTAINER:=devbox}"

echo "Setting up macos clipboard bridge..."

pkill -f "socat TCP-LISTEN:8377" 2>/dev/null || true
nohup socat TCP-LISTEN:8377,reuseaddr,fork EXEC:pbcopy >/tmp/docker-pbcopy.log 2>&1 &

pkill -f "socat TCP-LISTEN:8388" 2>/dev/null || true
nohup socat TCP-LISTEN:8388,reuseaddr,fork EXEC:pbpaste >/tmp/docker-pbpaste.log 2>&1 &

echo "Connecting to $DEVBOX_CONTAINER..."
docker exec -it "$DEVBOX_CONTAINER" bash -l -c "tmux attach 2>/dev/null || tmux new-session -s 0"
