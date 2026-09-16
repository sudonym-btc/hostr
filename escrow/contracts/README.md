# Hostr contract deployment wrapper

This package deploys NMDK's canonical `MultiEscrow` artifact. Solidity source,
compiler settings, ABI and bytecode are owned by
`dependencies/nmdk/dependencies/marketplace-evm-contracts`; Hostr does not compile
a separate escrow implementation.

```sh
npm run compile
npm test
npx hardhat deploy --network localhost
```

`compile` validates the canonical artifact without generating a local copy.
The Hardhat 3 deployment task reads its ABI and bytecode directly into an ethers
factory. `NMDK_ESCROW_ARTIFACT` supplies the artifact path in a packaged
environment. There is no Hostr contract compiler or local artifact store.

The deployment task preserves `contract-addresses.json` entries and updates the
selected `${network}.${chainId}`. Configure `RPC_URL` and
`DEPLOYER_PRIVATE_KEY` for the destination chain.

Each deployment creates the current canonical contract (v7) and replaces the
selected network's recorded address, including when an older address is already
present. Existing contract bytecode is immutable; this is a fresh deployment,
not an in-place update. Because Hostr is not live, local development chains,
seeded events and operation journals can be reset and recreated for this cutover.
No v6 compatibility or data-migration layer is required. Regenerate the consuming
environment with `scripts/sync-contract-env.sh` after deployment, then reseed.

Compose provides NMDK's contract directory as a named Docker build context. For a
standalone build from the Hostr repository root, use:

```sh
docker build \
  --build-context nmdk-contracts=./dependencies/nmdk/dependencies/marketplace-evm-contracts \
  -f escrow/contracts/Dockerfile escrow/contracts
```

The regression suite tests native and ERC-20 release, claim,
arbitration, withdrawals, deposits and signatures against the canonical
artifact. Its mintable token is a test fixture. Withdrawal signatures include
the v7 nonce, and a deployment test checks the
deployed EIP-712 version and preservation of other network addresses.

After changing the contract, regenerate the canonical NMDK artifacts and driver
bindings there before deploying. Hostr's former sample funding script and
duplicate escrow/Boltz Solidity sources have been removed.
