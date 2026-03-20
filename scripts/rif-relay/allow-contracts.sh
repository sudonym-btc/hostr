#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ENVIRONMENT="${1:-test}"
load_managed_relay_env "$ENVIRONMENT" "$0"

NETWORK_NAME="$(relay_network_name "$ENVIRONMENT")"
VERIFIER_LIST="$(get_boltz_verifier_list "$ENVIRONMENT")"
CONTRACT_ADDRESS="$(resolve_escrow_contract_address "$ENVIRONMENT")"
ADMIN_PK="$(relay_admin_private_key "$0")"

echo ""
echo "┌─────────────────────────────────────────────────"
echo "│  allow-contracts ($ENVIRONMENT)"
echo "├─────────────────────────────────────────────────"
echo "│  Network:          $NETWORK_NAME"
echo "│  Escrow contract:  $CONTRACT_ADDRESS"
echo "│  Verifiers:        $VERIFIER_LIST"
echo "│  Admin key:        ${ADMIN_PK:0:6}…${ADMIN_PK: -4}"
echo "└─────────────────────────────────────────────────"
echo ""
read -rp "Proceed? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
	echo "Aborted."
	exit 0
fi

cd "$REPO_ROOT/dependencies/rif-relay-contracts"
PK="$ADMIN_PK" npx hardhat allow-contracts \
	--contract-list "$CONTRACT_ADDRESS" \
	--verifier-list "$VERIFIER_LIST" \
	--network "$NETWORK_NAME"
