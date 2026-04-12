# ERC20 Token Support — Swap-In & Swap-Out Plan

## Status Quo

| Layer                 | ERC20 ready?      | Notes                                                                                                                                                                                                  |
| --------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **MultiEscrow.sol**   | ✅ Yes            | `token` field per trade; `_safeTransferFrom` / `_transfer` handle non-standard tokens like USDT. `createTrade` pulls via `transferFrom`, `withdraw` pushes to destination.                             |
| **hostr_sdk** (Boltz) | ✅ Yes            | `BoltzCallBuilder.erc20Lock()` builds `approve` + `ERC20Swap.lock()`. `BoltzClaimSigner` handles ERC-20 claims. `BoltzSwapProvider.currencyForTokenAddress()` resolves ERC-20 → Boltz currency string. |
| **Escrow daemon**     | ✅ Token-agnostic | Doesn't care about token type; reads `trade.token` from contract.                                                                                                                                      |
| **App (Flutter)**     | ⚠️ Partial        | Fund/withdraw operations call `resolveBoltzFundingToken()` which already prefers ERC-20 when available, but UI has no token selector and no stablecoin flows.                                          |

**Bottom line:** The contract and SDK plumbing for ERC20 is already in place. What we need is the _routing strategy_ — how to get Lightning sats in/out of arbitrary ERC20 tokens like USDT.

---

## The Boltz Router Contract

### What it is

