#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENVIRONMENT="${1:-local}"
RIF_RELAY_MODE="${2:-regtest-fast}"
ENV_FILE="$REPO_ROOT/.env.$ENVIRONMENT"

case "$ENVIRONMENT" in
    local|test|staging|prod) ;;
    *)
        echo "Usage: $0 [local|test|staging|prod] [regtest-fast|regtest-managed]"
        exit 64
        ;;
esac

case "$RIF_RELAY_MODE" in
    regtest-fast|regtest-managed) ;;
    *)
        echo "Usage: $0 [local|test|staging|prod] [regtest-fast|regtest-managed]"
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
    selected_docker_default_platform="${DOCKER_DEFAULT_PLATFORM:-}"
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

    # Keep Boltz LND platform consistent with the explicitly requested Docker platform.
    # This prevents pulling amd64 images while compose still requests arm64 (or vice versa).
    if [ -n "$selected_docker_default_platform" ]; then
        LND_PLATFORM="$selected_docker_default_platform"
    fi
fi
set +a

if [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "test" ]; then
    case ":${COMPOSE_FILE:-}:" in
        *:docker-compose.rif-relay-managed-override.yml:*) ;;
        *)
            if [ "$RIF_RELAY_MODE" = "regtest-managed" ]; then
                COMPOSE_FILE="${COMPOSE_FILE}:docker-compose.rif-relay-managed-override.yml"
            fi
            ;;
    esac
fi

docker network inspect shared_network >/dev/null 2>&1 || docker network create shared_network

cd "$REPO_ROOT"
if [ "$ENVIRONMENT" = "test" ]; then
    docker compose down --remove-orphans --volumes || true
fi

compose_up_args=(-d --remove-orphans --yes)
if { [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "test" ]; } && [ "$RIF_RELAY_MODE" = "regtest-managed" ]; then
    compose_up_args+=(--scale rif-relay=0)
fi

# Rebuild local-source images in local/test so restarts always pick up
# workspace changes for one-shot deployment and relay services.
if [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "test" ]; then
    docker compose build escrow-contract-deploy rif-relay
fi

# -d with proper depends_on chains (bootstrap → regtest-start → LND/CLN)
# ensures every container is scheduled after its deps are met.
# We can't use --wait because it treats one-shot init containers
# (tls-init, alby-init, lnbits-init, etc.) that exit 0 as failures.
docker compose up "${compose_up_args[@]}"

# Block until tls-init finishes so the CA cert is available for trust
# and for containers that mount it.
# Use `docker wait` (not `docker compose wait`) because compose wait
# fails with "no containers" when one-shot containers have already exited.
tls_init_cid="$(docker compose ps -aq tls-init 2>/dev/null | head -n 1 || true)"
if [ -n "$tls_init_cid" ]; then
    docker wait "$tls_init_cid" >/dev/null 2>&1 || true
fi

# Block until the one-shot bootstrap container finishes.
bootstrap_cid="$(docker compose ps -aq bootstrap 2>/dev/null | head -n 1 || true)"
if [ -n "$bootstrap_cid" ]; then
    docker wait "$bootstrap_cid" >/dev/null 2>&1
    bootstrap_exit_code="$(docker inspect "$bootstrap_cid" --format '{{.State.ExitCode}}')"
    if [ "$bootstrap_exit_code" -ne 0 ]; then
        echo "bootstrap failed with exit code: $bootstrap_exit_code"
        exit "$bootstrap_exit_code"
    fi
fi

# Trust the dev CA on the host so browsers show green lock.
# Not required in CI (no browser, ephemeral runner) — run best-effort so a
# missing sudo or unknown OS never aborts the stack startup.
if [ "$ENVIRONMENT" != "prod" ]; then
    "$SCRIPT_DIR/trust-dev-ca.sh" || echo "⚠️  trust-dev-ca.sh failed (non-fatal)"
fi
