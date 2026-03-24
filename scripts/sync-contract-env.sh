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
AA_FILE="${AA_CONTRACT_ADDRESSES_FILE:-$REPO_ROOT/docker/aa-contract-addresses.json}"
TOKEN_FILE="${TOKEN_ADDRESSES_FILE:-$REPO_ROOT/docker/data/arbitrum/token-addresses.json}"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing env file: $ENV_FILE" >&2
  exit 66
fi

if [ ! -f "$ESCROW_FILE" ]; then
  echo "Missing escrow contract manifest: $ESCROW_FILE" >&2
  exit 66
fi

if [ ! -f "$AA_FILE" ]; then
  echo "Missing AA contract manifest: $AA_FILE" >&2
  exit 66
fi

if [ ! -f "$TOKEN_FILE" ]; then
  echo "Missing token address manifest: $TOKEN_FILE (non-fatal)" >&2
  TOKEN_FILE=""
fi

node - "$TARGET_ENV" "$ENV_FILE" "$ESCROW_FILE" "$AA_FILE" "$TOKEN_FILE" <<'NODE'
const fs = require('fs');

const [targetEnv, envFile, escrowFile, aaFile, tokenFile] = process.argv.slice(2);

const NETWORK_KEY_BY_ENV = {
  local: 'regtest.412346',
  test: 'regtest.412346',
  staging: 'mainnet.42161',
  prod: 'mainnet.42161',
};

const BUNDLER_URL_BY_ENV = {
  local: 'https://paymaster.hostr.development',
  test: 'https://paymaster.hostr.development',
  staging: 'https://api.pimlico.io/v2/42161/rpc?apikey=pim_G4g94ATqJrxcLBtjxFf67f',
  prod: 'https://paymaster.hostr.network/rpc',
};

const keysToUpdate = [
  'ESCROW_CONTRACT_ADDRESS_KEY',
  'ESCROW_CONTRACT_ADDRESS',
  'AA_BUNDLER_URL',
  'AA_ENTRY_POINT_ADDRESS',
  'AA_ACCOUNT_FACTORY_ADDRESS',
  'AA_PAYMASTER_ADDRESS',
  'ARBITRUM_TBTC_ADDRESS',
  'ARBITRUM_TBTC_DECIMALS',
  'ARBITRUM_USDT_ADDRESS',
  'ARBITRUM_USDT_DECIMALS',
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
const aaConfig = parseAddressManifest(aaFile);
const tokenConfig = tokenFile ? parseAddressManifest(tokenFile) : {};
const envState = parseEnvFile(envFile);

const defaultNetworkKey = NETWORK_KEY_BY_ENV[targetEnv];
const escrowAddressKey = resolveNetworkKey(
  envState.entries,
  'ESCROW_CONTRACT_ADDRESS_KEY',
  defaultNetworkKey,
);
const aaAddressKey = defaultNetworkKey;

const escrowEntry = escrowConfig[escrowAddressKey] || {};
const aaEntry = aaConfig[aaAddressKey] || {};

const nextValues = {
  ESCROW_CONTRACT_ADDRESS_KEY: escrowAddressKey,
  ESCROW_CONTRACT_ADDRESS: requireAddress(
    escrowEntry.MultiEscrow,
    `escrow MultiEscrow address for ${escrowAddressKey} in ${escrowFile}`,
  ),
  AA_BUNDLER_URL: BUNDLER_URL_BY_ENV[targetEnv],
  AA_ENTRY_POINT_ADDRESS: requireAddress(
    aaEntry.EntryPoint,
    `AA EntryPoint address for ${aaAddressKey} in ${aaFile}`,
  ),
  AA_ACCOUNT_FACTORY_ADDRESS: requireAddress(
    aaEntry.SimpleAccountFactory,
    `AA SimpleAccountFactory address for ${aaAddressKey} in ${aaFile}`,
  ),
  AA_PAYMASTER_ADDRESS: requireAddress(
    aaEntry.VerifyingPaymaster,
    `AA VerifyingPaymaster address for ${aaAddressKey} in ${aaFile}`,
  ),
};

// Token addresses — optional (only present for local/test with deployed mocks).
const tokenEntry = tokenConfig[defaultNetworkKey] || {};
if (tokenEntry.tBTC) {
  nextValues.ARBITRUM_TBTC_ADDRESS = tokenEntry.tBTC.address;
  nextValues.ARBITRUM_TBTC_DECIMALS = String(tokenEntry.tBTC.decimals);
}
if (tokenEntry.USDT) {
  nextValues.ARBITRUM_USDT_ADDRESS = tokenEntry.USDT.address;
  nextValues.ARBITRUM_USDT_DECIMALS = String(tokenEntry.USDT.decimals);
}

const nextContent = updateEnvLines(envState.lines, nextValues);
fs.writeFileSync(envFile, nextContent);

for (const key of keysToUpdate) {
  console.log(`${key}=${nextValues[key]}`);
}
NODE
