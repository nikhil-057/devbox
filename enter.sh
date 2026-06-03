#!/usr/bin/env bash
set -euo pipefail

if ! docker container inspect devbox &>/dev/null; then
  "$(dirname "$0")/bootstrap.sh"
else
  docker start devbox &>/dev/null
  echo "Entering devbox..."
  docker exec -it devbox bash -l -c 'tmux attach 2>/dev/null || tmux new-session -s 0'
fi
