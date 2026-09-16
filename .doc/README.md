# [<img src="./app/assets/images/logo/logo.svg" width="32">](https://hostr.network) Hostr

[![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)

Rental accommodation using purely peer‑to‑peer technologies such as [Nostr](https://nostr.com/).

<p align="start">

<img src="./app/screenshots/iphone_17_pro_max/dark/explore.png" alt="Explore page" width=200 style="max-width:300px;">&nbsp;
<img src="./app/screenshots/iphone_17_pro_max/dark/listing.png" alt="Listing page" width=200 style="max-width:300px;">&nbsp;
<img src="./app/screenshots/iphone_17_pro_max/dark/threads.png" alt="Threads page" width=200 style="max-width:300px;">&nbsp;
<img src="./app/screenshots/iphone_17_pro_max/dark/thread.png" alt="Thread page" width=200 style="max-width:300px;">&nbsp;
<img src="./app/screenshots/iphone_17_pro_max/dark/payment.png" alt="Payment page" width=200 style="max-width:300px;">&nbsp;

</p>

Read docs in full [here](https://sudonym-btc.github.io/hostr/).

This repo contains

```bash
.
├── app                 # Flutter client app deployed to stores and web
├── hostr_sdk           # Hostr relay, booking, messaging, and driver adapters
├── hostr_cli           # CLI and Dart daemon used by MCP/local automation
├── escrow              # Escrow daemon and canonical contract deployment tooling
├── ai                  # Node/TypeScript MCP server and agent-facing automation
├── infrastructure      # Terraform, DNS, CI deploy, and hosted VM setup
├── docker              # Local/dev service config for relay, blossom, EVM, observability
├── dependencies/nmdk   # Shared models, payment drivers, contracts, and NIP drafts
└── scripts             # Bootstrap, deploy, ABI, TLS, screenshot, and helper scripts
```

- Client [README](./app/README.md)
- Infrastructure [README](./infrastructure/README.md)
- Escrow [README](./escrow/README.md)
- AI [README](./ai/README.md)

## Protocol specifications

NMDK owns the protocol drafts used by Hostr. These pages render the canonical
specifications directly from the pinned NMDK submodules.

- [Marketplace listings](./specifications/listings.md)
- [Accommodation listings](./specifications/accommodation.md)
- [Orders and settlement](./specifications/orders.md)
- [Arbitration services](./specifications/arbitration.md)
- [Auctions](./specifications/auctions.md)

## Clone

```bash
git clone --recursive git@github.com:sudonym-btc/hostr.git
```

Quickstart: see the client app guide at `app/README.md` for run targets by environment.
