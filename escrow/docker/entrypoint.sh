#!/bin/sh
set -e

# ── Trust dev CA certificate if mounted ──────────────────────────────────
if [ -f /tls/ca.crt ]; then
  cp /tls/ca.crt /usr/local/share/ca-certificates/hostr-dev-ca.crt
  update-ca-certificates 2>/dev/null || true
fi

# ── Start the daemon (PID 1, foreground) ─────────────────────────────────
# CONTRACT_ADDR must be set in the environment by the orchestrator
# (docker-compose, k8s, etc.) — we never read it from a file here.
exec dart run bin/daemon.dart
