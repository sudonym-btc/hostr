#!/usr/bin/env bash
set -euo pipefail

node <<'NODE'
const fs = require('fs');

const zeroAddress = '0x0000000000000000000000000000000000000000';
const addressFile = process.env.RIF_RELAY_ADDRESS_FILE || '/rif-relay-contracts/contract-addresses.json';
const addressKey = process.env.RIF_RELAY_ADDRESS_KEY || 'mainnet.30';

function readAddressManifest() {
  if (!fs.existsSync(addressFile)) {
    return {};
  }

  const raw = fs.readFileSync(addressFile, 'utf8');
  const parsed = JSON.parse(raw);
  return parsed[addressKey] || {};
}

function firstNonEmpty(values) {
  return values.find((value) => typeof value === 'string' && value.trim() !== '') || '';
}

const manifest = readAddressManifest();
const relayHubAddress = firstNonEmpty([
  process.env.RIF_RELAY_HUB_ADDRESS,
  manifest.RelayHub,
]);
const deployVerifierAddress = firstNonEmpty([
  process.env.RIF_RELAY_DEPLOY_VERIFIER_ADDRESS,
  manifest.DeployVerifier,
  manifest.BoltzDeployVerifier,
  manifest.MinimalBoltzDeployVerifier,
  manifest.CustomSmartWalletDeployVerifier,
  manifest.NativeHolderSmartWalletDeployVerifier,
]);
const relayVerifierAddress = firstNonEmpty([
  process.env.RIF_RELAY_RELAY_VERIFIER_ADDRESS,
  manifest.RelayVerifier,
  manifest.BoltzRelayVerifier,
  manifest.MinimalBoltzRelayVerifier,
  manifest.CustomSmartWalletRelayVerifier,
  manifest.NativeHolderSmartWalletRelayVerifier,
]);

const missing = [];
if (!relayHubAddress) missing.push('relayHubAddress');
if (!deployVerifierAddress) missing.push('deployVerifierAddress');
if (!relayVerifierAddress) missing.push('relayVerifierAddress');
if (missing.length > 0) {
  throw new Error(
    `Missing relay addresses: ${missing.join(', ')}. ` +
      `Populate ${addressFile} under key ${addressKey} or set explicit RIF_RELAY_* env vars.`
  );
}

const trustedVerifiers = Array.from(
  new Set([deployVerifierAddress, relayVerifierAddress].filter(Boolean))
);

const config = {
  app: {
    url: process.env.RIF_RELAY_PUBLIC_URL,
    port: Number(process.env.RIF_RELAY_PORT || '8090'),
    devMode: false,
    logLevel: Number(process.env.RIF_RELAY_LOG_LEVEL || '2'),
    workdir: process.env.RIF_RELAY_WORKDIR || '/srv/app/environment',
  },
  blockchain: {
    rskNodeUrl: process.env.RIF_RELAY_RSK_NODE_URL || process.env.RPC_URL || 'https://public-node.rsk.co',
    workerMinBalance: process.env.RIF_RELAY_WORKER_MIN_BALANCE || '1000000000000000',
    workerTargetBalance: process.env.RIF_RELAY_WORKER_TARGET_BALANCE || '3000000000000000',
    managerMinBalance: process.env.RIF_RELAY_MANAGER_MIN_BALANCE || '1000000000000000',
    managerMinStake: 1,
    managerTargetBalance: process.env.RIF_RELAY_MANAGER_TARGET_BALANCE || '3000000000000000',
    initialBlockToScan: Number(process.env.RIF_RELAY_INITIAL_BLOCK_TO_SCAN || '1'),
  },
  contracts: {
    relayHubAddress,
    relayVerifierAddress,
    deployVerifierAddress,
    feesReceiver: process.env.RIF_RELAY_FEES_RECEIVER || zeroAddress,
    trustedVerifiers,
  },
  register: {
    stake: process.env.REGISTER_STAKE || '0.0001',
    funds: process.env.REGISTER_FUNDS || '0.02',
    gasPrice: Number(process.env.REGISTER_GAS_PRICE || '60000000'),
    unstakeDelay: Number(process.env.REGISTER_UNSTAKE_DELAY || '1000'),
  },
};

if (process.env.RIF_RELAY_DISABLE_SPONSORED_TX != null) {
  config.app.disableSponsoredTx = process.env.RIF_RELAY_DISABLE_SPONSORED_TX === 'true';
}

if (process.env.RIF_RELAY_GAS_FEE_PERCENTAGE != null) {
  config.app.gasFeePercentage = process.env.RIF_RELAY_GAS_FEE_PERCENTAGE;
}

if ((process.env.REGISTER_PRIVATE_KEY || '').trim() !== '') {
  config.register.privateKey = process.env.REGISTER_PRIVATE_KEY;
}

fs.writeFileSync('/rif-relay-server/config/local.json5', `${JSON.stringify(config, null, 2)}\n`);
NODE
