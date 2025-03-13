# App

[![codecov](https://codecov.io/gh/sudonym-btc/hostr/branch/main/graph/badge.svg?token=YOUR_TOKEN)](https://codecov.io/gh/sudonym-btc/hostr)

This is a client that displays and posts events related to short term accommodation lets over the nostr network.

<p align="start">

<img src="/app/screenshots/home.png" alt="Home page" width=200 style="max-width:300px;">&nbsp;
<img src="/app/screenshots/listing.png" alt="Listing page" width=200 style="max-width:300px;">&nbsp;
<img src="/app/screenshots/threads.png" alt="Listing page" width=200 style="max-width:300px;">&nbsp;
<img src="/app/screenshots/thread.png" alt="Listing page" width=200 style="max-width:300px;">&nbsp;
<img src="/app/screenshots/thread_pay.png" alt="Listing page" width=200 style="max-width:300px;">&nbsp;

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

## Improvements

- Swap in transaction should go straight into the contract
- Escrow contract COULD encode bolt12, and then escrcow can do the swap by proving they paid a corresponding bolt11 invoice and releasing the funds to themselves. Out of scope.

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
