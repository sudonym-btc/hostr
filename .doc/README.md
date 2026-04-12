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
- [ ] Deeplinks
  - [ ] Allow opening of listings/reviews via deeplinks
- [ ] Blossom files
  - [ ] Caching of blossom servers between Image components
- [ ] Routing: unify tab-initial-route source of truth
  - [ ] `SearchRoute` is declared `initial: true` in the static route config but `buildAppNavigationDestinations` independently decides which tabs exist per mode — during mode transitions the router briefly shows the wrong initial tab (SearchRoute in host mode) before the dynamic destination list catches up. Remove `initial: true` from tab children and let `AutoTabsRouter` drive the initial index from `buildAppNavigationDestinations` so there is one mode-aware source of truth.

### Escrow

- [ ] Listen for cancelled events and arbitrate accordingly
