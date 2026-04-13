#!/usr/bin/env bash
# Run the escrow daemon + interactive CLI against a remote environment.
#
# Sources .env + the environment overlay for config, then pulls secrets
# (ESCROW_PRIVATE_KEY) from GCP Secret Manager automatically.
#
# Usage:
#   bash scripts/run-escrow.sh staging
#   bash scripts/run-escrow.sh production
set -euo pipefail

# ── 0. Parse argument ───────────────────────────────────────────────
TARGET="${1:-}"
case "$TARGET" in
  staging)
    GCP_PROJECT="hostr-staging-d4c52998"
    ENV_FILE=".env.staging"
    ENV_NAME="staging"
    ;;
  production|prod)
    GCP_PROJECT="hostr-production-d3ba05b4"
    ENV_FILE=".env.prod"
    ENV_NAME="production"
    ;;
  *)
    echo "Usage: $0 <staging|production>"
    exit 1
    ;;
esac

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ── 1. Load env files (base + overlay, last wins) ───────────────────
set -a
source "$REPO_ROOT/.env"
source "$REPO_ROOT/$ENV_FILE"
set +a

# ── 2. Pull secrets from GCP Secret Manager ─────────────────────────
echo "Fetching ESCROW_PRIVATE_KEY from Secret Manager (project: $GCP_PROJECT)…"
ESCROW_PRIVATE_KEY="$(gcloud secrets versions access latest \
  --secret=ESCROW_PRIVATE_KEY \
  --project="$GCP_PROJECT")"

# ── 3. Map env vars to what the daemon expects ──────────────────────────────────
export NOSTR_RELAY="wss://relay.${DOMAIN}"
export PRIVATE_KEY="$ESCROW_PRIVATE_KEY"
export ENV="$ENV_NAME"
# Point at the hosted nginx OTLP proxy (auth injected server-side)
export OTEL_EXPORTER_OTLP_ENDPOINT="https://app.${DOMAIN}/otlp"

echo "──────────────────────────────────────"
echo "  ENV:                      $ENV_NAME"
echo "  NOSTR_RELAY:              $NOSTR_RELAY"
echo "  RPC_URL:                  $EVM_CHAIN_ARBITRUM_RPC_URL"
echo "  ESCROW_CONTRACT_ADDRESS:  $EVM_CHAIN_ARBITRUM_ESCROW_CONTRACT_ADDRESS"
echo "  AA_BUNDLER_URL:           ${EVM_CHAIN_ARBITRUM_AA_BUNDLER_URL:+(set)}"
echo "  AA_PAYMASTER_ADDRESS:     $EVM_CHAIN_ARBITRUM_AA_PAYMASTER_ADDRESS"
echo "  PRIVATE_KEY:              ${PRIVATE_KEY:0:6}…"
echo "──────────────────────────────────────"

# ── 4. Launch daemon + CLI via the combined runner ───────────────────
cd "$REPO_ROOT/escrow"
exec dart run bin/run.dart
