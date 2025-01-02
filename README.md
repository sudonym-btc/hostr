# Rentals over nostr

This repo contains a client for managing listing and rental requests over the nostr network.

## Getting started

Install dependencies needed to compile https://github.com/SatoshiPortal/boltz-dart/tree/trunk

install android studio, command line tools and ndk (side-by-side)
```bash
git clone git@github.com:SatoshiPortal/boltz-dart.git
# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# install tools
cargo install flutter_rust_bridge_codegen --version 2.0.0
cargo install cargo-ndk
cargo install cargo-lipo

(cd ./boltz-dart && ./compile.native.sh)
```