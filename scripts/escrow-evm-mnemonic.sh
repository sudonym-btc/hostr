#!/usr/bin/env bash
# Pulls ESCROW_PRIVATE_KEY from GCP Secret Manager and prints the derived
# BIP-39 mnemonic + EVM address, ready to import into MetaMask.
#
# Usage:
#   ./scripts/escrow-evm-mnemonic.sh                          # uses staging project
#   ./scripts/escrow-evm-mnemonic.sh hostr-production-XXXX    # specify project
set -euo pipefail

PROJECT="${1:-hostr-staging-d4c52998}"
SECRET_NAME="ESCROW_PRIVATE_KEY"

echo "Fetching $SECRET_NAME from project $PROJECT …"

NSEC_HEX=$(gcloud secrets versions access latest \
  --secret="$SECRET_NAME" \
  --project="$PROJECT") || {
  echo "ERROR: Could not fetch secret. Check gcloud auth and project ID." >&2
  exit 1
}

echo "Deriving EVM mnemonic + address …"
cd "$(dirname "$0")/../escrow" && dart run bin/evm_mnemonic.dart "$NSEC_HEX"
