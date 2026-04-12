# App

[![codecov](https://codecov.io/gh/sudonym-btc/hostr/branch/main/graph/badge.svg?token=YOUR_TOKEN)](https://codecov.io/gh/sudonym-btc/hostr)

This is a client that displays and posts events related to short term accommodation lets over the nostr network.

<p align="start">

<img src="../screenshots/iphone_17_pro_max/dark/explore.png" alt="Explore page" width=200 style="max-width:300px;">&nbsp;
<img src="../screenshots/iphone_17_pro_max/dark/listing.png" alt="Listing page" width=200 style="max-width:300px;">&nbsp;
<img src="../screenshots/iphone_17_pro_max/dark/threads.png" alt="Threads page" width=200 style="max-width:300px;">&nbsp;
<img src="../screenshots/iphone_17_pro_max/dark/thread.png" alt="Thread page" width=200 style="max-width:300px;">&nbsp;
<img src="../screenshots/iphone_17_pro_max/dark/payment.png" alt="Payment page" width=200 style="max-width:300px;">&nbsp;

</p>

## Getting Started

Install [Flutter](https://docs.flutter.dev/get-started/install)
By default flutter launches in `mock` mode. It will not attempt to connect to relays or swap services. To connect to other environments, check the VSCode debug launcher.

```bash
flutter run
```

## Structure

```bash
./lib
├── config            # Configs like default relays and EVM-RPC URLs
├── core              # Utils and mic
├── data
    ├── models        # Data models and mock data
    └── repositories  # Classes for fetching certain types of data
├── logic             # How data flows through app
├── presentation      # How data looks
└── README.md
```

## NIPs Utilized

- **NIP-01**: Basic protocol for event creation and subscription.
- **NIP-05**: Mapping Nostr keys to DNS-based internet identifiers.
- **NIP-09**: Event deletion for removing listings or messages.
- **NIP-17**: Encrypted direct messages for secure communication between hosts and guests.
- **NIP-33**: Parameterized replaceable events for creating and updating listings and bookings.

## Dependency injection and mocking

- Each `Screen` widget just handles the mapping of query and path parameters onto it's corresponding `View` widget. This allows for catalogging widgets while only using their TypeSafe parameters, rather than having to pass in query strings etc.

## Generating screenshots

To generate screenshots of the app run

```
./scripts/screenshots.sh
```

Screenshots will be saved in `app/screenshot`.

## Compile ABIs

We use [Boltz](https://boltz.exchange/) to swap into and out of escrow contracts on [Arbitrum](https://arbitrum.io/)'s EVM L2.

To facilitate this, we require the [ABIs](https://www.quicknode.com/guides/ethereum-development/smart-contracts/what-is-an-abi) that Boltz makes available for their swaps, and the ABIs used for the escrow contract.

If we import the ABIs, we can use [web3dart](https://pub.dev/packages/web3dart) package and it's accompanying class builder to easily interact with any EVM compatible L2.
We only need to run this if there is a change in the ABIs, since the compiled dart is committed in the `/app` folder.

```bash
./scripts/compile_abis.sh
```

## Assets

The `assets` directory houses images, fonts, and any other files you want to
include with your application.

The `assets/images` directory contains [resolution-aware
images](https://flutter.dev/docs/development/ui/assets-and-images#resolution-aware).

## Localization

This project generates localized messages based on arb files found in
the `lib/_localization` directory.

To support additional languages, please visit the tutorial on
[Internationalizing Flutter
apps](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)
