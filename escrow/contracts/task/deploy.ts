import { TransactionRequest } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import fs from 'node:fs';
import path from 'node:path';

const ADDRESS_FILE = process.env.ADDRESS_FILE || 'contract-addresses.json';

type ContractAddresses = {
  MultiEscrow?: string;
};

type AddressConfig = Record<string, ContractAddresses>;

function getAddressFilePath(): string {
  return path.resolve(process.cwd(), ADDRESS_FILE);
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
    case 33:
      return 'regtest';
    case 31:
      return 'testnet';
    case 30:
      return 'mainnet';
    case 31337:
      return 'hardhat';
    default:
      return networkName;
  }
}

async function resolveChainId(hre: HardhatRuntimeEnvironment): Promise<number> {
  const configuredChainId = hre.network.config.chainId;
  if (configuredChainId != null) {
    return Number(configuredChainId);
  }

  const network = await hre.ethers.provider.getNetwork();
  return Number(network.chainId);
}

export async function deployEscrow(hre: HardhatRuntimeEnvironment): Promise<void> {
  const chainId = await resolveChainId(hre);
  const networkName = canonicalNetworkName(chainId, hre.network.name);
  const networkKey = `${networkName}.${chainId}`;

  const [deployer] = await hre.ethers.getSigners();
  if (deployer == null) {
    throw new Error('No deployer account available. Set DEPLOYER_PRIVATE_KEY for the selected network.');
  }

  const factory = await hre.ethers.getContractFactory('MultiEscrow', deployer);
  const deployTx = (await factory.getDeployTransaction()) as TransactionRequest;
  const estimatedGas = await deployer.estimateGas(deployTx);
  const latestBlock = await hre.ethers.provider.getBlock('latest');
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