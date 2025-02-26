
[![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)


# [<img src="app/assets/images/logo/logo.svg" width="32">](https://hostr.network) Hostr

Rental accomodation using purely peer-to-peer technologies such as [Nostr](https://nostr.com/).

<p align="start">

<img src=".doc/app/screenshots/home.jpeg" alt="Home page" width=200 style="max-width:300px;">
<img src=".doc/app/screenshots/listing.jpeg" alt="Listing page" width=200 style="max-width:300px;">

</p>

Read docs in full [here](https://sudonym-btc.github.io/hostr/)

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

## NIPs Utilized

- [**NIP-01**](https://github.com/nostr-protocol/nips/blob/master/01.md): Basic protocol for event creation and subscription.
- [**NIP-04**](https://github.com/nostr-protocol/nips/blob/master/04.md): Encrypted direct messages for secure communication between hosts and guests. (Deprecated)
- [**NIP-47**](https://github.com/nostr-protocol/nips/blob/master/17.md): Private Direct Messages
 
- [**NIP-05**](https://github.com/nostr-protocol/nips/blob/master/05.md): Mapping Nostr keys to DNS-based internet identifiers.
- [**NIP-09**](https://github.com/nostr-protocol/nips/blob/master/09.md): Event deletion for removing listings or messages.
- [**NIP-33**](https://github.com/nostr-protocol/nips/blob/master/33.md): Parameterized replaceable events for creating and updating listings and bookings.

## Getting started

```bash
git clone git@github.com:sudonym-btc/hostr.git
npm install -g semantic-release@18
```
