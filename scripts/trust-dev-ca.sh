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

if [[ "$OSTYPE" == darwin* ]]; then
  # `security find-certificate -Z` outputs SHA-1 hashes; compute SHA-1 to match.
  CA_SHA1=$(openssl x509 -in "$CA_CERT" -noout -fingerprint -sha1 2>/dev/null \
    | sed 's/.*=//' | tr -d ':')
  EXISTING_HOSTR_SHAS=$(security find-certificate -a -c "Hostr Development CA" -Z /Library/Keychains/System.keychain 2>/dev/null \
    | awk '/SHA-1 hash:/ { print $3 }')

  if printf '%s\n' "$EXISTING_HOSTR_SHAS" | grep -qi "^${CA_SHA1}$"; then
    echo "✓ Hostr dev CA already trusted in system keychain"
  else
    if [ -n "$EXISTING_HOSTR_SHAS" ]; then
      echo "→ Replacing stale Hostr dev CA in macOS system keychain..."
      while IFS= read -r existing_sha; do
        [ -n "$existing_sha" ] || continue
        sudo security delete-certificate -Z "$existing_sha" -t /Library/Keychains/System.keychain 2>/dev/null || true
      done <<EOF
$EXISTING_HOSTR_SHAS
EOF
    else
      echo "→ Adding Hostr dev CA to macOS system keychain (requires sudo)..."
    fi

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
