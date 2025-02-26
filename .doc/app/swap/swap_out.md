
# Swap out (Submarine Swap)

A swap-out occurs after an escrow has paid the seller out on the EVM chain.
The funds now need to be swept back to lightning.

```diff
How can we get cought out?

- We lock our funds in the lock TXN and never refund ourselves

- We overpay fees
```

```mermaid
flowchart TD
  SwapOut[Swap Out]
  --> GetTotalBalance
  --> SubtractFees
  --> GenerateInvoice
  --> ContactBoltz[Contact Boltz for submarine Swap. Params: invoice]
  --> SwapCreated[Returns:
  boltzClaimAddr, timeoutBlockHeight, expectedAmount]
  --> LockEVMFunds
  --> A{Did they unlock with preimage}
  ---|No| RefundAfterTimelock
  A---|Yes| WeMustHaveBeenPaidOut
```
