# [<img src="/app/assets/images/logo/logo.svg" width="32">](https://hostr.network) Hostr

[![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)

Rental accommodation using purely peer‑to‑peer technologies such as [Nostr](https://nostr.com/).

<p align="start">

<img src="/app/screenshots/home.png" alt="Home page" width=200 style="max-width:300px;">&nbsp;
<img src="/app/screenshots/listing.png" alt="Listing page" width=200 style="max-width:300px;">&nbsp;
<img src="/app/screenshots/threads.png" alt="Listing page" width=200 style="max-width:300px;">&nbsp;
<img src="/app/screenshots/thread.png" alt="Listing page" width=200 style="max-width:300px;">&nbsp;
<img src="/app/screenshots/thread_pay.png" alt="Listing page" width=200 style="max-width:300px;">&nbsp;

</p>

Read docs in full [here](https://sudonym-btc.github.io/hostr/).

This repo contains

```bash
.
├── app                 # Client app deployed to store
├── hostr_sdk           # Code to interact with relays and hostr-specific models
├── escrow              # Server side daemon to arbitrate txns
├── models              # Custom Nostr Event types and their validations
├── infrastructure      # Infrastructure-as-as code required to run the project
└── README.md
```

- Client [README](./app/README.md)
- Infrastructure [README](./infrastructure/README.md)
- Escrow [README](./escrow/README.md)
- Accommodation [NIP](../NIP)
- Escrow [NIP](../NIP)

## NIPs utilized

- [**NIP-01**](https://github.com/nostr-protocol/nips/blob/master/01.md): Basic protocol for event creation and subscription.
- [**NIP-04**](https://github.com/nostr-protocol/nips/blob/master/04.md): Encrypted direct messages for secure communication between hosts and guests. (Deprecated)
- [**NIP-17**](https://github.com/nostr-protocol/nips/blob/master/17.md): Private Direct Messages

- [**NIP-05**](https://github.com/nostr-protocol/nips/blob/master/05.md): Mapping Nostr keys to DNS-based internet identifiers.
- [**NIP-09**](https://github.com/nostr-protocol/nips/blob/master/09.md): Event deletion for removing listings or messages.
- [**NIP-33**](https://github.com/nostr-protocol/nips/blob/master/33.md): Parameterized replaceable events for creating and updating listings and bookings.

## Clone

```bash
git clone --recursive git@github.com:sudonym-btc/hostr.git
```

Quickstart: see the client app guide at `app/README.md` for run targets by environment.

## TODO

### App

P1

- [ ] Background worker: https://docs.page/fluttercommunity/flutter_workmanager/quickstart
  - [ ] Must show notifications for items not already in thread messaege sync hydrated cubit
- [ ] Rif-relay mocking
- [ ] Event validation - async?
- [ ] Startup loading page
  - [x] Sync giftwraps
  - [ ] Broadcast preferred user blossom servers if not found
  - [ ] Broadcast preferred user relays if not found
  - [ ] Broadcast preferred user escrows if not found
- [ ] Blossom files
  - [ ] Image component which loads pubkeys blossom servers and generates file path
  - [ ] Caching of blossom servers between Image components
  - [ ] Blossom server infrastructure
- [ ] State management
  - [ ] Update Nip01Events in EntityCubit / ListCubits if they are updated
  - [ ] Form Location Input
  - [ ] Form Image Input
- [ ] Settings
  - [ ] Update relays
  - [ ] Update trusted escrows
  - [ ] Display public / private keys
- [ ] Escrow
  - [ ] Escrow advertisement events should allow for multiple services in one advertisement event
- [ ] Reservation Requests
  - [ ] User trust escrow event broadcast
- [ ] Payment status
  - [ ] Check if can NWC allows fetching invoice with description
  - [x] Combine rootstock status check and NWC status check into one PaymentStatus
  - [ ] Mock NWC should record "paid" invoices and respond to list invoice request appropriately
  - [ ] Mock lightning payments should 'resolve' accurate invoices and amounts
- [ ] NIP 05 verification
- [x] Language file
- [ ] Tests

P2

- [x] Payment flow in one "snackbar" instead of repeated popups
- [ ] Scan for NWC https://github.com/benthecarman/nips/blob/nostr-wallet-connect-connect/67.md

### Escrow

- [ ] Update escrow advertisement on launch
- [ ] Listen for cancelled events and arbitrate accordingly
- [ ] Must be able to read conversation once escrow is included
