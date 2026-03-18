#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ENVIRONMENT="${1:-prod}"
load_managed_relay_env "$ENVIRONMENT" "$0"

ADMIN_PRIVATE_KEY="$(relay_admin_private_key "$0")"
WORKDIR="$(relay_wind_down_workdir)"

compose_run_rif_relay 'cd /rif-relay-server && node <<"NODE"
const fs = require("fs");
const path = require("path");
const { Contract, Wallet, providers, utils, constants } = require("ethers");

const zeroAddress = constants.AddressZero;
const addressFile = process.env.RIF_RELAY_ADDRESS_FILE || "/rif-relay-contracts/contract-addresses.json";
const addressKey = process.env.RIF_RELAY_ADDRESS_KEY || "mainnet.30";
const workdir = process.env.RIF_RELAY_WIND_DOWN_WORKDIR || "/srv/app/environment";
const rpcUrl = process.env.RIF_RELAY_RSK_NODE_URL || process.env.RPC_URL;
const adminPrivateKey = process.env.ADMIN_PRIVATE_KEY;

if (!rpcUrl) {
  throw new Error("Missing RPC_URL or RIF_RELAY_RSK_NODE_URL");
}

if (!adminPrivateKey) {
  throw new Error("Missing ADMIN_PRIVATE_KEY");
}

function firstNonEmpty(values) {
  return values.find((value) => typeof value === "string" && value.trim() !== "") || "";
}

function readAddressManifest() {
  if (!fs.existsSync(addressFile)) {
    return {};
  }

  const raw = fs.readFileSync(addressFile, "utf8");
  const parsed = JSON.parse(raw);
  return parsed[addressKey] || {};
}

function resolveRelayHubAddress() {
  const manifest = readAddressManifest();
  const relayHubAddress = firstNonEmpty([
    process.env.RIF_RELAY_HUB_ADDRESS,
    manifest.RelayHub,
  ]);

  if (!relayHubAddress) {
    throw new Error(
      `Missing relay hub address. Populate ${addressFile} under ${addressKey} or set RIF_RELAY_HUB_ADDRESS.`
    );
  }

  return relayHubAddress;
}

function loadDerivedWallet(subdir, provider) {
  const keystorePath = path.join(workdir, subdir, "keystore");
  if (!fs.existsSync(keystorePath)) {
    return null;
  }

  const { seed } = JSON.parse(fs.readFileSync(keystorePath, "utf8"));
  if (typeof seed !== "string" || seed.trim() === "") {
    throw new Error(`Invalid keystore seed in ${keystorePath}`);
  }

  const hdNode = utils.HDNode.fromSeed(seed.startsWith("0x") ? seed : `0x${seed}`);
  const child = hdNode.derivePath("0");
  return new Wallet(child.privateKey, provider);
}

async function main() {
  const provider = new providers.JsonRpcProvider(rpcUrl);
  const relayHubAddress = resolveRelayHubAddress();
  const relayHub = new Contract(
    relayHubAddress,
    [
      "function getStakeInfo(address relayManager) view returns (tuple(uint256 stake,uint256 unstakeDelay,uint256 withdrawBlock,address owner))",
      "function disableRelayWorkers(address[] relayWorkers)",
      "function unlockStake(address relayManager)",
    ],
    provider
  );

  const adminWallet = new Wallet(adminPrivateKey, provider);
  const managerWallet = loadDerivedWallet("manager", provider);
  const workerWallet = loadDerivedWallet("workers", provider);
  const managerAddress = process.env.RIF_RELAY_MANAGER_ADDRESS || managerWallet?.address;
  const workerAddress = process.env.RIF_RELAY_WORKER_ADDRESS || workerWallet?.address || null;

  if (!managerAddress) {
    throw new Error(
      `Unable to determine relay manager address. Set RIF_RELAY_MANAGER_ADDRESS or provide a keystore under ${path.join(workdir, "manager")}.`
    );
  }

  let stakeInfo = await relayHub.getStakeInfo(managerAddress);
  if (stakeInfo.owner !== zeroAddress && stakeInfo.owner.toLowerCase() !== adminWallet.address.toLowerCase()) {
    throw new Error(`Relay manager owner is ${stakeInfo.owner}, expected ${adminWallet.address}`);
  }

  if (managerWallet && workerAddress) {
    try {
      const disableTx = await relayHub.connect(managerWallet).disableRelayWorkers([workerAddress]);
      console.log(`Disabled relay worker ${workerAddress}: ${disableTx.hash}`);
      await disableTx.wait();
    } catch (error) {
      console.warn(`Skipping relay worker disable step: ${error.message}`);
    }
  } else {
    console.warn(
      "Skipping relay worker disable step because the manager/worker keystore was not found. " +
        "Set RIF_RELAY_WIND_DOWN_WORKDIR, RIF_RELAY_MANAGER_ADDRESS, and RIF_RELAY_WORKER_ADDRESS if you need this in a custom setup."
    );
  }

  stakeInfo = await relayHub.getStakeInfo(managerAddress);
  if (stakeInfo.stake.eq(0)) {
    console.log(`No stake found for relay manager ${managerAddress}. Nothing to unlock.`);
    return;
  }

  if (!stakeInfo.withdrawBlock.eq(0)) {
    const currentBlock = await provider.getBlockNumber();
    const remainingBlocks = stakeInfo.withdrawBlock.sub(currentBlock);
    console.log(
      remainingBlocks.gt(0)
        ? `Stake already unlocked. Withdraw will be available at block ${stakeInfo.withdrawBlock.toString()} (${remainingBlocks.toString()} blocks remaining).`
        : `Stake already unlocked and withdrawable since block ${stakeInfo.withdrawBlock.toString()}.`
    );
    return;
  }

  const unlockTx = await relayHub.connect(adminWallet).unlockStake(managerAddress);
  console.log(`Unlocked relay manager stake: ${unlockTx.hash}`);
  await unlockTx.wait();

  const unlockedStakeInfo = await relayHub.getStakeInfo(managerAddress);
  const currentBlock = await provider.getBlockNumber();
  const remainingBlocks = unlockedStakeInfo.withdrawBlock.sub(currentBlock);
  console.log(
    `Relay manager ${managerAddress} unlocked. ` +
      `Stake withdraw becomes available at block ${unlockedStakeInfo.withdrawBlock.toString()} ` +
      `(${remainingBlocks.gt(0) ? remainingBlocks.toString() : "0"} blocks remaining).`
  );
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
NODE' \
    -e ADMIN_PRIVATE_KEY="$ADMIN_PRIVATE_KEY" \
    -e RIF_RELAY_WIND_DOWN_WORKDIR="$WORKDIR"