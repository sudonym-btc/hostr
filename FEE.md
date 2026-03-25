# Fee Architecture — Redesign Plan

## Table of Contents

- [Current State](#current-state)
- [The Three Fee Sources](#the-three-fee-sources)
  - [1. Escrow Fee (service operator)](#1-escrow-fee-service-operator)
  - [2. Boltz Swap Fee (Lightning ↔ on-chain bridge)](#2-boltz-swap-fee-lightning--on-chain-bridge)
  - [3. Network Fee (EVM gas)](#3-network-fee-evm-gas)
- [What's Wrong Today](#whats-wrong-today)
- [Proposed Design](#proposed-design)
  - [Unified FeeBreakdown model](#unified-feebreakdown-model)
  - [Escrow fee denomination fix](#escrow-fee-denomination-fix)
  - [Gas estimation: real UserOp cost](#gas-estimation-real-userop-cost)
  - [Single FeeEstimator per operation](#single-feeestimator-per-operation)
  - [Nostr event changes](#nostr-event-changes)
  - [Smart contract changes](#smart-contract-changes)
- [Classes to Add, Remove, Refactor](#classes-to-add-remove-refactor)
- [UserOp Gas vs Raw Gas — Explainer](#userop-gas-vs-raw-gas--explainer)
- [Escrow fee denomination: which currency?](#escrow-fee-denomination-which-currency)
- [Migration Checklist](#migration-checklist)

---

## Current State

Fees are calculated in at least **six different classes** across three layers, with inconsistent denomination handling, redundant wrapping, and a gas estimate that always returns zero.

| Class              | File                             | Purpose                                                                  |
| ------------------ | -------------------------------- | ------------------------------------------------------------------------ |
| `GasEstimate`      | `supported_escrow_contract.dart` | Raw `eth_estimateGas` result (gasLimit × gasPrice)                       |
| `BoltzFeeEstimate` | `boltz_fee_estimate.dart`        | Boltz pair maths → totalFeeSat                                           |
| `SwapInFees`       | `swap_in_models.dart`            | Wraps gas + swap + relay as three `DenominatedAmount`s                   |
| `SwapOutFees`      | `swap_out_models.dart`           | Wraps gas + swap + balance + invoiceAmount                               |
| `OnchainFeeQuote`  | `onchain_operation.dart`         | Wraps `GasEstimate` + `SwapInFees` + `List<CallIntent>`                  |
| `EscrowFundFees`   | `escrow_fund_models.dart`        | Wraps `TokenAmount` gas + `SwapInFees` swap + `DenominatedAmount` escrow |
| `SwapOutQuote`     | `swap_out_quote_service.dart`    | Yet another wrapping: balance + invoice + gas + swap fees                |

That's **seven** types to represent what is fundamentally one concept: _"here are the fee line-items for an operation."_

---

## The Three Fee Sources

### 1. Escrow Fee (service operator)

**Where it's set:** Escrow operator publishes `feeBase` (int, sats) and `feePercent` (double, %) in the Nostr kind 30303 `EscrowServiceContent` JSON body.

**Where it's computed (client):** `EscrowServiceContent.escrowFee(int amountSats)` → `feeBase + floor(amountSats × feePercent / 100)`.

**Where it's enforced (contract):** `MultiEscrow.sol` stores `Trade.escrowFee` as a flat `uint256` in **token units**. The contract only validates `escrowFee ≤ amount`. On settlement, `escrowFee` is transferred to `trade.arbiter`.

**Problem:** The Nostr event defines fees in **sats**. The contract accepts fees in **token units** (which could be 6-decimal USDT, 18-decimal RBTC, or 8-decimal tBTC). The client bridges this gap with ad-hoc conversion logic in `_buildFundArgs()`:

- For native RBTC: compute in sats → scale to wei via `rbtcFromSatsInt()`
- For ERC-20: use raw BigInt math with `feePercent` re-scaled to token decimals

This dual path is a bug magnet. `feeBase` is ambiguous — is it 500 sats or 500 USDT micro-units?

### 2. Boltz Swap Fee (Lightning ↔ on-chain bridge)

**Where it comes from:** Boltz API `/getpairs` returns per-pair fee structures:

| Field                               | Meaning                         | Unit         |
| ----------------------------------- | ------------------------------- | ------------ |
| `SubmarinePair.fees.percentage`     | Proportional Boltz fee          | % of invoice |
| `SubmarinePair.fees.minerFees`      | Bitcoin miner fee for claim tx  | sats         |
| `ReversePair.fees.percentage`       | Proportional Boltz fee          | % of invoice |
| `ReversePair.fees.minerFees.lockup` | EVM gas for lockup (Boltz pays) | sats         |
| `ReversePair.fees.minerFees.claim`  | Bitcoin miner fee for claim tx  | sats         |

**Where it's computed:** `BoltzFeeEstimate` does the math correctly. For reverse (swap-in):

```
invoice = (onchain + lockupFee) / (1 − pct/100)
fee     = invoice − onchain
```

**All Boltz fees are denominated in sats.** This is clean — no ambiguity.

**Problem:** The result gets wrapped in `SwapInFees` which redundantly splits it into `estimatedGasFees` (always zero for swap-in!) + `estimatedSwapFees` + `estimatedRelayFees`, using three separate `DenominatedAmount` fields. Then `EscrowFundFees` wraps `SwapInFees` again, re-summing them in `networkFees`. Two layers of wrapping for one number.

### 3. Network Fee (EVM gas)

**Where it's estimated:** Two completely different paths exist:

| Path                                    | Used by                                     | What it does                                                  |
| --------------------------------------- | ------------------------------------------- | ------------------------------------------------------------- |
| `SupportedEscrowContract.estimateFee()` | `OnchainOperation.estimateCallIntentsFee()` | Raw `eth_estimateGas` → `gasLimit × gasPrice` → `GasEstimate` |
| `AACapability.estimateGasFee()`         | `SwapInOperation`, `SwapOutOperation`       | **Hardcoded `return BigInt.zero`**                            |

The raw gas estimate is used for on-chain operations (escrow fund), but the AA-aware estimate is always zero because the Pimlico paymaster currently sponsors everything.

**Problem:** `estimateGasFee()` returning `BigInt.zero` means:

1. The UI shows "0 sats in gas" — misleading if the paymaster stops sponsoring.
2. The `SwapInFees.estimatedGasFees` field is always zero, making the field pointless.
3. There is no infrastructure to show "this would cost X if not sponsored."
4. The raw `eth_estimateGas` path (in `GasEstimate`) doesn't account for UserOp overhead at all — it estimates as if the call were a direct EOA transaction, not an ERC-4337 UserOperation (see explainer below).

---

## What's Wrong Today

### 1. Seven fee types for one concept

`GasEstimate`, `BoltzFeeEstimate`, `SwapInFees`, `SwapOutFees`, `OnchainFeeQuote`, `EscrowFundFees`, `SwapOutQuote` — these form a Russian nesting doll. Each wraps the previous layer and adds one field. The result:

- Callers must dig through `.estimatedSwapFees.estimatedSwapFees` to reach the actual number.
- Summing across layers requires ad-hoc `.rescale(8)` calls sprinkled in getters.
- Every new operation needs yet another `XyzFees` class.

### 2. Escrow fee denomination is ambiguous

`EscrowServiceContent.feeBase` is documented as "sats" but the contract stores fees in **token units**. For RBTC (18 decimals) the client does `rbtcFromSatsInt()`, for ERC-20 it does its own BigInt scaling. If the escrow supports USDT (6 decimals), `feeBase: 500` means 500 sats to the Nostr event but 500 micro-USDT to the ERC-20 path — that's 0.0005 USDT vs 0.000005 BTC. The semantics diverge silently.

### 3. Gas estimation is fictional

`AACapability.estimateGasFee()` returns zero unconditionally. There is no way to show the real UserOp gas cost. The `GasEstimate` class used by `OnchainOperation` runs `eth_estimateGas`, which gives the **inner call's gas** — not the full UserOperation gas envelope (which includes validation, paymaster overhead, and bundler margins).

### 4. Redundant estimation round-trips

`EscrowFundOperation.estimateOperationFees()` creates a **throwaway `SwapInOperation`** just to call its `estimateFees()`, which itself creates throwaway Boltz clients and makes network calls. The same Boltz pair data could be fetched once and reused.

### 5. Mixed amount types

`EscrowFundFees` mixes `TokenAmount` (gas), `SwapInFees` (which contains `DenominatedAmount`s), and `DenominatedAmount` (escrow fee). The UI then has to normalize everything to a common denomination. This should be the model's job, not the UI's.

---

## Proposed Design

### Unified FeeBreakdown model

Replace all seven fee classes with one:

```
FeeBreakdown
  ├── escrowFee: TokenAmount     — escrow operator's cut (in trade token)
  ├── swapFee: TokenAmount       — Boltz swap overhead (in BTC/sats)
  ├── gasFee: TokenAmount        — EVM gas cost (in native token, e.g. RBTC)
  ├── gasSponsored: bool         — true if paymaster is covering gas
  └── total(denomination): DenominatedAmount  — sum in requested denomination
```

Every operation (`SwapIn`, `SwapOut`, `EscrowFund`, `EscrowRelease`, etc.) returns a `FeeBreakdown`. The caller never needs to know which wrapper they're in.

**For swap-out:** `escrowFee` is zero. `swapFee` comes from Boltz submarine pair. `gasFee` is the lock transaction gas.

**For swap-in:** `escrowFee` is zero. `swapFee` comes from Boltz reverse pair. `gasFee` is the claim transaction gas.

**For escrow fund:** All three are populated. `swapFee` and `gasFee` come from the nested swap-in's `FeeBreakdown`.

The key insight: `FeeBreakdown` is **compositional**. An escrow fund's breakdown can _include_ a nested swap's breakdown without needing a separate wrapping type.

### Escrow fee denomination fix

Today `feeBase` is "sats" in the Nostr event but "token units" in the contract. We should pick one and be consistent.

**Recommendation: denominate the escrow fee as a percentage + a base in the trade token's units.**

The Nostr event (kind 30303) already has `feePercent` as a percentage. Change `feeBase` from "sats" to mean **smallest units of the trade token** (or drop it entirely — see below). The `escrowFee()` helper then returns a value in the trade token's decimals, and no client-side re-scaling is needed.

Alternatively, keep `feePercent` as the only fee parameter and drop `feeBase`. A flat base fee denominated in one token doesn't translate well to tokens with different values (500 sats ≠ 500 USDT micro-units). A pure percentage scales naturally.

**Contract side:** No change needed. The contract already accepts `escrowFee` as a raw `uint256` in token units and only validates `escrowFee ≤ amount`.

**Nostr event change:**

```json
{
  "feePercent": 1.5
}
```

Drop `feeBase` entirely. If a base fee is truly needed, make it per-token in the `["token", ...]` tags (which PRICING.md already proposes).

### Gas estimation: real UserOp cost

Replace the `return BigInt.zero` stub in `AACapability.estimateGasFee()` with a real estimate, then flag it as sponsored.

The method should:

1. Build a dummy UserOperation from the signer.
2. Call Pimlico's `eth_estimateUserOperationGas` (already exposed via the bundler client).
3. Compute `(preVerificationGas + verificationGasLimit + callGasLimit) × maxFeePerGas`.
4. Return that as the `gasFee` in the `FeeBreakdown`.
5. Set `gasSponsored: true` so the UI knows the user isn't actually paying.

This lets the UI show: _"Gas: ~0.0001 RBTC (sponsored ✨)"_ — transparent about the real cost without scaring the user.

The raw `eth_estimateGas` in `SupportedEscrowContract.estimateFee()` should be kept as a **fallback** for non-AA chains, but for AA chains the UserOp estimation is the source of truth.

### Single FeeEstimator per operation

Instead of each operation class having its own `estimateFees()` method that duplicates Boltz pair fetching and gas estimation, extract a `FeeEstimator`:

```
FeeEstimator
  ├── estimateSwapIn(amount, tokenAddress?) → FeeBreakdown
  ├── estimateSwapOut(amount, tokenAddress?) → FeeBreakdown
  ├── estimateEscrowFund(amount, escrowService, tokenAddress?) → FeeBreakdown
  ├── estimateGas(callIntents, signer) → TokenAmount
  └── cached pair data (Boltz pairs, gas price — TTL ~30s)
```

Benefits:

- Boltz pair data fetched once, cached with a short TTL.
- Gas price fetched once per estimation batch.
- Each operation calls `feeEstimator.estimateX(...)` — one line, no throwaway objects.
- Easy to unit-test: inject a mock `FeeEstimator`.

### Nostr event changes

**EscrowService (kind 30303):**

| Field                 | Current                 | Proposed                      | Reason                                                                          |
| --------------------- | ----------------------- | ----------------------------- | ------------------------------------------------------------------------------- |
| `feeBase`             | int (sats)              | **Remove**                    | Ambiguous across tokens. Use per-token `feeBase` in `["token"]` tags if needed. |
| `feePercent`          | double (%)              | **Keep**                      | Token-agnostic percentage scales naturally.                                     |
| `["token", ...]` tags | `feeBase:500` per token | **Keep, rename to `baseFee`** | Explicit per-token base fee in that token's smallest unit.                      |

The client computes:

```
escrowFee = floor(amount × feePercent / 100) + perTokenBaseFee
```

Everything in the trade token's units. No sats-to-token conversion.

### Smart contract changes

**No functional changes needed.** The contract already stores `escrowFee` as a raw `uint256` in token units. The caller (client) is responsible for computing the correct value. The only check is `escrowFee ≤ amount`.

**Optional improvement:** Add an on-chain `feePercent` and `feeBase` to the contract so the contract can **verify** the fee matches the operator's published schedule, rather than trusting the caller. This would be a view function or modifier:

```solidity
function _validateEscrowFee(uint256 amount, uint256 escrowFee) internal view {
    uint256 expected = (amount * feePercent) / FEE_SCALE + feeBase;
    require(escrowFee >= expected, "Fee too low");
}
```

This is not strictly necessary if you trust the client, but it prevents a malicious client from setting `escrowFee: 0` to avoid paying the operator.

**DEX conversion to TBTC:** Not recommended. Adding a DEX call inside the settlement flow introduces:

- Slippage risk (especially for small amounts).
- An external dependency that can revert, bricking settlements.
- Complexity in fee accounting (the DEX itself charges a fee).

If the escrow operator wants fees in TBTC, they should simply support TBTC as a trade token. The escrow fee is then naturally in TBTC. Cross-token conversion belongs in a separate sweep/treasury step, not in the settlement path.

---

## Classes to Add, Remove, Refactor

### Remove

| Class                                           | File                          | Why                                                                                |
| ----------------------------------------------- | ----------------------------- | ---------------------------------------------------------------------------------- |
| `SwapInFees`                                    | `swap_in_models.dart`         | Replaced by `FeeBreakdown`                                                         |
| `SwapOutFees`                                   | `swap_out_models.dart`        | Replaced by `FeeBreakdown`                                                         |
| `EscrowFundFees`                                | `escrow_fund_models.dart`     | Replaced by `FeeBreakdown`                                                         |
| `OnchainFeeQuote`                               | `onchain_operation.dart`      | Split: fees → `FeeBreakdown`, intents stay as return value of `buildCallIntents()` |
| `SwapOutQuote.estimatedGasFee/estimatedSwapFee` | `swap_out_quote_service.dart` | The quote keeps `balance`/`invoiceAmount`, but fee fields move to `FeeBreakdown`   |

### Add

| Class          | Purpose                                                               |
| -------------- | --------------------------------------------------------------------- |
| `FeeBreakdown` | Single fee model: `escrowFee`, `swapFee`, `gasFee`, `gasSponsored`    |
| `FeeEstimator` | Stateless service: estimates fees for any operation, caches pair data |

### Refactor

| Class                           | Change                                                                                                                              |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `GasEstimate`                   | Keep, but only used internally by `FeeEstimator`. Not exposed to operations/UI.                                                     |
| `BoltzFeeEstimate`              | Keep as-is (it's clean). Used internally by `FeeEstimator`.                                                                         |
| `AACapability.estimateGasFee()` | Real UserOp gas estimation instead of `return BigInt.zero`                                                                          |
| `EscrowServiceContent`          | Remove `feeBase`. Keep `feePercent`. Fee calculation moves to `FeeEstimator` which reads per-token base fees from `["token"]` tags. |
| `SwapOutQuoteService`           | Inject `FeeEstimator`; remove fee fields from `SwapOutQuote`.                                                                       |

**Net change:** 5 classes removed, 2 classes added = **−3 classes.** More importantly, every caller uses one type (`FeeBreakdown`) instead of learning five.

---

## UserOp Gas vs Raw Gas — Explainer

### Raw gas (`eth_estimateGas`)

A standard Ethereum gas estimation simulates the transaction as if an EOA (externally-owned account) called the target contract directly:

```
gas = execution gas of the inner call (e.g. MultiEscrow.createTrade)
cost = gas × gasPrice
```

This is what `SupportedEscrowContract.estimateFee()` computes today.

### UserOp gas (`eth_estimateUserOperationGas`)

An ERC-4337 UserOperation wraps the inner call in an envelope processed by the EntryPoint contract. The gas budget has **three components**:

| Component              | What it covers                                                                                                                                                          |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `preVerificationGas`   | Calldata cost to submit the UserOp to the EntryPoint. Includes bundler overhead. On L2s this also covers L1 data-availability costs (significant on Arbitrum/Optimism). |
| `verificationGasLimit` | Running `validateUserOp` on the smart account + `validatePaymasterUserOp` on the paymaster. Includes signature verification and factory deployment (first tx only).     |
| `callGasLimit`         | The actual inner call execution — equivalent to raw `eth_estimateGas`.                                                                                                  |

The total gas for a UserOp is:

$$
\text{totalGas} = \text{preVerificationGas} + \text{verificationGasLimit} + \text{callGasLimit}
$$

And the cost is:

$$
\text{cost} = \text{totalGas} \times \text{maxFeePerGas}
$$

In practice, **UserOp gas is 1.5×–3× raw gas** because:

- `preVerificationGas` adds ~42,000+ gas for calldata encoding.
- `verificationGasLimit` adds ~100,000–400,000 gas (especially on first deployment of the smart account via factory).
- The bundler and paymaster add validation overhead.
- On L2 rollups, `preVerificationGas` includes L1 data posting costs, which can dominate.

### Why `estimateGasFee() → BigInt.zero` is wrong

Even though the paymaster sponsors the gas, the **real cost exists** — it's just paid by someone else (Pimlico, in this case). Returning zero means:

1. The UI can't show "what this would cost without sponsorship."
2. If the paymaster goes away, every fee display is wrong.
3. Swap amount calculations that include gas budget (`_computeRequiredSwapAmount`) treat gas as free, which is accidentally correct today but will break the moment sponsorship ends.

### What to do

`AACapability.estimateGasFee()` should call the bundler's `eth_estimateUserOperationGas` with a representative UserOp and return the real cost. Then attach `gasSponsored: true` so the UI and business logic know the user isn't paying.

For the `GasEstimate` path used in `OnchainOperation.estimateCallIntentsFee()`: if the chain has AA enabled, delegate to `AACapability` instead of calling `eth_estimateGas` directly. The raw gas path should only be used on non-AA chains.

---

## Escrow fee denomination: which currency?

There are three options. Here's why a pure percentage is the simplest:

### Option A: Everything in sats (current, broken for ERC-20)

`feeBase: 500` means 500 sats. Works for BTC. For USDT, the client must convert 500 sats → USDT at the current exchange rate. This requires a price oracle, adds complexity, and introduces slippage.

**Verdict:** Don't do this.

### Option B: Everything in trade token units (requires per-token config)

`feeBase` means "500 units of whatever token this trade uses." For BTC that's 500 sats. For USDT (6 decimals) that's 0.0005 USDT. This is what the contract actually stores.

This works but requires the escrow operator to set a base fee per token. The `["token", "USDT", "baseFee:50000"]` tag approach from PRICING.md handles this.

**Verdict:** Viable, but adds operator UX burden.

### Option C: Percentage only, drop feeBase (recommended)

`feePercent: 1.5` means 1.5% of the trade amount, regardless of token. No conversion, no per-token config, no ambiguity.

The operator wants to earn a percentage of each trade. A flat base fee in sats is an artifact of a BTC-only world. For a 0.001 BTC trade, 500 sats is a meaningful minimum. For a $75 USDT trade, 500 sats is economically meaningless. The percentage handles both naturally.

If a minimum fee floor is needed, express it as `minFee: 0.50` (in the listing's price denomination, e.g. USD) on the Nostr event. This is more intuitive for operators than per-token smallest-unit base fees.

**Verdict:** Simplest, cleanest. Drop `feeBase`, keep `feePercent`.

---

## Migration Checklist

### Phase 1: Models & estimation

- [ ] Create `FeeBreakdown` class in `hostr_sdk/lib/usecase/evm/models/`.
- [ ] Create `FeeEstimator` service in `hostr_sdk/lib/usecase/evm/services/`.
- [ ] Implement real UserOp gas estimation in `AACapability.estimateGasFee()`.
- [ ] Add `gasSponsored` flag to `FeeBreakdown`.
- [ ] Wire `BoltzFeeEstimate` into `FeeEstimator` with caching.

### Phase 2: Operation refactoring

- [ ] Refactor `SwapInOperation.estimateFees()` → return `FeeBreakdown`.
- [ ] Refactor `SwapOutOperation.estimateFees()` → return `FeeBreakdown`.
- [ ] Refactor `EscrowFundOperation.estimateFees()` → return `FeeBreakdown`.
- [ ] Remove `SwapInFees`, `SwapOutFees`, `EscrowFundFees`.
- [ ] Collapse `OnchainFeeQuote` — return `(FeeBreakdown, List<CallIntent>)` instead.
- [ ] Update `SwapOutQuoteService` to use `FeeEstimator`.

### Phase 3: Escrow fee denomination

- [ ] Update `EscrowServiceContent` — remove `feeBase`, keep `feePercent`.
- [ ] Update escrow daemon's CLI and RPC to remove `feeBase` editing.
- [ ] Update escrow daemon's Nostr event publisher.
- [ ] Update client-side `_buildFundArgs()` to compute fee purely from `feePercent` in token units.
- [ ] Re-publish all escrow service events (kind 30303) without `feeBase`.

### Phase 4: UI

- [ ] Update `escrow_fund.dart` widget to use `FeeBreakdown`.
- [ ] Update `swap_in.dart` widget to use `FeeBreakdown`.
- [ ] Update `swap_out.dart` widget to use `FeeBreakdown`.
- [ ] Show `gasSponsored` badge when gas is zero but `gasFee > 0`.
- [ ] Format each fee line-item in its native denomination (no manual rescaling in UI).

### Phase 5: Cleanup

- [ ] Delete dead classes (`SwapInFees`, `SwapOutFees`, `EscrowFundFees`, `OnchainFeeQuote`).
- [ ] Remove `feeBase` from `EscrowServiceContent.fromJson()` / `toJson()`.
- [ ] Audit all `.rescale(8)` calls — most should be unnecessary after `FeeBreakdown`.
- [ ] Update `PRICING.md` and `ERC20.md` to reference new fee architecture.
