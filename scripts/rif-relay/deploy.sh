#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ENVIRONMENT="${1:-test}"
load_managed_relay_env "$ENVIRONMENT" "$0"
ADMIN_PRIVATE_KEY="$(relay_admin_private_key "$0")"
NETWORK_NAME="$(relay_network_name "$ENVIRONMENT")"
DEPLOY_FLAGS="$(relay_deploy_flags)"
compose_run_rif_relay "cd /rif-relay-contracts && npx hardhat deploy --network $NETWORK_NAME $DEPLOY_FLAGS" \
	-e PK="$ADMIN_PRIVATE_KEY"
"$SCRIPT_DIR/../sync-contract-env.sh" "$ENVIRONMENT"
