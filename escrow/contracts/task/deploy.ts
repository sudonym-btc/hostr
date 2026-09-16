import type { TransactionRequest } from 'ethers';
import type { NetworkConnection } from 'hardhat/types/network';
import fs from 'node:fs';
import path from 'node:path';
import { readCanonicalEscrowArtifact } from './artifact.js';

type ContractAddresses = {
  MultiEscrow?: string;
};

type AddressConfig = Record<string, ContractAddresses>;

function getAddressFilePath(): string {
  return path.resolve(process.cwd(), process.env.ADDRESS_FILE || 'contract-addresses.json');
}

function readExistingConfig(): AddressConfig {
  const filePath = getAddressFilePath();
  if (!fs.existsSync(filePath)) {
    return {};
  }

  return JSON.parse(fs.readFileSync(filePath, 'utf8')) as AddressConfig;
}

function writeConfig(config: AddressConfig): void {
  const filePath = getAddressFilePath();
  fs.writeFileSync(filePath, `${JSON.stringify(config, null, 2)}\n`);
  console.log(`Address file available at: "${path.basename(filePath)}"`);
}

function canonicalNetworkName(chainId: number, networkName: string): string {
  switch (chainId) {
    case 412346:
      return 'regtest';
    case 421614:
      return 'testnet';
    case 42161:
      return 'mainnet';
    case 31337:
      return 'hardhat';
    default:
      return networkName;
  }
}

async function resolveChainId(connection: NetworkConnection): Promise<number> {
  const configuredChainId = connection.networkConfig.chainId;
  if (configuredChainId != null) {
    return Number(configuredChainId);
  }

  const network = await connection.ethers.provider.getNetwork();
  return Number(network.chainId);
}

export async function deployEscrow(connection: NetworkConnection): Promise<void> {
  const chainId = await resolveChainId(connection);
  const networkName = canonicalNetworkName(chainId, connection.networkName);
  const networkKey = `${networkName}.${chainId}`;

  const [deployer] = await connection.ethers.getSigners();
  if (deployer == null) {
    throw new Error('No deployer account available. Set DEPLOYER_PRIVATE_KEY for the selected network.');
  }

  const artifact = readCanonicalEscrowArtifact();
  const factory = new connection.ethers.ContractFactory(artifact.abi, artifact.bytecode, deployer);
  const deployTx = (await factory.getDeployTransaction()) as TransactionRequest;
  const estimatedGas = await deployer.estimateGas(deployTx);
  const latestBlock = await connection.ethers.provider.getBlock('latest');
  const blockGasLimit = latestBlock?.gasLimit ?? estimatedGas;
  const paddedEstimate = (estimatedGas * 12n) / 10n;
  const safeGasLimit = paddedEstimate < blockGasLimit ? paddedEstimate : blockGasLimit - 100000n;

  const contract = await factory.deploy({ gasLimit: safeGasLimit });
  await contract.waitForDeployment();
  const contractAddress = await contract.getAddress();

  console.table({
    MultiEscrow: contractAddress,
  });

  const existing = readExistingConfig();
  const nextConfig: AddressConfig = {
    ...existing,
    [networkKey]: {
      ...(existing[networkKey] || {}),
      MultiEscrow: contractAddress,
    },
  };

  writeConfig(nextConfig);
}
