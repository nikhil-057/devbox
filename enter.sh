#!/usr/bin/env bash
set -euo pipefail

: "${DEVBOX_CONTAINER:=devbox}"

if ! docker container inspect "$DEVBOX_CONTAINER" &>/dev/null; then
  "$(dirname "$0")/bootstrap.sh"
else
  docker start "$DEVBOX_CONTAINER" &>/dev/null
  "$(dirname "$0")/connect.sh"
fi
