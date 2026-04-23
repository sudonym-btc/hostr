#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/hostr-common.sh"
ENVIRONMENT="${1:-local}"

hostr_validate_environment "$ENVIRONMENT" "$0"
hostr_load_env "$REPO_ROOT" "$ENVIRONMENT"
hostr_ensure_certs "$REPO_ROOT" "$ENVIRONMENT"

cd "$REPO_ROOT"
if [ "$ENVIRONMENT" = "test" ]; then
    hostr_compose_cmd "$ENVIRONMENT" down --remove-orphans --volumes || true
fi

compose_up_args=(-d --remove-orphans --yes)

# -d with proper depends_on chains (bootstrap → regtest-start → LND/CLN)
# ensures every container is scheduled after its deps are met.
# We can't use --wait because it treats one-shot init containers
# (tls-init, alby-init, lnbits-init, etc.) that exit 0 as failures.
hostr_compose_cmd "$ENVIRONMENT" up "${compose_up_args[@]}"

wait_for_oneshot_service() {
    local service_name="$1"
    local required="${2:-true}"
    local cid

    cid="$(hostr_compose_cmd "$ENVIRONMENT" ps -aq "$service_name" 2>/dev/null | head -n 1 || true)"
    if [ -z "$cid" ]; then
        if [ "$required" = "true" ]; then
            echo "missing expected one-shot service container: $service_name"
            exit 1
        fi
        return 0
    fi

    docker wait "$cid" >/dev/null 2>&1 || true
    local exit_code
    exit_code="$(docker inspect "$cid" --format '{{.State.ExitCode}}')"
    if [ "$exit_code" -ne 0 ]; then
        echo "$service_name failed with exit code: $exit_code"
        exit "$exit_code"
    fi
}

# Block until tls-init finishes so the CA cert is available for trust
# and for containers that mount it.
# Use `docker wait` (not `docker compose wait`) because compose wait
# fails with "no containers" when one-shot containers have already exited.
tls_init_cid="$(hostr_compose_cmd "$ENVIRONMENT" ps -aq tls-init 2>/dev/null | head -n 1 || true)"
if [ -n "$tls_init_cid" ]; then
    docker wait "$tls_init_cid" >/dev/null 2>&1 || true
fi

# Block until critical one-shot init containers finish so callers can safely
# interact with the local chain and seeded services immediately after start.
wait_for_oneshot_service bootstrap
if [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "test" ]; then
    wait_for_oneshot_service arbitrum-init
    wait_for_oneshot_service contract-deployer false
    wait_for_oneshot_service escrow-contract-deploy false
fi

if [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "test" ]; then
    "$SCRIPT_DIR/sync-contract-env.sh" "$ENVIRONMENT" || echo "⚠️  sync-contract-env.sh failed (non-fatal)"
fi

# Trust the dev CA on the host so browsers show green lock.
# Not required in CI (no browser, ephemeral runner) — run best-effort so a
# missing sudo or unknown OS never aborts the stack startup.
if [ "$ENVIRONMENT" != "prod" ]; then
    "$SCRIPT_DIR/trust-dev-ca.sh" || echo "⚠️  trust-dev-ca.sh failed (non-fatal)"
fi
