#!/usr/bin/env bash
# Pulls ESCROW_PRIVATE_KEY from GCP Secret Manager and prints the Nostr pubkey.
#
# Usage:
#   ./scripts/escrow-pubkey.sh                          # uses production project
#   ./scripts/escrow-pubkey.sh hostr-staging-XXXX       # specify project
set -euo pipefail

PROJECT="${1:-hostr-production-d3ba05b4}"
SECRET_NAME="ESCROW_PRIVATE_KEY"

echo "Fetching $SECRET_NAME from project $PROJECT …"

NSEC_HEX=$(gcloud secrets versions access latest \
  --secret="$SECRET_NAME" \
  --project="$PROJECT") || {
  echo "ERROR: Could not fetch secret. Check gcloud auth and project ID." >&2
  exit 1
}

echo ""
echo "Deriving Nostr pubkey …"
PUBKEY=$(cd "$(dirname "$0")/../escrow" && dart run bin/pubkey.dart "$NSEC_HEX")

echo ""
echo "  Nostr pubkey: $PUBKEY"
echo ""
echo "Use this value in bootstrapEscrowPubkeys in your app configs."
