#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_ENV="${1:-}"

case "$TARGET_ENV" in
  local|test|staging|prod) ;;
  *)
    echo "Usage: $0 [local|test|staging|prod]" >&2
    exit 64
    ;;
esac

ENV_FILE="$REPO_ROOT/.env.$TARGET_ENV"
ESCROW_FILE="${ESCROW_CONTRACT_ADDRESSES_FILE:-$REPO_ROOT/escrow/contracts/contract-addresses.json}"
RIF_RELAY_FILE="${RIF_RELAY_CONTRACT_ADDRESSES_FILE:-$REPO_ROOT/dependencies/rif-relay-contracts/contract-addresses.json}"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing env file: $ENV_FILE" >&2
  exit 66
fi

if [ ! -f "$ESCROW_FILE" ]; then
  echo "Missing escrow contract manifest: $ESCROW_FILE" >&2
  exit 66
fi

if [ ! -f "$RIF_RELAY_FILE" ]; then
  echo "Missing rif-relay contract manifest: $RIF_RELAY_FILE" >&2
  exit 66
fi

node - "$TARGET_ENV" "$ENV_FILE" "$ESCROW_FILE" "$RIF_RELAY_FILE" <<'NODE'
const fs = require('fs');

const [targetEnv, envFile, escrowFile, rifRelayFile] = process.argv.slice(2);

const NETWORK_KEY_BY_ENV = {
  local: 'regtest.33',
  test: 'regtest.33',
  staging: 'mainnet.30',
  prod: 'mainnet.30',
};

const keysToUpdate = [
  'ESCROW_CONTRACT_ADDRESS_KEY',
  'ESCROW_CONTRACT_ADDRESS',
  'RIF_RELAY_ADDRESS_KEY',
  'RIF_RELAY_HUB_ADDRESS',
  'RIF_RELAY_DEPLOY_VERIFIER_ADDRESS',
  'RIF_RELAY_RELAY_VERIFIER_ADDRESS',
  'RIF_RELAY_SMARTWALLET_FACTORY_ADDRESS',
];

function parseAddressManifest(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function parseEnvFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split(/\r?\n/);
  const entries = new Map();

  for (const line of lines) {
    const match = /^([A-Z0-9_]+)=(.*)$/.exec(line);
    if (!match) continue;
    entries.set(match[1], match[2]);
  }

  return { lines, entries };
}

function nonEmpty(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function resolveNetworkKey(envEntries, keyName, fallback) {
  const existing = envEntries.get(keyName);
  return nonEmpty(existing) ? existing.trim() : fallback;
}

function requireAddress(value, label) {
  if (!nonEmpty(value)) {
    throw new Error(`Missing ${label}`);
  }
  return value.trim();
}

function updateEnvLines(lines, values) {
  const nextLines = [...lines];
  const seen = new Set();

  for (let i = 0; i < nextLines.length; i += 1) {
    const match = /^([A-Z0-9_]+)=(.*)$/.exec(nextLines[i]);
    if (!match) continue;
    const key = match[1];
    if (!(key in values)) continue;
    nextLines[i] = `${key}=${values[key]}`;
    seen.add(key);
  }

  const missing = Object.keys(values).filter((key) => !seen.has(key));
  if (missing.length > 0) {
    if (nextLines.length > 0 && nextLines[nextLines.length - 1] !== '') {
      nextLines.push('');
    }
    for (const key of missing) {
      nextLines.push(`${key}=${values[key]}`);
    }
  }

  return `${nextLines.join('\n').replace(/\n*$/, '')}\n`;
}

const escrowConfig = parseAddressManifest(escrowFile);
const rifRelayConfig = parseAddressManifest(rifRelayFile);
const envState = parseEnvFile(envFile);

const defaultNetworkKey = NETWORK_KEY_BY_ENV[targetEnv];
const escrowAddressKey = resolveNetworkKey(
  envState.entries,
  'ESCROW_CONTRACT_ADDRESS_KEY',
  defaultNetworkKey,
);
const rifRelayAddressKey = resolveNetworkKey(
  envState.entries,
  'RIF_RELAY_ADDRESS_KEY',
  defaultNetworkKey,
);

const escrowEntry = escrowConfig[escrowAddressKey] || {};
const rifRelayEntry = rifRelayConfig[rifRelayAddressKey] || {};

const nextValues = {
  ESCROW_CONTRACT_ADDRESS_KEY: escrowAddressKey,
  ESCROW_CONTRACT_ADDRESS: requireAddress(
    escrowEntry.MultiEscrow,
    `escrow MultiEscrow address for ${escrowAddressKey} in ${escrowFile}`,
  ),
  RIF_RELAY_ADDRESS_KEY: rifRelayAddressKey,
  RIF_RELAY_HUB_ADDRESS: requireAddress(
    rifRelayEntry.RelayHub,
    `rif-relay RelayHub address for ${rifRelayAddressKey} in ${rifRelayFile}`,
  ),
  RIF_RELAY_DEPLOY_VERIFIER_ADDRESS: requireAddress(
    rifRelayEntry.DeployVerifier || rifRelayEntry.BoltzDeployVerifier || rifRelayEntry.MinimalBoltzDeployVerifier,
    `rif-relay deploy verifier for ${rifRelayAddressKey} in ${rifRelayFile}`,
  ),
  RIF_RELAY_RELAY_VERIFIER_ADDRESS: requireAddress(
    rifRelayEntry.RelayVerifier || rifRelayEntry.BoltzRelayVerifier || rifRelayEntry.MinimalBoltzRelayVerifier,
    `rif-relay relay verifier for ${rifRelayAddressKey} in ${rifRelayFile}`,
  ),
  RIF_RELAY_SMARTWALLET_FACTORY_ADDRESS: requireAddress(
    rifRelayEntry.SmartWalletFactory || rifRelayEntry.BoltzSmartWalletFactory || rifRelayEntry.MinimalBoltzSmartWalletFactory,
    `rif-relay smart wallet factory for ${rifRelayAddressKey} in ${rifRelayFile}`,
  ),
};

const nextContent = updateEnvLines(envState.lines, nextValues);
fs.writeFileSync(envFile, nextContent);

for (const key of keysToUpdate) {
  console.log(`${key}=${nextValues[key]}`);
}
NODE
