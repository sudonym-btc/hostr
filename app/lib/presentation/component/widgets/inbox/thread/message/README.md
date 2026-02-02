# Giftwrap Reservation Requests

This folder contains UI for rendering and interacting with reservation requests
inside a thread. The UI derives a **ReservationRequestStatus** and uses it to
decide which action (if any) to show.

## Inputs that determine status

- **Reservations for the listing** (filtered by the thread anchor)
- **Who sent the request** (host vs guest)
- **Payment status**
  - Zap receipts
  - Escrow contract deposits
- **Escrow capability**
  - If escrow is supported, the guest can pay immediately because funds are
    refundable. Otherwise, the host must acknowledge first.

## Derived status → UI behavior

| Status / Condition                            | UI Output                                        | Notes                                                          |
| --------------------------------------------- | ------------------------------------------------ | -------------------------------------------------------------- |
| Host not acknowledged and escrow unavailable  | Text: “Waiting for host to accept”               | Guest must wait for host acceptance.                           |
| Host acknowledged **or** escrow available     | Button: “Pay”                                    | Guest can proceed to payment.                                  |
| Payment sent but host reservation missing     | Text: “Unconfirmed”                              | Guest published reservation, host hasn’t yet.                  |
| Current user is host and has not acknowledged | Button: “Accept”                                 | Host confirms they will honor the request.                     |
| Cancelled                                     | Text(”Cancelled by host" / "Cancelled by guest") | Either party has cancelled.                                    |
| Refunded                                      | Text: “Refunded”                                 | Proof provided via zapreceipt or escrow that a refund was made |

## What this UI assumes

- The thread anchor is the single source of truth to link messages,
  reservations, and payment records.
- The reservation list is already scoped to the thread’s listing anchor.
- Payment checks are consistent across zap receipts and escrow deposits.

## Missing or to-do

- Explicit handling for **expired** or **cancelled** requests
- A clear **error** state for missing listing data or metadata
- UI for **payment in progress** (pending confirmation)
- Host-side **reject/decline** action
- Unit tests for each status transition
