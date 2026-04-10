# [<img src="./assets/images/logo/logo.svg" width="32">](https://hostr.network) Hostr

[![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)

Rental accommodation using purely peer‑to‑peer technologies such as [Nostr](https://nostr.com/).

<p align="start">

<img src="./screenshots/iphone_17_pro_max/dark/search.png" alt="Search page" width=200 style="max-width:300px;">&nbsp;
<img src="./screenshots/iphone_17_pro_max/dark/listing.png" alt="Listing page" width=200 style="max-width:300px;">&nbsp;
<img src="./screenshots/iphone_17_pro_max/dark/threads.png" alt="Threads page" width=200 style="max-width:300px;">&nbsp;
<img src="./screenshots/iphone_17_pro_max/dark/thread.png" alt="Thread page" width=200 style="max-width:300px;">&nbsp;
<img src="./screenshots/iphone_17_pro_max/dark/payment.png" alt="Payment page" width=200 style="max-width:300px;">&nbsp;

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
└── landing-page
```

- Client [README](./app/README.md)
- Infrastructure [README](./infrastructure/README.md)
- Escrow [README](./escrow/README.md)

## Nips utilized

- Accommodation [NIP](https://github.com/sudonym-btc/accommodation-nip)
- Escrow [NIP](https://github.com/sudonym-btc/escrow-nip)

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
  - [ ] Sync calendar optional
- [ ] Startup loading page
  - [x] Sync giftwraps
  - [x] Broadcast preferred user blossom servers if not found
  - [x] Broadcast preferred user relays if not found
  - [x] Broadcast preferred user escrows if not found
- [ ] Deeplinks
  - [ ] Allow opening of listings/reviews via deeplinks
- [ ] Payments
  - [x] Claim payment
  - [x] Refund payment
  - [ ] Swap in should broadcast claim as soon as lockup in mempool
  - [ ] Host autowithdraw should leave sats for claim/refund transactions
- [ ] Host views
  - [ ] List of upcoming reservations
- [ ] Blossom files
  - [ ] Caching of blossom servers between Image components
- [ ] Payment status
  - [ ] Check if can NWC allows fetching invoice with description
  - [x] Combine rootstock status check and NWC status check into one PaymentStatus
  - [ ] Mock NWC should record "paid" invoices and respond to list invoice request appropriately
  - [ ] Mock lightning payments should 'resolve' accurate invoices and amounts
- [x] NIP 05 verification
- [x] Language file
- [ ] Tests

### Escrow

- [ ] Update escrow advertisement on launch
- [ ] Listen for cancelled events and arbitrate accordingly
