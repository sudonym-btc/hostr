#!/bin/sh
set -e

# ── Trust dev CA certificate if mounted ──────────────────────────────────
if [ -f /tls/ca.crt ]; then
  cp /tls/ca.crt /usr/local/share/ca-certificates/hostr-dev-ca.crt
  update-ca-certificates 2>/dev/null || true
fi

# ── Read contract address ─────────────────────────────────────────────────
# Prefer the CONTRACT_ADDR env var; fall back to the file written by
# escrow-contract-deploy in local/test profiles.
if [ -z "$CONTRACT_ADDR" ] && [ -f /data/contract_addr ]; then
  CONTRACT_ADDR=$(cat /data/contract_addr)
  export CONTRACT_ADDR
fi

# ── Start the daemon (PID 1, foreground) ─────────────────────────────────
exec dart run bin/daemon.dart
