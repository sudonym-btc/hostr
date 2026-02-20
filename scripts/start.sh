#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENVIRONMENT="${1:-local}"
ENV_FILE="$REPO_ROOT/.env.$ENVIRONMENT"

case "$ENVIRONMENT" in
    local|test|staging|prod) ;;
    *)
        echo "Usage: $0 [local|test|staging|prod]"
        exit 64
        ;;
esac

if [ ! -f "$ENV_FILE" ]; then
    echo "Missing env file: $ENV_FILE"
    exit 66
fi

set -a
source "$REPO_ROOT/.env"
source "$ENV_FILE"
if [[ "${COMPOSE_FILE:-}" == *"dependencies/boltz-regtest/docker-compose.yml"* ]] && [ -f "$REPO_ROOT/dependencies/boltz-regtest/.env" ]; then
    selected_compose_file="${COMPOSE_FILE:-}"
    selected_compose_profiles="${COMPOSE_PROFILES:-}"
    source "$REPO_ROOT/dependencies/boltz-regtest/.env"
    COMPOSE_FILE="$selected_compose_file"

    # Always run Boltz in CI profile when its compose file is included.
    # Keep existing hostr profiles (e.g. local/test/seed), but force-add ci.
    if [ -n "$selected_compose_profiles" ]; then
        COMPOSE_PROFILES="$selected_compose_profiles"
    else
        COMPOSE_PROFILES="$ENVIRONMENT"
    fi

    case ",$COMPOSE_PROFILES," in
        *,ci,*) ;;
        *) COMPOSE_PROFILES="$COMPOSE_PROFILES,ci" ;;
    esac
fi
set +a

docker network inspect shared_network >/dev/null 2>&1 || docker network create shared_network

cd "$REPO_ROOT"
if [ "$ENVIRONMENT" = "test" ]; then
    docker compose down --remove-orphans --volumes || true
fi

exec docker compose up -d --remove-orphans --yes
