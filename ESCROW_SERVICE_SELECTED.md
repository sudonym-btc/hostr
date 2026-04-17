# Plan: Remove EscrowServiceSelected DM

## Problem

`EscrowServiceSelected` (kind 30302) is a DM published into the trade thread solely to shuttle the selected `EscrowService` + `EscrowMethod` to downstream listeners (`checkEscrowStatus`, `PaymentProofOrchestrator`). This is fragile — it depends on receiving the DM back through relay subscriptions, and couples swap funding to DM delivery.

## Goal

Keep the same data shape (`service: EscrowService`, `sellerMethods: EscrowMethod`), make it serializable on `SwapInData`, and use a global swap-completion listener to post the reservation — eliminating the DM entirely.

---

## Step 1 — Make `EscrowServiceSelectedContent` standalone & serializable

- Extract the content fields (`service`, `sellerMethods`) into a plain serializable class (e.g. `EscrowSelection`) with `toJson()`/`fromJson()`, decoupled from `JsonContentNostrEvent`.
- Keep the same shape: `EscrowService` event + `EscrowMethod` event, JSON-encoded.

## Step 2 — Add `escrowSelection` to `SwapInData`

- Add an optional `EscrowSelection? escrowSelection` field to `SwapInData`.
- Wire it through `toJson()` / `fromJson()` (nullable, same as `tokenAddress` pattern).
- This persists the selection alongside the swap in `OperationStateStore`.

## Step 3 — Have `EscrowFundPreparer` attach the selection

- In `EscrowFundPreparer.prepare()`, accept `EscrowSelection` as a parameter (or on `EscrowFundParams`).
- When building `SwapInParams`, pass the `escrowSelection` through so `SwapInData` stores it.
- Alternatively, set it on `SwapInData` right after `swapIn()` returns the operation, before `init()`.

## Step 4 — Remove the DM publish from `_onConfirm`

- In `escrow_fund.dart` `_onConfirm()`: delete the `_selectorCubit.select()` call.
- Remove `EscrowSelectorCubit` (or its `select()` / DM-publishing logic) entirely.

## Step 5 — Add global swap-completion listener → post reservation

- Create a listener (in SDK, e.g. on `PaymentProofOrchestrator` or a new class) that subscribes to **all tracked swaps** via `SwapInTracker`.
- On `SwapInCompleted` state:
  1. Read `swapData.escrowSelection` — if non-null, it's an escrow-funded swap.
  2. Build `EscrowProof(txHash: swapData.claimTxHash, hostsEscrowMethods: selection.sellerMethods, escrowService: selection.service)`.
  3. Build `PaymentProof` and call `reservations.createSelfSigned(...)`.
  4. On success, remove the swap from storage / mark as fully processed.
- This replaces the current reactive chain: `DM received → checkEscrowStatus → EscrowFundedEvent → PaymentProofOrchestrator`.

## Step 6 — Remove `checkEscrowStatus` from DM listener path

- In `UserSubscriptions`, remove `_maybeAddEscrowStream` (the DM-triggered escrow event listener).
- The on-chain escrow status stream (`checkEscrowStatus`) is still needed for UI (e.g. showing escrow state in the trade thread) — but it should be triggered from the swap tracker / trade view, not from receiving a DM.
- Refactor trade-thread UI to call `checkEscrowStatus` using the `escrowSelection` from the swap data instead.

## Step 7 — Delete `EscrowServiceSelected` event type

- Remove the `EscrowServiceSelected` Nostr event class, its parser registration (kind 30302), and all references.
- Keep `EscrowSelection` as the replacement data class.

## Step 8 — Clean up

- Remove `EscrowSelectorCubit` if no longer used.
- Remove kind 30302 from relay filters / subscription queries.
- Update any tests referencing `EscrowServiceSelected`.

---

## Migration / Backwards Compatibility

- **In-flight swaps** (already created without `escrowSelection`): these will have `escrowSelection: null`. The old `PaymentProofOrchestrator` path can be kept as a fallback for a release cycle, or those swaps can be manually completed.
- **Old DMs already on relays**: harmless — they'll just be ignored by the updated parser.

## Files to touch (estimated)

| File                              | Change                                                   |
| --------------------------------- | -------------------------------------------------------- |
| `EscrowServiceSelected` model     | Extract `EscrowSelection`, delete event class            |
| `SwapInData`                      | Add `escrowSelection` field + serialization              |
| `SwapInParams`                    | Add `escrowSelection` passthrough                        |
| `EscrowFundPreparer`              | Accept & attach `EscrowSelection`                        |
| `escrow_fund.dart` (`_onConfirm`) | Remove DM publish, pass selection to preparer            |
| `PaymentProofOrchestrator`        | Add swap-completion listener, build proof from swap data |
| `UserSubscriptions`               | Remove `_maybeAddEscrowStream`                           |
| `EscrowSelectorCubit`             | Delete or gut                                            |
| Parser registry                   | Remove kind 30302                                        |
| Trade thread UI                   | Source escrow status from swap data                      |
