User clicks login with Nostr Connect

E.g. nostr connect hyperlink `nostrconnect://<pubkey>?relay=${encodeURIComponent("wss://relay.hostr.io")}&metadata=${encodeURIComponent(JSON.stringify({"name": "Hostr"}))}`

```mermaid
flowchart TD
    A[User clicks login with Nostr Connect] --> B[Construct connect Url]
    B --> C[Click nostr connect hyperlink]
    C --> D[App signer sends NIP4 message kind 24133]
    D --> E[Once received, emit describe command to check if signer compatible with delegator]
    E --> F["Once received, emit delegate command [delegatee, { kind: number, since: number, until: number }]"]
    F --> G[Once received, store delegation signature along with generated pubkey, privkey in app storage]
    G --> H{Scan for listings of this rootkey}
    H --> I[If none, enter guest mode]
    H --> J[If some, enter host mode]
```