#!/bin/sh
# ──────────────────────────────────────────────────────────────
# ca-trust-entrypoint.sh — Inject CA trust then exec the real command
#
# Mount this as a custom entrypoint for any container that needs
# to validate TLS certificates signed by the Hostr dev CA.
#
# Usage in docker-compose:
#   volumes:
#     - ./docker/certs/ca.crt:/tls/ca.crt:ro
#     - ./docker/tls/ca-trust-entrypoint.sh:/ca-trust-entrypoint.sh:ro
#   entrypoint: ["/ca-trust-entrypoint.sh"]
#   command: ["original", "command", "here"]
# ──────────────────────────────────────────────────────────────
set -e

CA_CERT="/tls/ca.crt"

if [ -f "$CA_CERT" ]; then
  # Detect OS and install CA cert into system trust store
  if [ -d /usr/local/share/ca-certificates ]; then
    # Debian / Ubuntu / Alpine with ca-certificates package
    cp "$CA_CERT" /usr/local/share/ca-certificates/hostr-dev-ca.crt
    update-ca-certificates 2>/dev/null || true
  elif [ -d /etc/pki/ca-trust/source/anchors ]; then
    # RHEL / CentOS / Fedora
    cp "$CA_CERT" /etc/pki/ca-trust/source/anchors/hostr-dev-ca.crt
    update-ca-trust 2>/dev/null || true
  else
    # Fallback: set environment variables that many runtimes respect
    export SSL_CERT_FILE="$CA_CERT"
    export REQUESTS_CA_BUNDLE="$CA_CERT"
    export NODE_EXTRA_CA_CERTS="$CA_CERT"
    export CURL_CA_BUNDLE="$CA_CERT"
  fi
fi

exec "$@"
