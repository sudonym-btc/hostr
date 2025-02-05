
[![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)


# [<img src="app/assets/images/logo/logo_icon/logo.png" width="32">](https://hostr.network) Hostr

Rental accomodation using purely peer-to-peer technologies such as [Nostr](https://nostr.com/).

This repo contains

```bash
.
├── app                 # Client app deployed to store
├── escrow              # Server side daemon to arbitrate txns
├── infrastructure      # Infrastructure-as-as code required to run the project
└── README.md               
```

- Client [README](./app/README.md)
- Infrastructure [README](./infrastructure/README.md)
- Escrow [README](./escrow/README.md)
- Accommodation [NIP](../NIP)
- Escrow [NIP](../NIP)

## NIPs used

## NIPs Utilized

- **NIP-01**: Basic protocol for event creation and subscription.
- **NIP-04**: Encrypted direct messages for secure communication between hosts and guests. (Deprecated)
- [**NIP-47**](https://github.com/nostr-protocol/nips/blob/master/17.md): Private Direct Messages
 
- **NIP-05**: Mapping Nostr keys to DNS-based internet identifiers.
- **NIP-09**: Event deletion for removing listings or messages.
- **NIP-33**: Parameterized replaceable events for creating and updating listings and bookings.

## Getting started

```bash
git clone git@github.com:sudonym-btc/hostr.git
npm install -g semantic-release@18
```

<!-- Install dependencies needed to compile https://github.com/SatoshiPortal/boltz-dart/tree/trunk

install android studio, command line tools and ndk (side-by-side)
```bash
git clone git@github.com:SatoshiPortal/boltz-dart.git
# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# install tools
cargo install flutter_rust_bridge_codegen --version 2.0.0
cargo install cargo-ndk
cargo install cargo-lipo

(cd ./boltz-dart && ./compile.native.sh) -->
<!-- ``` -->

### App side EVM compatibility

We use [Boltz](https://boltz.exchange/) to swap into and out of escrow contracts on [Rootstock](https://rootstock.io/)'s EVM L2.

To facilitate this, we require the [ABIs](https://www.quicknode.com/guides/ethereum-development/smart-contracts/what-is-an-abi) that Boltz makes available for their swaps, and the ABIs used for the escrow contract.

If we import the ABIs, we can use [web3dart](https://pub.dev/packages/web3dart) package and it's accompanying class builder to easily interact with any EVM compatible L2.
We only need to run this if there is a change in the ABIs, since the compiled dart is committed in the `/app` folder.

``` bash
git@github.com:BoltzExchange/boltz-core.git
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
