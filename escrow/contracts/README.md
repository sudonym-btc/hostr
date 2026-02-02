# Development and deployment of smart contracts

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Escrow.ts --network localhost
```

Run the node in docker-compose for ease-of-use.
If the contract is changed, re-run ./scripts/compile_abis.sh.

npx hardhat run task/fund.ts --network localhost
