#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/hostr-common.sh"
ENVIRONMENT="${1:-local}"
RIF_RELAY_MODE="${2:-regtest-fast}"

hostr_validate_environment "$ENVIRONMENT" "$0"
hostr_validate_rif_relay_mode "$RIF_RELAY_MODE" "$0"
hostr_load_env "$REPO_ROOT" "$ENVIRONMENT"
hostr_ensure_certs "$REPO_ROOT" "$ENVIRONMENT"
export RIF_RELAY_MODE

cd "$REPO_ROOT"
if [ "$ENVIRONMENT" = "test" ]; then
    hostr_compose_cmd "$ENVIRONMENT" down --remove-orphans --volumes || true
fi

compose_up_args=(-d --remove-orphans --yes)
if { [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "test" ]; } && [ "$RIF_RELAY_MODE" = "regtest-managed" ]; then
    compose_up_args+=(--scale rif-relay=0)
fi

# -d with proper depends_on chains (bootstrap → regtest-start → LND/CLN)
# ensures every container is scheduled after its deps are met.
# We can't use --wait because it treats one-shot init containers
# (tls-init, alby-init, lnbits-init, etc.) that exit 0 as failures.
hostr_compose_cmd "$ENVIRONMENT" up "${compose_up_args[@]}"

# Block until tls-init finishes so the CA cert is available for trust
# and for containers that mount it.
# Use `docker wait` (not `docker compose wait`) because compose wait
# fails with "no containers" when one-shot containers have already exited.
tls_init_cid="$(hostr_compose_cmd "$ENVIRONMENT" ps -aq tls-init 2>/dev/null | head -n 1 || true)"
if [ -n "$tls_init_cid" ]; then
    docker wait "$tls_init_cid" >/dev/null 2>&1 || true
fi

# Block until the one-shot bootstrap container finishes.
bootstrap_cid="$(hostr_compose_cmd "$ENVIRONMENT" ps -aq bootstrap 2>/dev/null | head -n 1 || true)"
if [ -n "$bootstrap_cid" ]; then
    docker wait "$bootstrap_cid" >/dev/null 2>&1
    bootstrap_exit_code="$(docker inspect "$bootstrap_cid" --format '{{.State.ExitCode}}')"
    if [ "$bootstrap_exit_code" -ne 0 ]; then
        echo "bootstrap failed with exit code: $bootstrap_exit_code"
        exit "$bootstrap_exit_code"
    fi
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
