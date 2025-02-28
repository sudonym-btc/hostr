# Conversation Page

Conversations consist of wrapped messages between a seller and hoster, and contain direct messages and reservation requests.

A thread must reference a particular unique ID, primarily set by an initial `ReservationRequest` sent either by the host to the guest, or guest to the host.

```mermaid
flowchart TD
    Input[Payment Request to, amount?, needReceipt=true]

    subgraph Resolve Info
        A{Must resolve?}
        B[LNURL, Lightning Address, Bolt12, Zap, npub]
        C[Bolt11]
        A ---|Yes| B
        A ---|No| C
        E[fetch]
        D[commentMax, commentMin, minAmount, maxAmount, callbackUrl]
        B --> E
        E --> D
        C --> D
    end

    Input --> A

    D --> FetchFinal[Fetch bolt11 and verify hash/amount]
    FetchFinal --> PayMethod{NWC enabled?}
    PayMethod ---|No| PayBolt11WithDeeplinkQR
    PayBolt11WithDeeplinkQR --> ManuallyCloseAwaitZapEscrowEvent
    PayMethod ---|Yes| NWCPayInvoice
    NWCPayInvoice --> NWCResponse{notification received?}
    NWCResponse --> CloseUI
```
