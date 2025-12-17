# Compile Swap ABIs

We use [Boltz](https://boltz.exchange/) to swap into and out of escrow contracts on [Rootstock](https://rootstock.io/)'s EVM L2.

To facilitate this, we require the [ABIs](https://www.quicknode.com/guides/ethereum-development/smart-contracts/what-is-an-abi) that Boltz makes available for their swaps, and the ABIs used for the escrow contract.

If we import the ABIs, we can use [web3dart](https://pub.dev/packages/web3dart) package and it's accompanying class builder to easily interact with any EVM compatible L2.
We only need to run this if there is a change in the ABIs, since the compiled dart is committed in the `/app` folder.

```bash
git clone git@github.com:BoltzExchange/boltz-core.git
(
    cd boltz-core && npm install && curl -L https://foundry.paradigm.xyz | bash && foundryup && npm run compile:solidity
)
cp ./boltz-core/out/**/* ./app/lib/data/sources/boltz/contracts
(
    cd ./app/lib/data/sources/boltz/contracts
    for file in *.json; do
        mv -- "$file" "${file%.json}.abi.json"
    done
)
```
