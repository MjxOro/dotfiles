#!/usr/bin/env bash

set -euo pipefail

RUNTIME_DIR="${CLIPROXY_HOME:-$HOME/.cliproxy}"
COMPOSE_FILE="$RUNTIME_DIR/docker-compose.yml"
PRUNE_SCRIPT="$RUNTIME_DIR/prune-auths.sh"
CONTAINER_NAME='cli-proxy-api-plus'

if [[ ! -f "$COMPOSE_FILE" ]]; then
  printf 'Missing %s\n' "$COMPOSE_FILE" >&2
  printf '%s\n' "Run ./install.sh -p cliproxy first" >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  printf '%s\n' 'Docker is installed, but this user cannot access the Docker daemon.' >&2
  printf '%s\n' 'Fix Docker permissions first, then rerun this login helper.' >&2
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  docker compose -f "$COMPOSE_FILE" up -d
fi

if [[ -x "$PRUNE_SCRIPT" ]]; then
  "$PRUNE_SCRIPT"
fi

printf '%s\n' 'OpenAI device login runs inside the container and prints a verification URL and code.'
printf '%s\n' 'Open the URL, enter the code, and finish login in the browser/account you want to authorize.'
printf '%s\n' 'For a second account, rerun this script and complete the verification flow with the other account.'
printf '%s\n' 'Each successful login adds or refreshes one auth file under ~/.cliproxy/auths for round-robin routing.'
printf '%s\n' 'No client-side API key export is needed unless you deliberately enable proxy api-keys in config.yaml.'

docker exec -i "$CONTAINER_NAME" ./CLIProxyAPIPlus --config /CLIProxyAPI/config.yaml --codex-device-login --no-browser "$@"
