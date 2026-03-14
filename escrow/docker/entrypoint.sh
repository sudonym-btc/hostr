#!/bin/sh
set -e

# ── Trust dev CA certificate if mounted ──────────────────────────────────
if [ -f /tls/ca.crt ]; then
  cp /tls/ca.crt /usr/local/share/ca-certificates/hostr-dev-ca.crt
  update-ca-certificates 2>/dev/null || true
fi

# ── Start the daemon (PID 1, foreground) ─────────────────────────────────
# The daemon resolves the escrow contract address from
# `escrow/contracts/contract-addresses.json` (or an explicit
# `ESCROW_CONTRACT_ADDRESS` override) before starting.
exec dart run bin/daemon.dart
