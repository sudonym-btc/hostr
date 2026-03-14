#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ENVIRONMENT="${1:-prod}"
load_managed_relay_env "$ENVIRONMENT" "$0"

ADMIN_PRIVATE_KEY="$(relay_admin_private_key "$0")"
WORKDIR="$(relay_wind_down_workdir)"

compose_run_rif_relay 'node <<"NODE"
const fs = require("fs");
const path = require("path");
const { BigNumber, Contract, Wallet, providers, utils, constants } = require("ethers");

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

async function sweepWallet(label, wallet, recipient, provider) {
  if (!wallet) {
    console.warn(`Skipping ${label} sweep because no keystore was found.`);
    return;
  }

  if (wallet.address.toLowerCase() === recipient.toLowerCase()) {
    return;
  }

  const gasPrice = await provider.getGasPrice();
  const gasLimit = BigNumber.from(21000);
  const txCost = gasPrice.mul(gasLimit);
  const balance = await provider.getBalance(wallet.address);

  if (balance.lte(txCost)) {
    console.log(`${label} balance too low to sweep: ${balance.toString()}`);
    return;
  }

  const value = balance.sub(txCost);
  const tx = await wallet.sendTransaction({
    to: recipient,
    value,
    gasLimit,
    gasPrice,
  });
  console.log(`Sweeping ${label} balance from ${wallet.address}: ${tx.hash}`);
  await tx.wait();
}

async function main() {
  const provider = new providers.JsonRpcProvider(rpcUrl);
  const relayHubAddress = resolveRelayHubAddress();
  const relayHub = new Contract(
    relayHubAddress,
    [
      "function getStakeInfo(address relayManager) view returns (tuple(uint256 stake,uint256 unstakeDelay,uint256 withdrawBlock,address owner))",
      "function withdrawStake(address relayManager)",
    ],
    provider
  );

  const adminWallet = new Wallet(adminPrivateKey, provider);
  const managerWallet = loadDerivedWallet("manager", provider);
  const workerWallet = loadDerivedWallet("workers", provider);
  const managerAddress = process.env.RIF_RELAY_MANAGER_ADDRESS || managerWallet?.address;

  if (!managerAddress) {
    throw new Error(
      `Unable to determine relay manager address. Set RIF_RELAY_MANAGER_ADDRESS or provide a keystore under ${path.join(workdir, "manager")}.`
    );
  }

  const stakeInfo = await relayHub.getStakeInfo(managerAddress);
  if (stakeInfo.owner !== zeroAddress && stakeInfo.owner.toLowerCase() !== adminWallet.address.toLowerCase()) {
    throw new Error(`Relay manager owner is ${stakeInfo.owner}, expected ${adminWallet.address}`);
  }

  if (stakeInfo.stake.gt(0)) {
    if (stakeInfo.withdrawBlock.eq(0)) {
      throw new Error("Stake is still locked. Run wind-down.sh first.");
    }

    const currentBlock = await provider.getBlockNumber();
    if (BigNumber.from(currentBlock).lt(stakeInfo.withdrawBlock)) {
      throw new Error(
        `Stake is not withdrawable yet. Current block ${currentBlock}, withdraw block ${stakeInfo.withdrawBlock.toString()}.`
      );
    }

    const withdrawTx = await relayHub.connect(adminWallet).withdrawStake(managerAddress);
    console.log(`Withdrawing relay manager stake: ${withdrawTx.hash}`);
    await withdrawTx.wait();
  } else {
    console.log(`No relay manager stake found for ${managerAddress}. Continuing with balance sweep.`);
  }

  await sweepWallet("worker", workerWallet, adminWallet.address, provider);
  await sweepWallet("manager", managerWallet, adminWallet.address, provider);
  console.log(`Completed relay balance recovery to ${adminWallet.address}.`);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
NODE' \
    -e ADMIN_PRIVATE_KEY="$ADMIN_PRIVATE_KEY" \
    -e RIF_RELAY_WIND_DOWN_WORKDIR="$WORKDIR"