#!/usr/bin/env bash
# Run the escrow daemon locally against the staging environment.
#
# Sources .env + .env.staging for config, then pulls secrets
# (ESCROW_PRIVATE_KEY) from GCP Secret Manager automatically.
#
# Usage:
#   bash scripts/run-escrow-staging.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GCP_PROJECT="hostr-staging-d4c52998"

# ── 1. Load env files (base + staging overlay, last wins) ────────────
set -a
source "$REPO_ROOT/.env"
source "$REPO_ROOT/.env.staging"
set +a

# ── 2. Pull secrets from GCP Secret Manager ─────────────────────────
echo "Fetching ESCROW_PRIVATE_KEY from Secret Manager (project: $GCP_PROJECT)…"
ESCROW_PRIVATE_KEY="$(gcloud secrets versions access latest \
  --secret=ESCROW_PRIVATE_KEY \
  --project="$GCP_PROJECT")"

# Optional: pull OTEL headers if you want telemetry locally
if gcloud secrets versions access latest \
    --secret=OTEL_EXPORTER_OTLP_HEADERS \
    --project="$GCP_PROJECT" 2>/dev/null; then
  OTEL_EXPORTER_OTLP_HEADERS="$(gcloud secrets versions access latest \
    --secret=OTEL_EXPORTER_OTLP_HEADERS \
    --project="$GCP_PROJECT")"
fi

# ── 3. Map env vars to what the daemon expects ───────────────────────
export NOSTR_RELAY="wss://relay.${DOMAIN}"
export PRIVATE_KEY="$ESCROW_PRIVATE_KEY"
export RPC_URL
export ESCROW_CONTRACT_ADDRESS
export AA_BUNDLER_URL
export AA_ENTRY_POINT_ADDRESS
export AA_ACCOUNT_FACTORY_ADDRESS
export AA_PAYMASTER_ADDRESS
export OTEL_EXPORTER_OTLP_ENDPOINT="${OTEL_EXPORTER_OTLP_ENDPOINT:-}"
export OTEL_EXPORTER_OTLP_HEADERS="${OTEL_EXPORTER_OTLP_HEADERS:-}"

echo "──────────────────────────────────────"
echo "  NOSTR_RELAY:              $NOSTR_RELAY"
echo "  RPC_URL:                  $RPC_URL"
echo "  ESCROW_CONTRACT_ADDRESS:  $ESCROW_CONTRACT_ADDRESS"
echo "  AA_BUNDLER_URL:           ${AA_BUNDLER_URL:+(set)}"
echo "  AA_PAYMASTER_ADDRESS:     $AA_PAYMASTER_ADDRESS"
echo "  PRIVATE_KEY:              ${PRIVATE_KEY:0:6}…"
echo "──────────────────────────────────────"

# ── 4. Run the daemon ────────────────────────────────────────────────
cd "$REPO_ROOT/escrow"
exec dart run bin/daemon.dart
