#!/usr/bin/env bash
set -euo pipefail

RIF_RELAY_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$RIF_RELAY_SCRIPT_DIR/../.." && pwd)"
LOCAL_ENV_FILE="$RIF_RELAY_SCRIPT_DIR/local.env.sh"
CONTRACT_ADDRESSES_FILE="$REPO_ROOT/dependencies/rif-relay-contracts/contract-addresses.json"
ESCROW_CONTRACT_ADDRESSES_FILE_DEFAULT="$REPO_ROOT/escrow/contracts/contract-addresses.json"
RIF_RELAY_WORKDIR_ADDRESSES_FILE="$REPO_ROOT/docker/data/rif-relay/contract-addresses.json"
DEV_CA_CERT_FILE="$REPO_ROOT/docker/tls/ca/ca.crt"

usage_env() {
    echo "Usage: $1 [local|test|staging|prod]"
}

compose_cmd() {
    if [ "${HOSTR_ENVIRONMENT:-test}" = "staging" ] || [ "${HOSTR_ENVIRONMENT:-test}" = "prod" ]; then
        docker compose -f compose.yaml -f compose.hosted.yaml "$@"
    else
        docker compose "$@"
    fi
}

load_managed_relay_env() {
    local environment="${1:-test}"
    local env_file="$REPO_ROOT/.env.$environment"
    local runtime_env_file="$REPO_ROOT/.env.runtime"
    HOSTR_ENVIRONMENT="$environment"
    export HOSTR_ENVIRONMENT

    case "$environment" in
        local|test|staging|prod) ;;
        *)
            usage_env "${2:-$0}"
            exit 64
            ;;
    esac

    if [ ! -f "$env_file" ] && { [ "$environment" != "staging" ] && [ "$environment" != "prod" ]; }; then
        echo "Missing env file: $env_file"
        exit 66
    fi

    set -a
    if { [ "$environment" = "local" ] || [ "$environment" = "test" ]; } && [ -f "$REPO_ROOT/dependencies/boltz-regtest/.env" ]; then
        source "$REPO_ROOT/dependencies/boltz-regtest/.env"
    fi
    source "$REPO_ROOT/.env"
    if [ -f "$runtime_env_file" ] && { [ "$environment" = "staging" ] || [ "$environment" = "prod" ]; }; then
        source "$runtime_env_file"
    elif [ -f "$env_file" ]; then
        source "$env_file"
    fi
    if { [ "$environment" = "local" ] || [ "$environment" = "test" ]; } && [ -f "$LOCAL_ENV_FILE" ]; then
        source "$LOCAL_ENV_FILE"
    fi
    set +a

    if [ "$environment" = "local" ] || [ "$environment" = "test" ]; then
        export RIF_RELAY_MODE=regtest-managed
    fi

    cd "$REPO_ROOT"
}

relay_network_name() {
    if [ -n "${RIF_RELAY_NETWORK:-}" ]; then
        printf '%s\n' "$RIF_RELAY_NETWORK"
        return
    fi

    case "${1:-test}" in
        local|test) printf 'regtest\n' ;;
        staging|prod) printf 'mainnet\n' ;;
        *) printf 'regtest\n' ;;
    esac
}

relay_address_key() {
    if [ -n "${RIF_RELAY_ADDRESS_KEY:-}" ]; then
        printf '%s\n' "$RIF_RELAY_ADDRESS_KEY"
        return
    fi

    case "$(relay_network_name "${1:-test}")" in
        regtest) printf 'regtest.33\n' ;;
        testnet) printf 'testnet.31\n' ;;
        mainnet) printf 'mainnet.30\n' ;;
        *) printf 'regtest.33\n' ;;
    esac
}

relay_deploy_flags() {
    if [ -n "${RIF_RELAY_DEPLOY_FLAGS:-}" ]; then
        printf '%s\n' "$RIF_RELAY_DEPLOY_FLAGS"
    else
        printf '%s\n' '--relay-hub --boltz-smart-wallet'
    fi
}

ensure_contract_addresses_file() {
    mkdir -p "$(dirname "$CONTRACT_ADDRESSES_FILE")"
    if [ ! -f "$CONTRACT_ADDRESSES_FILE" ]; then
        printf '{}\n' >"$CONTRACT_ADDRESSES_FILE"
    fi
}

sync_contract_addresses_into_workdir() {
    ensure_contract_addresses_file
    mkdir -p "$(dirname "$RIF_RELAY_WORKDIR_ADDRESSES_FILE")"
    cp "$CONTRACT_ADDRESSES_FILE" "$RIF_RELAY_WORKDIR_ADDRESSES_FILE"
}

get_boltz_verifier_list() {
    local address_key
    address_key="$(relay_address_key "${1:-test}")"

    if [ -n "${RIF_RELAY_DEPLOY_VERIFIER_ADDRESS:-}" ] && [ -n "${RIF_RELAY_RELAY_VERIFIER_ADDRESS:-}" ]; then
        printf '%s,%s\n' "$RIF_RELAY_DEPLOY_VERIFIER_ADDRESS" "$RIF_RELAY_RELAY_VERIFIER_ADDRESS"
        return
    fi

    ensure_contract_addresses_file
    node -e '
const fs = require("fs");
const file = process.argv[1];
const key = process.argv[2] || "regtest.33";
const json = JSON.parse(fs.readFileSync(file, "utf8"));
const entry = json[key] || {};
const list = [entry.BoltzDeployVerifier, entry.BoltzRelayVerifier].filter(Boolean);
if (list.length !== 2) {
  console.error(`Missing Boltz verifier addresses for ${key} in ${file}`);
  process.exit(1);
}
process.stdout.write(list.join(","));
' "$CONTRACT_ADDRESSES_FILE" "$address_key"
}

