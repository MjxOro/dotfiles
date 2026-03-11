#!/usr/bin/env bash

set -euo pipefail

RUNTIME_DIR="${CLIPROXY_HOME:-$HOME/.cliproxy}"
COMPOSE_FILE="$RUNTIME_DIR/docker-compose.yml"

if [[ ! -f "$COMPOSE_FILE" ]]; then
  printf 'Missing %s\n' "$COMPOSE_FILE" >&2
  printf '%s\n' 'Run ./install.sh -p cliproxy first' >&2
  exit 1
fi

docker compose -f "$COMPOSE_FILE" pull
docker compose -f "$COMPOSE_FILE" up -d
