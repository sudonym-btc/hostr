import hardhatToolboxMochaEthers from '@nomicfoundation/hardhat-toolbox-mocha-ethers';
import { defineConfig, task } from 'hardhat/config';
import { deployEscrow } from './task/deploy.js';

const deploy = task('deploy', 'Deploy canonical NMDK MultiEscrow and record its address')
  .setInlineAction(async (_, hre) => {
    const connection = await hre.network.create(hre.globalOptions.network ?? 'hardhat');
    try {
      await deployEscrow(connection);
    } finally {
      await connection.close();
    }
  })
  .build();

const accounts = process.env.DEPLOYER_PRIVATE_KEY
  ? [process.env.DEPLOYER_PRIVATE_KEY]
  : [];

export default defineConfig({
  plugins: [hardhatToolboxMochaEthers],
  tasks: [deploy],
  networks: {
    localhost: { type: 'http', url: process.env.RPC_URL ?? 'http://127.0.0.1:8545', accounts },
    'arbitrum-sepolia': { type: 'http', url: 'https://sepolia-rollup.arbitrum.io/rpc', chainId: 421614, accounts },
    'arbitrum-one': { type: 'http', url: process.env.RPC_URL ?? 'https://arbitrum.gateway.tenderly.co', chainId: 42161, accounts },
    hardhat: {
      type: 'edr-simulated',
      chainId: 31337,
      accounts: [
        { privateKey: '0xa9cbe715ebaeb852bf7cc3d35f4a81b9a58f16705e4bb8434aa453093e612206', balance: '10000000000000000000000' },
        { privateKey: '0x1714ff69753ae70a91d6e1989cb1ee859b10e98239c61d28bcb0577d8d626b74', balance: '10000000000000000000000' },
      ],
    },
  },
});
