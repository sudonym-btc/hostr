#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ENVIRONMENT="${1:-test}"
load_managed_relay_env "$ENVIRONMENT" "$0"
NETWORK_NAME="$(relay_network_name "$ENVIRONMENT")"
VERIFIER_LIST="$(get_boltz_verifier_list "$ENVIRONMENT")"
CONTRACT_ADDRESS="$(resolve_escrow_contract_address "$ENVIRONMENT")"
compose_run_rif_relay "cd /rif-relay-contracts && npx hardhat allow-contracts --contract-list \"$CONTRACT_ADDRESS\" --verifier-list \"$VERIFIER_LIST\" --network $NETWORK_NAME" \
	-e VERIFIER_LIST="$VERIFIER_LIST"