resolve_escrow_contract_address() {
    if [ -n "${ESCROW_CONTRACT_ADDRESS:-}" ]; then
        printf '%s\n' "$ESCROW_CONTRACT_ADDRESS"
        return
    fi

    local escrow_contract_addresses_file="${ESCROW_CONTRACT_ADDRESSES_FILE:-$ESCROW_CONTRACT_ADDRESSES_FILE_DEFAULT}"
    local address_key="${ESCROW_CONTRACT_ADDRESS_KEY:-$(relay_address_key "${1:-test}")}"

    if [ ! -f "$escrow_contract_addresses_file" ]; then
        echo "Could not resolve escrow contract address. Missing $escrow_contract_addresses_file." >&2
        exit 66
    fi

    node -e '
const fs = require("fs");
const file = process.argv[1];
const key = process.argv[2] || "regtest.33";
const json = JSON.parse(fs.readFileSync(file, "utf8"));
const address = json[key]?.MultiEscrow;
if (!address) {
  console.error(`Missing MultiEscrow address for ${key} in ${file}`);
  process.exit(1);
}
process.stdout.write(String(address));
' "$escrow_contract_addresses_file" "$address_key"
}

compose_run_rif_relay() {
    local command="$1"
    shift || true
    ensure_contract_addresses_file
    sync_contract_addresses_into_workdir
    local extra_args=()
    if [ -f "$DEV_CA_CERT_FILE" ]; then
        extra_args+=(
            -v "$DEV_CA_CERT_FILE:/tmp/hostr-dev-ca.crt:ro"
            -e NODE_EXTRA_CA_CERTS=/tmp/hostr-dev-ca.crt
        )
    fi
    compose_cmd run --rm --no-deps \
        -v "$CONTRACT_ADDRESSES_FILE:/rif-relay-contracts/contract-addresses.json" \
        "${extra_args[@]}" \
        "$@" --entrypoint /bin/bash rif-relay -lc "$command"
}

relay_admin_private_key_secret_name() {
    printf '%s\n' "${RIF_RELAY_ADMIN_PRIVATE_KEY_SECRET_NAME:-RIF_RELAY_ADMIN_PRIVATE_KEY}"
}

relay_default_gcloud_project_id_for_environment() {
    local environment="${1:-${HOSTR_ENVIRONMENT:-}}"
    local tfvars_file=""

    case "$environment" in
        staging)
            tfvars_file="$REPO_ROOT/infrastructure/var/staging.tfvars"
            ;;
        prod)
            tfvars_file="$REPO_ROOT/infrastructure/var/production.tfvars"
            ;;
        *)
            return 0
            ;;
    esac

    if [ -f "$tfvars_file" ]; then
        awk -F '"' '/^[[:space:]]*project_id[[:space:]]*=/{print $2; exit}' "$tfvars_file"
    fi
}

relay_gcloud_project_id() {
    local project_id="${RIF_RELAY_ADMIN_PRIVATE_KEY_GCP_PROJECT:-${GOOGLE_CLOUD_PROJECT:-${GCLOUD_PROJECT:-${GCP_PROJECT:-${PROJECT_ID:-}}}}}"

    if [ -n "$project_id" ]; then
        printf '%s\n' "$project_id"
        return
    fi

    project_id="$(relay_default_gcloud_project_id_for_environment)"
    if [ -n "$project_id" ]; then
        printf '%s\n' "$project_id"
        return
    fi

    if command -v gcloud >/dev/null 2>&1; then
        project_id="$(gcloud config get-value project 2>/dev/null || true)"
        project_id="${project_id//$'\r'/}"
        project_id="${project_id//$'\n'/}"
    fi

    printf '%s\n' "$project_id"
}

relay_admin_private_key_from_gcloud() {
    local script_name="${1:-$0}"
    local secret_name
    local project_id

    secret_name="$(relay_admin_private_key_secret_name)"
    project_id="$(relay_gcloud_project_id)"

    if ! command -v gcloud >/dev/null 2>&1; then
        echo "gcloud CLI is required to fetch $secret_name for ${script_name}" >&2
        return 69
    fi

    if [ -z "$project_id" ]; then
        echo "Set RIF_RELAY_ADMIN_PRIVATE_KEY_GCP_PROJECT, GOOGLE_CLOUD_PROJECT, GCLOUD_PROJECT, GCP_PROJECT, or PROJECT_ID before running ${script_name}" >&2
        return 69
    fi

    gcloud secrets versions access latest \
        --secret="$secret_name" \
        --project="$project_id" | tr -d '\r\n'
}

relay_admin_private_key() {
    local private_key="${RIF_RELAY_ADMIN_PRIVATE_KEY:-${REGISTER_PRIVATE_KEY:-}}"

    if [ -z "$private_key" ] && { [ "${HOSTR_ENVIRONMENT:-}" = "staging" ] || [ "${HOSTR_ENVIRONMENT:-}" = "prod" ]; }; then
        private_key="$(relay_admin_private_key_from_gcloud "${1:-$0}")" || return $?
    fi

    if [ -z "$private_key" ]; then
        echo "Set RIF_RELAY_ADMIN_PRIVATE_KEY or REGISTER_PRIVATE_KEY before running ${1:-$0}" >&2
        return 64
    fi

    printf '%s\n' "$private_key"
}

relay_wind_down_workdir() {
    printf '%s\n' "${RIF_RELAY_WIND_DOWN_WORKDIR:-/srv/app/environment}"
}
