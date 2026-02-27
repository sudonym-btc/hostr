#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# trust-dev-ca.sh — Trust the Hostr dev CA on the host machine
#
# Idempotent: only prompts for sudo if the CA isn't already trusted.
# Supports macOS and Linux.
# ──────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CA_CERT="$(cd "$SCRIPT_DIR/.." && pwd)/docker/tls/ca/ca.crt"

if [ ! -f "$CA_CERT" ]; then
  echo "⚠️  CA cert not found at $CA_CERT — run tls-init first."
  exit 0
fi

CA_FINGERPRINT=$(openssl x509 -in "$CA_CERT" -noout -fingerprint -sha256 2>/dev/null | sed 's/.*=//')

if [[ "$OSTYPE" == darwin* ]]; then
  # Check if already trusted by comparing SHA-256 fingerprints.
  # `security find-certificate -Z` only prints SHA-1, so dump PEM certs and
  # re-fingerprint them with openssl to get a reliable SHA-256 comparison.
  ALREADY_TRUSTED=false
  while IFS= read -r pem_cert; do
    fp=$(printf '%s' "$pem_cert" | openssl x509 -noout -fingerprint -sha256 2>/dev/null | sed 's/.*=//')
    if [[ "$fp" == "$CA_FINGERPRINT" ]]; then
      ALREADY_TRUSTED=true
      break
    fi
  done < <(security find-certificate -a -p /Library/Keychains/System.keychain 2>/dev/null \
    | awk '/BEGIN CERTIFICATE/{cert=""} {cert=cert $0 "\n"} /END CERTIFICATE/{print cert}')
  if $ALREADY_TRUSTED; then
    echo "✓ Hostr dev CA already trusted in system keychain"
  else
    echo "→ Adding Hostr dev CA to macOS system keychain (requires sudo)..."
    sudo security add-trusted-cert -d -r trustRoot \
      -k /Library/Keychains/System.keychain "$CA_CERT"
    echo "✓ Hostr dev CA trusted — browsers will show green lock for *.hostr.development"
  fi

elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ]; then
  # Debian / Ubuntu
  DEST="/usr/local/share/ca-certificates/hostr-dev-ca.crt"
  if [ -f "$DEST" ] && diff -q "$CA_CERT" "$DEST" >/dev/null 2>&1; then
    echo "✓ Hostr dev CA already installed"
  else
    echo "→ Adding Hostr dev CA to system trust store (requires sudo)..."
    sudo cp "$CA_CERT" "$DEST"
    sudo update-ca-certificates
    echo "✓ Hostr dev CA trusted"
  fi

elif [ -d /etc/pki/ca-trust/source/anchors ]; then
  # RHEL / Fedora / CentOS
  DEST="/etc/pki/ca-trust/source/anchors/hostr-dev-ca.crt"
  if [ -f "$DEST" ] && diff -q "$CA_CERT" "$DEST" >/dev/null 2>&1; then
    echo "✓ Hostr dev CA already installed"
  else
    echo "→ Adding Hostr dev CA to system trust store (requires sudo)..."
    sudo cp "$CA_CERT" "$DEST"
    sudo update-ca-trust
    echo "✓ Hostr dev CA trusted"
  fi

else
  echo "⚠️  Unknown OS — manually trust: $CA_CERT"
fi