Boltz deployed a [`Router`](https://github.com/BoltzExchange/boltz-core/blob/master/contracts/Router.sol) contract on Arbitrum ([`0xaB6B467FC443Ca37a8E5aA11B04ea29434688d61`](https://arbiscan.io/address/0xaB6B467FC443Ca37a8E5aA11B04ea29434688d61)) that atomically chains a Boltz HTLC swap claim with arbitrary on-chain calls (typically a DEX trade) and a final sweep to the user.

### Key functions

```
claimExecute(claim, calls[], token, minAmountOut)
claimERC20Execute(claim, calls[], token, minAmountOut)
claimERC20ExecuteOft(claim, calls[], token, oft, sendData, auth)   // + cross-chain OFT bridge
executeAndLock(preimageHash, claimAddress, refundAddress, timelock, calls[])
executeAndLockERC20(preimageHash, token, claimAddress, refundAddress, timelock, calls[])
```

### How Boltz uses it for Lightning ↔ USDT

```
Lightning ──► Boltz (Reverse Sub) ──► tBTC locked in ERC20Swap on Arbitrum
                                          │
                                          ▼
                               Router.claimERC20Execute()
                                 1. Claim tBTC from ERC20Swap (preimage + EIP-712 sig)
                                 2. executeCalls: DEX swap tBTC → USDT0 (via Uniswap)
                                 3. sweep: send USDT0 to user wallet
                                          │
                                          ▼  (optional)
                               OFT bridge USDT0 → target chain (Ethereum, Rootstock, etc.)
```

The reverse direction (USDT → Lightning) uses:

```
USDT0 ──► DEX: USDT0 → tBTC ──► Router.executeAndLockERC20()
                                   1. executeCalls: DEX swap
                                   2. Lock tBTC into ERC20Swap
                                          │
                                          ▼
                               Boltz Submarine: pays Lightning invoice
```

---

## Can we use the Boltz Router for arbitrary ERC20 tokens?

### Short answer: YES — for any token with a DEX pair against tBTC (or RBTC)

The Router's `executeCalls` is completely generic — it takes an array of `Call{target, value, callData}` structs. Boltz constructs the calldata server-side using their quote API. The Router doesn't know or care what tokens are being swapped; it just:

1. Claims the intermediate asset (tBTC/RBTC) from the HTLC
2. Executes whatever calls you give it (approve → DEX swap → …)
3. Sweeps the output token to the user

**So to support USDC, DAI, or any ERC20:** you just need a different DEX route in the `calls[]` array. No contract changes.

### What the Boltz Router gives us

| ✅ Benefit              | Detail                                                             |
| ----------------------- | ------------------------------------------------------------------ |
| **Atomicity**           | Claim + DEX trade + sweep are all-or-nothing in one tx             |
| **Slippage protection** | `minAmountOut` reverts the whole thing if DEX price moves          |
| **Gas abstraction**     | EIP-712 signatures let a relayer broadcast on behalf of the user   |
| **OFT bridging**        | `claimERC20ExecuteOft` variant sends to other chains via LayerZero |
| **Battle-tested**       | Already live on Arbitrum, adopted by others (Lendasat)             |

### What it does NOT give us

| ❌ Limitation                        | Detail                                                                                                                                                      |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Only works on Arbitrum**           | The Router is deployed on Arbitrum. We're on Rootstock (chain 30). Boltz USDT swaps funnel through Arbitrum, not Rootstock.                                 |
| **Boltz must support the pair**      | Boltz's quote API currently only quotes tBTC ↔ USDT0. Arbitrary tokens (USDC, DOC, etc.) aren't in their pair list yet (USDC via CCTP is on their roadmap). |
| **We'd be routing through Arbitrum** | Our escrow is on Rootstock. Using Boltz's Arbitrum Router would mean a cross-chain hop.                                                                     |
| **Boltz controls the calldata**      | In their routed swap architecture, the server constructs the DEX swap calldata. We'd need to either trust that or build our own.                            |

---

## Three Options for Hostr

### Option A: Use Boltz Router on Arbitrum (simplest, cross-chain)

**Approach:** Deploy the Hostr escrow on Arbitrum alongside Boltz's Router. Use their Router + quote API for the Lightning ↔ USDT leg, then fund our `MultiEscrow` directly with USDT on Arbitrum.

```
Guest pays Lightning invoice
    │
    ▼  Boltz Reverse Submarine
tBTC locked in ERC20Swap (Arbitrum)
    │
    ▼  Router.claimERC20Execute()
    │    1. Claim tBTC
    │    2. DEX: tBTC → USDT
    │    3. Sweep USDT to guest's smart wallet
    │
    ▼  Guest's smart wallet
USDT.approve(MultiEscrow) + MultiEscrow.createTrade(token=USDT, ...)
    │
    ▼  Trade lifecycle (release/arbitrate/claim)
    │
    ▼  Host withdraws USDT balance from MultiEscrow
    │
    ▼  Swap out: USDT → tBTC → Lightning
         Router.executeAndLockERC20() → Boltz Submarine → Lightning
```

| Pros                                               | Cons                                            |
| -------------------------------------------------- | ----------------------------------------------- |
| Zero contract work — Boltz Router already deployed | Must deploy MultiEscrow on Arbitrum (new chain) |
| Boltz handles DEX quotes, gas abstraction          | Leaves Rootstock behind (or maintain both)      |
| Any token Boltz supports (USDT now, USDC soon)     | Dependency on Boltz quote API for DEX routing   |
| Low gas on Arbitrum L2                             |                                                 |

**Effort: Medium** — new chain deployment, SDK chain config, UI token selector.

---

### Option B: Build our own Router on Rootstock (most control)

**Approach:** Fork/adapt the Boltz Router contract for Rootstock. Wire it to Rootstock's Boltz `EtherSwap`/`ERC20Swap` contracts. Use a Rootstock DEX (SushiSwap, Sovryn) for the token swap leg.

```
Guest pays Lightning invoice
    │
    ▼  Boltz Reverse Submarine (Rootstock)
RBTC locked in EtherSwap (Rootstock)
    │
    ▼  HostrRouter.claimExecute()
    │    1. Claim RBTC from EtherSwap
    │    2. DEX: RBTC → USDT (via SushiSwap on Rootstock)
    │       or RBTC → DOC (via MoneyOnChain)
    │    3. Sweep USDT/DOC to guest's smart wallet
    │
    ▼  MultiEscrow.createTrade(token=USDT, ...)
    │   ... trade lifecycle ...
    ▼  Host withdraws
    │
    ▼  Swap out: USDT → RBTC → Lightning
         HostrRouter.executeAndLock() with DEX calls → Boltz Submarine
```

| Pros                                   | Cons                                         |
| -------------------------------------- | -------------------------------------------- |
| Stay on Rootstock — no new chain       | Must deploy + audit our own Router           |
| Full control over DEX routing          | Rootstock DEX liquidity may be thin for USDT |
| Can route to ANY token with a DEX pair | Need to build our own quote engine           |
| No dependency on Boltz's pair support  | More moving parts                            |

**Effort: High** — new contract, DEX integration, quote engine, testing.

---

### Option C: Smart Wallet batched calls — no Router contract needed (pragmatic)

**Approach:** Use the user's smart wallet (ERC-4337 account abstraction) to batch the claim + DEX swap + escrow deposit into a single `UserOperation`. The smart wallet IS the router.

```
Guest pays Lightning invoice
    │
    ▼  Boltz Reverse Submarine (Rootstock)
RBTC locked in EtherSwap (Rootstock)
    │
    ▼  Smart Wallet UserOp (batched):
    │    1. EtherSwap.claim(preimage, ...) → RBTC to wallet
    │    2. SushiSwap.swap(RBTC → USDT)
    │    3. USDT.approve(MultiEscrow, amount)
    │    4. MultiEscrow.createTrade(token=USDT, ...)
    │
    ▼  Trade lifecycle ...
    │
    ▼  Host withdraws (also via smart wallet UserOp):
    │    1. MultiEscrow.withdraw(USDT, ...)
    │    2. SushiSwap.swap(USDT → RBTC)
    │    3. EtherSwap.lock(preimageHash, ...) → Boltz Submarine
```

| Pros                                  | Cons                                                             |
| ------------------------------------- | ---------------------------------------------------------------- |
| NO new contracts at all               | Claim is not atomic with DEX (separate tx from Boltz HTLC claim) |
| Full flexibility — any token, any DEX | User pays gas for the batch                                      |
| Already have smart wallet infra       | Can't use Boltz's cooperative claim (EIP-712 sig targets Router) |
| Works on any chain we're on           | Must handle the Boltz claim preimage reveal carefully            |

**⚠️ Critical issue:** Boltz's cooperative claim mechanism (`claim(preimage, ..., v, r, s)`) is designed so the claim address is `msg.sender`. With a smart wallet, the wallet IS the claim address, so this works. But the DEX swap is NOT atomic with the HTLC claim unless we use a Router-style contract.

**Workaround:** Two-step approach:

1. Smart wallet claims RBTC/tBTC from Boltz (standard claim, wallet is claimAddress)
2. Second UserOp: DEX swap + escrow deposit

The preimage reveal in step 1 is safe because once claimed, the RBTC is in the wallet. The DEX swap is a separate risk (slippage) but not an atomicity problem.

**Effort: Low-Medium** — mostly SDK/app work, no new contracts.

---

## Recommendation

### Phase 1: Arbitrum + Smart Wallet + Boltz Quote API — ship fast 🚀

Combines Option A and Option C. Use the smart wallet on Arbitrum with Boltz's Quote API providing the DEX calldata. This avoids building a DEX aggregator and ensures amounts match Boltz quotes exactly.

1. **Deploy/verify MultiEscrow on Arbitrum** — already have `mainnet.42161` config in contract-addresses.json
2. **Token selector in the app** — let users choose BTC (native), USDT, or USDC as the escrow denomination
3. **Boltz Quote API integration** — `BoltzQuoteClient` wraps the `/quote/{currency}/in`, `/out`, `/encode` endpoints
4. **Batched UserOps** — smart wallet: `claim tBTC → [Boltz DEX calls] → approve → escrow deposit`
5. **Reverse for withdrawal** — smart wallet: `escrow withdraw → [Boltz DEX calls] → ERC20Swap.lock`

This requires:

- [ ] `BoltzQuoteClient` — wraps `/quote/{currency}/in`, `/out`, `/encode`
- [ ] `SwapAndDepositBuilder` — composes UserOp: claim → Boltz DEX calls → approve → createTrade
- [ ] `WithdrawAndSwapBuilder` — composes UserOp: withdraw → Boltz DEX calls → ERC20Swap.lock
- [ ] App UI: token selector, Boltz quote display, slippage settings
- [ ] Verify MultiEscrow deployment on Arbitrum mainnet

### Phase 2: Rootstock ERC20 support — if/when Boltz adds Rootstock tokens

If Boltz adds tBTC or USDT to their Rootstock pair list, or if we build our own DEX integration:

1. Add `DexSwapProvider` for SushiSwap/Sovryn on Rootstock
2. Same smart wallet batch pattern, but with local DEX calldata instead of Boltz Quote API
3. Verify USDT/DOC liquidity depth on Rootstock DEXes

### Phase 3: Custom Router — if we need atomicity guarantees

Only build our own Router if:

- Smart wallet approach has UX/reliability issues
- We need the atomicity guarantee of claim + DEX + deposit in one tx
- We want to offer the Router to other builders (like Boltz does)

---

## Key Technical Details

### DEX Integration (Rootstock)

| DEX       | Router address      | Pairs               | Notes            |
| --------- | ------------------- | ------------------- | ---------------- |
| SushiSwap | `0x...` (Rootstock) | RBTC/USDT, RBTC/DOC | V2-style AMM     |
| Sovryn    | `0x...` (Rootstock) | RBTC/USDT, RBTC/SOV | Order book + AMM |

Query SushiSwap quote:

```
GET https://api.sushi.com/swap/v5/30?tokenIn=RBTC&tokenOut=USDT&amount=...
```

### Boltz Pair Discovery

```
GET https://api.boltz.exchange/v2/chain/contracts
→ { "rsk": { "network": { "chainId": 30 }, "swapContracts": { "EtherSwap": "0x...", "ERC20Swap": "0x..." }, "tokens": { "TBTC": "0x..." } } }
```

Currently Boltz supports these ERC20 tokens per chain:

- **Rootstock:** native RBTC only (no ERC20 tokens listed)
- **Arbitrum:** tBTC (used as intermediate for USDT routing)

### Smart Wallet Batch — Using Boltz Quote API (Pseudocode)

```dart
// === SWAP-IN: Guest pays Lightning → USDT in escrow ===

// 1. Boltz Reverse Submarine: Lightning → tBTC locked in ERC20Swap (Arbitrum)
final reverseSwap = await boltzClient.createReverseSwap(
  from: 'BTC', to: 'ARB',
  invoiceAmount: lightningAmountSats,
  claimAddress: smartWalletAddress,
);

// 2. After Boltz locks tBTC, get claim details
final claimCalldata = boltzClaimSigner.buildErc20Claim(reverseSwap);

// 3. Get DEX quote from Boltz Quote API
final dexQuotes = await boltzClient.getQuoteIn(
  currency: 'ARB',
  tokenIn: tbtcAddress,      // 0x6c84...
  tokenOut: usdtAddress,     // 0xFd086...
  amountIn: reverseSwap.onchainAmount.toString(),
);
final bestQuote = dexQuotes.first; // sorted by highest output

// 4. Encode DEX calldata via Boltz
final encoded = await boltzClient.encodeQuote(
  currency: 'ARB',
  data: bestQuote.data,
  recipient: smartWalletAddress,
  amountIn: reverseSwap.onchainAmount.toString(),
  amountOutMin: (BigInt.parse(bestQuote.quote) * BigInt.from(99) ~/ BigInt.from(100)).toString(), // 1% slippage
);

// 5. Build smart wallet batch UserOp
final userOp = smartWallet.buildBatch([
  // a) Claim tBTC from Boltz ERC20Swap HTLC
  Call(target: erc20Swap, data: claimCalldata),
  // b) DEX swap calls (from Boltz encode endpoint — approve + Uniswap swap)
  ...encoded.calls.map((c) => Call(target: c.to, value: c.value, data: c.data)),
  // c) Approve escrow to spend USDT
  Call(target: usdt, data: usdt.encode('approve', [multiEscrow, usdtAmount])),
  // d) Fund escrow trade
  Call(target: multiEscrow, data: multiEscrow.encode('createTrade', [
    tradeId, buyer, seller, arbiter, usdt, paymentAmount, bondAmount, unlockAt, escrowFee
  ])),
]);

await smartWallet.send(userOp);
```

### Gas Estimation

On Rootstock (30s blocks, ~0.06 gwei gas price):
| Operation | Est. gas | Est. cost |
|---|---|---|
| Boltz EtherSwap.claim | ~60k | ~0.000004 RBTC |
| DEX swap (SushiSwap) | ~150k | ~0.000009 RBTC |
| ERC20 approve | ~46k | ~0.000003 RBTC |
| MultiEscrow.createTrade (ERC20) | ~120k | ~0.000007 RBTC |
| **Total batched UserOp** | **~376k** | **~0.000023 RBTC (~$2.30)** |

On Arbitrum (if we go that route):
| Operation | Est. cost |
|---|---|
| Full Boltz Router claim+DEX+sweep | ~$0.10-0.30 |
| MultiEscrow.createTrade | ~$0.05-0.15 |

---

## Boltz Quote API — DEX Calldata Provision

### Discovery

Boltz exposes a **Quote API** (under the `Quotes` tag) that provides both the DEX route details AND pre-encoded calldata for token swaps. This is the key to making the smart wallet approach work seamlessly with Boltz's pricing.

### Endpoints

| Endpoint                   | Method | Purpose                                                               |
| -------------------------- | ------ | --------------------------------------------------------------------- |
| `/quote/{currency}/in`     | GET    | Get quotes for a token swap with specified **input** amount           |
| `/quote/{currency}/out`    | GET    | Get quotes for a token swap with specified **output** amount          |
| `/quote/{currency}/encode` | POST   | **Encode calldata** for a token swap — returns ready-to-use `calls[]` |

### Flow: Quote → Encode → Execute

**Step 1: Get a quote**

```
GET /quote/ARB/in?tokenIn=0x6c84...&tokenOut=0xFd086...&amountIn=10000000000000000
```

Response (live example — 0.01 tBTC → USDT on Arbitrum):

```json
[
  {
    "quote": "713234802",
    "data": {
      "type": "uniswapV3",
      "tokenIn": "0x6c84a8f1c29108f47a79964b5fe888d4f4d0de40",
      "hops": [
        { "fee": 100, "token": "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f" },
        { "fee": 500, "token": "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9" }
      ]
    }
  }
]
```

This tells us: tBTC → WBTC (0.01% fee) → USDT (0.05% fee) via Uniswap V3 on Arbitrum.
The `quote` field is the expected output: 713,234,802 = **~713.23 USDT** (6 decimals).

**Step 2: Encode the calldata**

```
POST /quote/ARB/encode
{
  "data": { <the data object from step 1> },
  "recipient": "0x<smart_wallet_address>",
  "amountIn": "10000000000000000",
  "amountOutMin": "706000000"        // quote minus slippage (e.g., 1%)
}
```

Response:

```json
{
  "calls": [
    { "to": "0x<token>", "value": "0", "data": "0x<approve_calldata>" },
    { "to": "0x<uniswap>", "value": "0", "data": "0x<swap_calldata>" }
  ]
}
```

Each `Call` has `{ to, value, data }` — identical to what smart wallet `executeBatch` expects.

**Step 3: Insert into smart wallet UserOp**

```dart
// 1. Get Boltz claim details (preimage, etc.)
// 2. Get DEX quote from Boltz
final dexQuote = await boltzClient.getQuoteIn(
  currency: 'ARB',
  tokenIn: tbtcAddress,
  tokenOut: usdtAddress,
  amountIn: claimedAmount,
);

// 3. Encode DEX calldata via Boltz
final encodedCalls = await boltzClient.encodeQuote(
  currency: 'ARB',
  data: dexQuote.data,
  recipient: smartWalletAddress,
  amountIn: claimedAmount,
  amountOutMin: dexQuote.quote * (1 - slippage),
);

// 4. Build smart wallet batch
final userOp = smartWallet.buildBatch([
  // a) Claim tBTC from Boltz ERC20Swap HTLC
  Call(target: erc20Swap, data: claimCalldata),
  // b) DEX swap calls (from Boltz encode endpoint)
  ...encodedCalls.calls,
  // c) Approve escrow
  Call(target: usdt, data: approveCalldata),
  // d) Fund escrow
  Call(target: multiEscrow, data: createTradeCalldata),
]);
```

### Why this matters

**The amounts match because we use the same DEX route Boltz quotes.**

If we were to use a different DEX (e.g., our own SushiSwap integration) while Boltz quoted via Uniswap V3, the output amounts would diverge. By using Boltz's `/quote/encode` endpoint:

- The DEX route is identical to what Boltz quotes
- The slippage protection (`amountOutMin`) is based on a real, fresh quote
- We don't need to build our own DEX aggregator integration
- We get Boltz's best-route selection across multiple DEX protocols for free

### Limitation: Arbitrum only (for now)

The Quote API currently works with `ARB` (Arbitrum). Rootstock is not listed as a supported network for token swaps. This means:

- **On Arbitrum:** Full Boltz Quote API support — tBTC ↔ USDT, tBTC ↔ USDC (when added)
- **On Rootstock:** Must use our own DEX integration (SushiSwap/Sovryn) for the swap step

This reinforces the recommendation: **start with Arbitrum for USDT support** and use Boltz's Quote API end-to-end.

---

## Revised Recommendation

### Phase 1: Arbitrum + Smart Wallet + Boltz Quote API 🚀

The cleanest path combines Option A and Option C:

1. **Deploy MultiEscrow on Arbitrum** (already have `mainnet.42161` config)
2. **Use Boltz Reverse Submarine** to get tBTC locked on Arbitrum
3. **Smart wallet claims tBTC** from ERC20Swap (standard cooperative claim)
4. **Boltz Quote API** provides DEX calldata (tBTC → USDT via Uniswap V3)
5. **Smart wallet batches**: `[claim tBTC] + [DEX calls from Boltz] + [approve + createTrade]`

**No Router contract needed.** The smart wallet replaces the Router, and Boltz's Quote API replaces a DEX aggregator.

For withdrawal (Host cashes out to Lightning):

1. Smart wallet batches: `[withdraw USDT from escrow] + [reverse DEX: USDT → tBTC] + [ERC20Swap.lock(tBTC)]`
2. Boltz Submarine swap pays the Lightning invoice

### Implementation checklist

- [ ] `BoltzQuoteClient` — wraps `/quote/{currency}/in`, `/quote/{currency}/out`, `/quote/{currency}/encode`
- [ ] `SwapAndDepositBuilder` — composes UserOp: claim → Boltz DEX calls → approve → createTrade
- [ ] `WithdrawAndSwapBuilder` — composes UserOp: withdraw → Boltz DEX calls → ERC20Swap.lock
- [ ] Deploy MultiEscrow on Arbitrum mainnet (or verify existing deployment)
- [ ] App UI: token selector, quote display (from Boltz Quote API), slippage settings
- [ ] Test with small amounts on Arbitrum mainnet (Boltz has no Arbitrum testnet)

---

## Open Questions

1. **Rootstock USDT liquidity** — Is there enough depth on SushiSwap/Sovryn for typical booking amounts ($100-$5000)? Need to check pool sizes.
2. **Which stablecoin?** — USDT, DOC (BTC-backed stablecoin on Rootstock), or USDC? DOC is native to Rootstock and BTC-backed.
3. **Boltz tBTC on Rootstock?** — Boltz doesn't currently list tBTC as a token on Rootstock. If they add it, we could use the same tBTC→USDT routing pattern they use on Arbitrum.
4. **Price oracle** — For displaying prices in USD during booking, we need a reliable RBTC/USD price feed. Rootstock has Chainlink oracles.
5. **Slippage tolerance** — What default slippage to set for the DEX leg? 0.5% for stablecoin swaps, 1% for volatile pairs?
6. **Multi-chain escrow** — If we deploy on Arbitrum too, do we need cross-chain trade resolution? Or just keep them independent?
7. **Quote freshness** — How long is a Boltz DEX quote valid? Should we re-quote just before UserOp submission?
8. **Boltz Rate Consistency** — When creating a reverse submarine swap, the Boltz quote includes their fee + the amount of tBTC to be locked. Does the amount locked in the HTLC match what we then pass to the DEX quote? Need to verify the math: `invoiceAmount - boltzFee - minerFee = tBTC locked = amountIn for DEX quote`.

---

## Stealth Addresses Analysis: ERC-5564 / ERC-6538 vs Current BIP-32 Approach

### Problem Statement

The current per-trade address derivation uses `m/44'/60'/0'/0/{accountIndex}` from a BIP-32 master key. Each derived key becomes the owner of a counterfactual ERC-4337 smart wallet. This provides trade unlinkability but makes balance tracking painful:

- **N separate addresses** to poll for balances
- No aggregated view without scanning all derived indices (linear scan up to `maxAccountIndex`)
- Each address is a separate counterfactual smart wallet (CREATE2)
- The `TradeAccountAllocator` must linearly scan indices to find trade accounts

The question: could **stealth addresses** (ERC-5564 + ERC-6538) replace this BIP-32 derivation and provide the same unlinkability with better scanning?

---

### How ERC-5564 Stealth Addresses Work

**Key Setup (one-time):**

- Guest generates spending key $p_{spend}$ and viewing key $p_{view}$
- Publishes stealth meta-address: $(P_{spend}, P_{view})$ where $P = G \cdot p$
- Optionally registers in the ERC-6538 registry at `0x6538E6bf4B0eBd30A8Ea093027Ac2422ce5d6538`

**Per-Trade Address Generation (by sender/escrow):**

1. Generate random ephemeral key $p_{eph}$, derive $P_{eph} = G \cdot p_{eph}$
2. Compute shared secret: $s = p_{eph} \cdot P_{view}$
3. Hash: $s_h = \text{hash}(s)$
4. Extract view tag: $v = s_h[0]$ (first byte)
5. Stealth public key: $P_{stealth} = P_{spend} + s_h \cdot G$
6. Stealth address: $a_{stealth} = \text{pubkeyToAddress}(P_{stealth})$
7. Emit `Announcement(schemeId, stealthAddress, caller, ephemeralPubKey, metadata)` via the singleton at `0x55649E01B5Df198D18D95b5cc5051630cfD45564`

**Scanning (by guest with viewing key):**

1. Fetch all `Announcement` events from the ERC5564Announcer contract
2. For each: compute $s = p_{view} \cdot P_{eph}$, hash it, check view tag (1 ecMUL + 1 HASH)
3. View tag matches ~1/256 of the time → only then do full verification (1 ecMUL + 1 ecADD + 1 HASH)
4. If address matches: derive spending key $p_{stealth} = p_{spend} + s_h$

**Net cost per scanned announcement:** 1 ecMUL + 1 HASH (fast), with 0.4% requiring full check.

---

### Umbra Protocol Deployment Status

Umbra (ScopeLift) is the primary ERC-5564 implementation. Contracts deployed at the same address on all supported chains:

| Contract           | Address                                      |
| ------------------ | -------------------------------------------- |
| Umbra              | `0xFb2dc580Eed955B528407b4d36FfaFe3da685401` |
| StealthKeyRegistry | `0x31fe56609C65Cd0C510E7125f051D440424D38f3` |
| UmbraBatchSend     | `0xDbD0f5EBAdA6632Dde7d47713ea200a7C2ff91EB` |

**Supported chains:** Mainnet (1), Optimism (10), Polygon (137), Arbitrum (42161), Base (8453), Sepolia (11155111).

**⚠️ NOT deployed on Rootstock (chain 30).** They recently _removed_ Gnosis chain support. No indication of Rootstock support planned.

The ERC-5564/6538 singleton contracts (CREATE2-deployed) could theoretically exist on any EVM chain if someone sends the deployment tx to the deterministic deployer, but the Umbra scanning infrastructure (subgraphs, relayers) does not cover Rootstock.

---

### Compatibility with ERC-4337 (Account Abstraction)

This is where it gets nuanced. There are **two different models**:

#### Model A: Stealth EOA (standard ERC-5564)

The stealth address $a_{stealth}$ is derived from $P_{stealth}$ via `keccak256(pubkey) → address`. This is an **EOA**. The guest derives the spending key $p_{stealth}$ and can sign transactions directly.

- ✅ Works out of the box with ERC-5564
- ❌ **No account abstraction features** (no batching, no paymaster, no social recovery)
- ❌ Each stealth EOA needs native gas to transact → privacy leak when funding it
- ❌ We lose all the benefits of our current smart wallet architecture

#### Model B: Stealth-owned Smart Wallet (hybrid)

Use the stealth key $p_{stealth}$ as the **owner** of a counterfactual ERC-4337 wallet. The on-chain wallet address is `CREATE2(factory, salt=hash(P_stealth), initCode)`.

- ✅ Preserves all ERC-4337 benefits (batching, paymaster, social recovery)
- ✅ Paymaster can sponsor gas (no privacy leak from gas funding)
- ❌ **The on-chain address ≠ the stealth address.** The stealth address is the owner key's address; the smart wallet is at a different CREATE2 address.
- ❌ **Standard ERC-5564 Announcement scanning breaks.** The Announcer emits the stealth address, but funds are at the CREATE2 wallet address. Scanning the Announcer tells you the owner key, not where the money is.
- ❌ Must build custom scanning: find stealth address from Announcement → derive CREATE2 wallet address → check balance there.

Vitalik explicitly acknowledges this in his stealth address blog post: _"in both Bitcoin and Ethereum (including correctly-designed ERC-4337 accounts), an address is a hash containing the public key used to verify transactions from that address."_ But he's describing the theoretical compatibility, not the practical integration challenge.

#### Model C: Vitalik's ZKP approach (future)

For full stealth + smart wallet + social recovery, Vitalik describes a ZKP-based scheme where the wallet code contains $k = \text{hash}(\text{hash}(x), c)$ and spending requires a ZK proof of knowledge of $x$ and $c$. This enables:

- Stealth addresses that ARE smart contract wallets
- Social recovery via on-chain key rotation affecting all stealth wallets
- Cross-L2 recovery

- ❌ **Requires STARKs on-chain** → hundreds of thousands of extra gas per tx
- ❌ No production implementation exists
- ❌ Way beyond current scope

---

### Head-to-Head: Current BIP-32 vs Stealth Addresses

| Dimension                      | Current BIP-32 (`m/44'/60'/0'/0/{i}`)                                         | ERC-5564 Stealth Addresses                                                                        |
| ------------------------------ | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| **Address generation**         | Deterministic from master seed + index                                        | Randomized per-trade (ephemeral key)                                                              |
| **Who generates**              | Guest derives their own                                                       | Sender (escrow/relayer) generates                                                                 |
| **Unlinkability**              | ✅ Addresses unlinkable without master key                                    | ✅ Addresses unlinkable without viewing key                                                       |
| **Smart wallet compat**        | ✅ Native — key is wallet owner                                               | ⚠️ Requires hybrid model (Model B)                                                                |
| **Balance scanning**           | Linear scan: derive key[i] → compute CREATE2 addr → RPC `getBalance` for each | Event scan: filter `Announcement` logs → ecMUL+HASH per event → derive wallet addr → `getBalance` |
| **Scanning cost (our trades)** | **N RPC calls** (one per index, N = our trade count)                          | **M event parses + K RPC calls** (M = ALL announcements globally, K = our matches)                |
| **Anonymity set**              | N/A (no public announcements)                                                 | All users of the Announcer contract on that chain                                                 |
| **On-chain footprint**         | None (off-chain derivation)                                                   | `Announcement` event per trade (~1500 gas)                                                        |
| **Recovery**                   | Restore from seed phrase → re-derive all keys                                 | Need seed phrase + must re-scan all historical Announcements                                      |
| **Gas overhead**               | Zero                                                                          | ~2500 gas per `announce()` call + ephemeral key storage                                           |
| **Dependency**                 | None — pure client-side crypto                                                | ERC5564Announcer contract must be deployed on chain                                               |
| **Rootstock support**          | ✅ Works today                                                                | ❌ No Announcer deployed, no Umbra, no scanning infra                                             |

---

### The Scanning Problem — Stealth Is Actually WORSE For Our Use Case

This is the critical insight. The user's complaint is that scanning N addresses is painful. Let's compare the actual work:

**Current BIP-32 approach:**

```
for i in 0..maxAccountIndex:
    key = derive(masterKey, "m/44'/60'/0'/0/{i}")
    walletAddr = CREATE2(factory, hash(key.pubkey))
    balance = rpc.getBalance(walletAddr)      // one RPC call per index
```

Cost: **N RPC calls** where N = number of trades THIS guest has ever done.

**Stealth address approach:**

```
// Step 1: Fetch ALL Announcement events (every user on the chain)
events = announcer.getLogs(fromBlock=deployBlock)  // could be millions

// Step 2: Filter for our announcements
for event in events:
    s = pView * event.ephemeralPubKey       // 1 ecMUL (~0.1ms)
    viewTag = hash(s)[0]                     // 1 HASH
    if viewTag != event.metadata[0]: continue  // 255/256 skip here
    // Full check (1/256 of events):
    Pstealth = Pspend + hash(s) * G          // 1 ecMUL + 1 ecADD + 1 HASH
    if pubkeyToAddress(Pstealth) == event.stealthAddress:
        // This is ours! Derive wallet address
        walletAddr = CREATE2(factory, hash(Pstealth))
        balance = rpc.getBalance(walletAddr)
```

Cost: **1 large log query** + **M ecMUL operations** (M = ALL announcements, not just ours) + **K RPC calls** (K = our matches).

**On a chain with heavy stealth address usage**, M >> N. The guest must process every single announcement from every sender on the chain to find their own. View tags reduce the full-check cost by ~256x, but the initial ecMUL-per-event is still required.

**On a chain with almost no stealth address usage** (like Rootstock today), M ≈ N (only Hostr users), so there's no anonymity benefit — and we've added on-chain gas costs + contract dependencies for equivalent scanning work.

**The BIP-32 approach is actually more efficient for our use case** because:

1. We only scan OUR indices (not everyone's)
2. The scan is pure RPC calls (no crypto per step)
3. No on-chain Announcer dependency
4. The `maxAccountIndex` gives us an upper bound (no need to scan from genesis block)

---

### Where Stealth Addresses WOULD Help

Stealth addresses solve a different problem than what we have:

| Stealth addresses are great for...                                          | Our situation                                                  |
| --------------------------------------------------------------------------- | -------------------------------------------------------------- |
| **Receiving payments from unknown senders** who only know your meta-address | Escrow parties are known; trades are pre-negotiated on Nostr   |
| **Public donation/payment addresses** where you want unlinkable receipts    | Our addresses are never published; they're derived client-side |
| **Interoperability** — any app can send to your stealth meta-address        | We control both sides; no third-party senders                  |
| **Non-interactive** generation by the sender                                | We already non-interactively derive via BIP-32                 |

In our system, the guest already knows which trades they're part of (via Nostr reservation events). The address derivation is a local computation. Nobody needs to "discover" payments — the guest created the trade and knows the index.

---

### What Would Actually Improve Balance Scanning

Instead of stealth addresses, the real improvements are:

#### 1. Multicall Batching (immediate win)

```dart
// Instead of N separate RPC calls:
final balances = await multicall.aggregate([
  for (var i = 0; i <= maxAccountIndex; i++)
    Call(target: walletFactory, data: encodeGetBalance(deriveAddress(i)))
]);
```

One RPC call returns all N balances. This is the #1 fix.

#### 2. On-chain Balance Registry

The `MultiEscrow` contract already tracks `balances[user][token]`. When a trade resolves, the balance accrues to the user's address in the contract. The guest can call `balanceOf(beneficiary)` to get their aggregate balance across all resolved trades — **a single RPC call**.

The N-address problem only applies to **in-flight** trades (funds locked in counterfactual wallets that haven't been deposited to escrow yet). Once in escrow, balances are already aggregated.

#### 3. Local Index Tracking

Store the `accountIndex → tradeId` mapping locally (already done via `TradeAccountAllocator`). The scan only needs to check **unresolved** indices, not all historical ones.

#### 4. Subgraph / Event Indexer

Index `MultiEscrow` events (TradeCreated, TradeResolved, etc.) keyed by participant address. This gives a complete trade history without scanning derived addresses at all.

---

### Gotchas if We Tried Stealth Addresses Anyway

1. **No Announcer on Rootstock.** We'd have to deploy the ERC-5564 singleton ourselves. Since it uses CREATE2 with a specific salt, we'd need to send the exact deployment tx to the deterministic deployer at `0x4e59b44847b379578588920ca78fbf26c0b4956c` on Rootstock.

2. **Empty anonymity set.** On Rootstock, we'd be the only users of the Announcer contract. All announcements = Hostr trades. An observer filtering Announcer events sees exactly our trade graph — zero privacy improvement over the current approach.

3. **Gas overhead per trade.** Each trade needs an `announce()` call (~2500 gas + calldata for ephemeral key + view tag). Small but nonzero, and provides no benefit given point #2.

4. **Dart/Flutter crypto.** We'd need secp256k1 ecMUL in Dart for the scanning. We already have `coinlib` with secp256k1 support, but the scanning hot loop (ecMUL per announcement) would be slow on mobile web. BIP-32 derivation is already slow enough that we cache aggressively.

5. **Smart wallet address mismatch.** As discussed in Model B above, the stealth address ≠ the smart wallet address. We'd need custom infrastructure to bridge this gap — the standard ERC-5564 tooling won't work.

6. **Recovery complexity.** To recover stealth wallet funds, the user must re-scan ALL historical Announcement events from the Announcer contract's deploy block. With BIP-32, they just re-derive from the seed and scan up to `maxAccountIndex`.

7. **Escrow contract changes.** The `MultiEscrow.createTrade()` currently takes explicit buyer/seller/arbiter addresses. With stealth addresses, the escrow contract (or a relayer) would need to generate the stealth address and call `announce()`. This adds a new contract interaction and changes the trade creation flow.

---

### Verdict

**Stealth addresses (ERC-5564/6538) do NOT improve the Hostr guest's situation and would make it worse.**

| Claim                                                     | Reality                                                                                                                                                                                       |
| --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "Balance scanning becomes a single viewing-key operation" | ❌ It becomes scanning ALL global announcements (not just ours) + crypto per event. Worse than N targeted RPC calls.                                                                          |
| "Guest publishes one stealth meta-address"                | The guest doesn't publish any address today. BIP-32 derivation is fully private — nothing goes on-chain until trade creation. Publishing a meta-address is strictly more information leakage. |
| "Only the guest can compute private keys"                 | Same as today — only the guest has the BIP-32 master key.                                                                                                                                     |
| "Each trade generates a unique stealth address"           | Same as today — each BIP-32 index produces a unique address.                                                                                                                                  |

**Recommendation:** Keep the BIP-32 approach. Improve scanning with:

1. **Multicall batching** for balance queries (turns N RPCs into 1)
2. **Local index tracking** (only scan unresolved trades)
3. **Subgraph/indexer** for historical trade discovery
4. **`MultiEscrow.balanceOf()`** for aggregate resolved balances (already exists)

Stealth addresses are designed for a fundamentally different threat model (public payment endpoints with unknown senders). Our system has pre-negotiated trades between known parties on a separate communication channel (Nostr). The BIP-32 derivation already provides the unlinkability we need, and its scanning model is better suited to our bounded, self-known trade set.
