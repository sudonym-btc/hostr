#!/bin/sh
# ──────────────────────────────────────────────────────────────
# generate-dev-certs.sh — Local Development CA & TLS certificates
#
# Generates a root CA and per-service certificates signed by it.
# All containers that mount the CA cert can validate each other.
#
# Output directory: /certs (mounted from ./docker/certs/)
# Convention follows jwilder/nginx-proxy: <VIRTUAL_HOST>.crt + .key
# ──────────────────────────────────────────────────────────────
set -eu

apk add --no-cache openssl >/dev/null 2>&1

CERT_DIR="${CERT_DIR:-/certs}"
CA_DIR="${CA_DIR:-/ca}"
DOMAIN="${DOMAIN:-hostr.development}"
DAYS=825  # Apple max for non-public CA certs

mkdir -p "$CERT_DIR" "$CA_DIR"

# ── Check if existing CA is still valid (>7 days) ──────────────
REGEN_CA=true
if [ -f "$CA_DIR/ca.crt" ] && [ -f "$CA_DIR/ca.key" ] && \
   openssl x509 -in "$CA_DIR/ca.crt" -noout -checkend 604800 2>/dev/null; then
  echo "✓ CA certificate still valid (>7 days remaining)"
  REGEN_CA=false
fi

# ── Generate Root CA ───────────────────────────────────────────
if [ "$REGEN_CA" = true ]; then
  echo "==> Generating Hostr Development Root CA"
  openssl genrsa -out "$CA_DIR/ca.key" 4096 2>/dev/null
  openssl req -x509 -new -nodes \
    -key "$CA_DIR/ca.key" \
    -sha256 -days "$DAYS" \
    -out "$CA_DIR/ca.crt" \
    -subj "/CN=Hostr Development CA/O=Hostr/OU=Development"
  echo "  ✓ CA created: $CA_DIR/ca.crt"
fi

# ── Helper: generate a certificate signed by the CA ────────────
generate_cert() {
  local name="$1"
  shift
  local san_entries="$*"

  # Skip if cert exists, is valid, and CA wasn't regenerated
  if [ "$REGEN_CA" = false ] && [ -f "$CERT_DIR/${name}.crt" ] && \
     openssl x509 -in "$CERT_DIR/${name}.crt" -noout -checkend 604800 2>/dev/null && \
     openssl verify -CAfile "$CA_DIR/ca.crt" "$CERT_DIR/${name}.crt" >/dev/null 2>&1; then
    echo "  ✓ ${name} — still valid, skipping"
    return
  fi

  echo "  → ${name}"

  local cnf
  cnf=$(mktemp)
  cat > "$cnf" <<CONF
[req]
distinguished_name = dn
req_extensions     = v3_req
prompt             = no

[dn]
CN = ${name}
O  = Hostr
OU = Development

[v3_req]
subjectAltName   = ${san_entries}
basicConstraints = CA:FALSE
keyUsage         = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
CONF

  openssl genrsa  -out "$CERT_DIR/${name}.key" 2048 2>/dev/null
  openssl req -new \
    -key  "$CERT_DIR/${name}.key" \
    -out  "$CERT_DIR/${name}.csr" \
    -config "$cnf" 2>/dev/null

  openssl x509 -req \
    -in      "$CERT_DIR/${name}.csr" \
    -CA      "$CA_DIR/ca.crt" \
    -CAkey   "$CA_DIR/ca.key" \
    -CAcreateserial \
    -out     "$CERT_DIR/${name}.crt" \
    -days    "$DAYS" -sha256 \
    -extfile "$cnf" -extensions v3_req 2>/dev/null

  rm -f "$CERT_DIR/${name}.csr" "$cnf"
}

# ── Generate service certificates ──────────────────────────────
echo "==> Generating service certificates"

generate_cert "relay.${DOMAIN}" \
  "DNS:relay.${DOMAIN},DNS:relay,DNS:localhost,IP:127.0.0.1"

generate_cert "blossom.${DOMAIN}" \
  "DNS:blossom.${DOMAIN},DNS:blossom,DNS:localhost,IP:127.0.0.1"

generate_cert "lnbits1.${DOMAIN}" \
  "DNS:lnbits1.${DOMAIN},DNS:lnbits1,DNS:localhost,IP:127.0.0.1"

generate_cert "lnbits2.${DOMAIN}" \
  "DNS:lnbits2.${DOMAIN},DNS:lnbits2,DNS:localhost,IP:127.0.0.1"

generate_cert "alby1.${DOMAIN}" \
  "DNS:alby1.${DOMAIN},DNS:alby1,DNS:albyhub1,DNS:localhost,IP:127.0.0.1"

generate_cert "alby2.${DOMAIN}" \
  "DNS:alby2.${DOMAIN},DNS:alby2,DNS:albyhub2,DNS:localhost,IP:127.0.0.1"

generate_cert "landing.${DOMAIN}" \
  "DNS:landing.${DOMAIN},DNS:${DOMAIN},DNS:landing-page,DNS:localhost,IP:127.0.0.1"

generate_cert "anvil.${DOMAIN}" \
  "DNS:anvil.${DOMAIN},DNS:anvil,DNS:localhost,IP:127.0.0.1"

# ── Create combined CA bundle (system CAs + our CA) ────────────
# Containers can set SSL_CERT_FILE=/tls/ca-bundle.crt to trust
# both public CAs and our development CA.
echo "==> Creating combined CA bundle"
if [ -f /etc/ssl/certs/ca-certificates.crt ]; then
  cat /etc/ssl/certs/ca-certificates.crt "$CA_DIR/ca.crt" > "$CA_DIR/ca-bundle.crt"
else
  cp "$CA_DIR/ca.crt" "$CA_DIR/ca-bundle.crt"
fi

echo ""
echo "==> All certificates generated ✓"
echo "    CA cert:   ${CA_DIR}/ca.crt"
echo "    CA bundle: ${CA_DIR}/ca-bundle.crt"
ls -1 "$CERT_DIR"/*.crt 2>/dev/null | sed 's/^/    /'
