import "@nomicfoundation/hardhat-toolbox";
import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    localhost: {
      url: process.env.RPC_URL ?? "http://127.0.0.1:8545",
    },
    hardhat: {
      mining: {
        auto: true,
        interval: 5000,
      },
      // Use only the predetermined key so that the sender and nonce remain fixed
      accounts: [{
        //Eth priv key generated from escrow key stub, 
        privateKey: '0xa9cbe715ebaeb852bf7cc3d35f4a81b9a58f16705e4bb8434aa453093e612206',
        balance: '10000000000000000000000'
      }, 
      {
        //Eth priv key generated from guest key stub, 
        privateKey: '0x1714ff69753ae70a91d6e1989cb1ee859b10e98239c61d28bcb0577d8d626b74',
        balance: '10000000000000000000000'
      }],
    },
  },
};

export default config;
