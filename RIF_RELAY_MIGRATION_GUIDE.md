# Custom RIF Relay Migration Guide

This guide lays out the migration plan for moving hostr from the Boltz-hosted relay flow to a self-hosted, escrow-specific RIF Relay stack on Rootstock.

It is intentionally opinionated:

- one relay instance should serve one escrow wrapper / escrow family;
- verifier policy should be owned by hostr, not by Boltz;
- contract addresses should be tracked in-repo;
- contract logic should absorb as much business complexity as possible so the relay stays simple.

---

## 1. Target architecture

### Goal

Replace the current dependency on Boltz-hosted relay infrastructure with a hostr-owned relay stack that:

- sponsors gas for hostr escrow actions;
- can be tied to a specific escrow wrapper contract;
- can evolve as `MultiEscrow.sol` evolves;
- can later support multiple escrow wrappers, each with its own relay/verifier policy.

### Recommended shape

For each escrow wrapper family, deploy:

1. one `RelayHub` stack;
2. one smart-wallet factory;
3. one deploy verifier;
4. one relay verifier;
5. one relay server;
6. one escrow wrapper contract (or one family of compatible contracts).

In practice, the key coupling is:

- **client** knows which relay URL + verifier + factory to use;
- **verifier** knows which target contracts and methods it will sponsor;
- **escrow wrapper** exposes the exact atomic methods the relay is allowed to execute.

This gives you the flexibility to run different relays for different escrow products without turning one relay into a universal gas sponsor.

---

## 2. Current state in this repo

### Local development

Local dev already runs a Boltz-flavored relay container through [compose.override.yaml](compose.override.yaml).

At startup it currently:

1. deploys RIF relay contracts on Anvil;
2. starts the relay server;
3. runs registration.

The local relay config override is in [docker/rif-relay/local.json5](docker/rif-relay/local.json5).

### Contract deployment tooling

The relay contracts repo at [dependencies/rif-relay-contracts](dependencies/rif-relay-contracts) already contains:

- a custom Hardhat `deploy` task in [dependencies/rif-relay-contracts/hardhat.config.ts](dependencies/rif-relay-contracts/hardhat.config.ts);
- mutable allowlist tasks:
  - `allow-contracts`
  - `allowed-contracts`
  - `remove-contracts`
- disk-based address tracking in `contract-addresses.json` via [dependencies/rif-relay-contracts/tasks/deploy.ts](dependencies/rif-relay-contracts/tasks/deploy.ts).

### Client config today

Today the escrow app hardcodes relay/factory/verifier addresses in [escrow/lib/injection.dart](escrow/lib/injection.dart).

That means any verifier/factory redeploy requires a client config update.

---

## 3. Proposed hostr migration plan

### Phase 1 — fork the Boltz verifier path

Create a hostr-specific relay contract package by forking the Boltz-style verifier path.

Do **not** start from a completely open verifier.

Instead:

- keep the existing RIF relay server model;
- keep the smart-wallet deployment/relay flow;
- replace Boltz claim-specific validation with escrow-specific validation.

### Phase 2 — add a hostr escrow wrapper contract

Do not point the relay directly at raw `MultiEscrow` until the interface is stable.

Instead, introduce a wrapper / adapter contract with a narrow purpose, for example:

- `HostrEscrowRelayAdapter`
- `EscrowSponsoredActions`
- `MultiEscrowRelayedFacade`

This wrapper should expose only the atomic methods you want to sponsor.

Examples:

- `claimAndCreateTrade(...)`
- `fundTrade(...)`
- `releaseTrade(...)`
- `claimTimeout(...)`
- `arbitrateTrade(...)`

The wrapper is what the verifier allowlists.

This is the cleanest way to satisfy requirement (1):

> the relay instance is tied directly to my escrow contract wrapper, so different escrow contracts can use different relays.

### Phase 3 — switch the SDK from Boltz addresses to hostr addresses

Update hostr config so the relay URL, deploy verifier, relay verifier, and smart-wallet factory point to hostr-owned addresses.

Primary touchpoints:

- [hostr_sdk/lib/config.dart](hostr_sdk/lib/config.dart)
- [hostr_sdk/lib/usecase/evm/chain/rootstock/rif_relay/rif_relay.dart](hostr_sdk/lib/usecase/evm/chain/rootstock/rif_relay/rif_relay.dart)
- [escrow/lib/injection.dart](escrow/lib/injection.dart)

### Phase 4 — move business logic on-chain

The relay should not orchestrate multi-step backend behavior.

Instead, the contract wrapper should do the atomic unit of work in one call.

Good:

- one relayed call to `claimAndCreateTrade(...)`
- one relayed call to `releaseTrade(...)`

Bad:

- relay claims funds in one call, then backend separately funds escrow in a second step.

---

## 4. Private key plan

## Short answer

You can reuse `ESCROW_PRIVATE_KEY` for **deployer / verifier-owner / registration-owner** duties, but **not for every relay identity**.

### Important distinction

RIF Relay involves multiple keys / identities:

1. **deployer / admin / verifier owner**
   - deploys contracts;
   - owns verifier allowlist state;
   - runs `allow-contracts` / `remove-contracts`;
   - may be the same EOA as your existing `ESCROW_PRIVATE_KEY`.

2. **relay owner used during registration**
   - funds / stakes the relay manager;
   - can also be the same EOA as `ESCROW_PRIVATE_KEY` if you insist.

3. **relay manager + relay worker keys**
   - used by the running relay server;
   - generated / managed inside the relay server workdir;
   - these are not the same identity as the escrow admin key.

So the realistic plan is:

- keep **one external high-value secret**: `ESCROW_PRIVATE_KEY`;
- let the server manage its own manager/worker operational keys inside its persistent workdir.

### Recommendation

Use `ESCROW_PRIVATE_KEY` only for:

- contract deployment;
- verifier ownership;
- allowlist updates;
- relay registration ownership.

Do **not** try to force the relay worker key to equal the escrow admin key.

That would collapse admin authority and hot operational signing into one secret, which is a bad production setup.

---

## 5. Funding model

## Important correction

The relay does **not** automatically become self-sustaining just because it collects fees.

Why:

- the **relay worker** pays gas in RBTC up front;
- the **relay manager** must keep workers topped up;
- fee reimbursement may be delayed, incomplete, zero, or intentionally subsidized;
- failed / rejected / low-fee / mispriced transactions can still burn operational balance.

RIF Relay docs are explicit that workers must maintain native balance and that the manager replenishes them.

### What stays funded over time

Three balances matter:

1. **stake on the RelayHub**
   - required for registration;
   - not day-to-day spendable gas balance.

2. **relay manager RBTC balance**
   - used to replenish workers.

3. **relay worker RBTC balance**
   - directly pays transaction gas.

### Production funding rule

Treat the relay like a hot operational wallet with revenue, not like a perpetual motion machine.

You should assume you need:

- initial funding before first registration;
- occasional top-ups;
- monitoring / alerts when manager or worker balance drops.

### Recommended hostr funding policy

For initial rollout:

- subsidize all hostr-sponsored transactions;
- set verifier policy so only hostr-approved methods are relayed;
- monitor fees collected, but do not assume break-even immediately.

Later, once economics are clear, you can decide whether to:

- keep zero-fee sponsorship;
- charge users in-protocol;
- or reclaim costs inside escrow business logic.

### How the relay decides what fee to charge

If you do **not** want to subsidize transactions, your relay needs to quote a fee that is intended to cover gas, but it does **not** need to include profit.

At a high level, the fee charged by the relay is driven by:

1. the server-side gas assumptions;
2. the server-side fee markup configuration;
3. the final `tokenAmount` included in the signed relay request;
4. the `tokenContract` used for reimbursement.

In RIF Relay terms, the reimbursed amount is the `tokenAmount` on the request. Even though the field is called `tokenAmount`, it is also used for native-coin reimbursement when `tokenContract == address(0)`.

For hostr, the target policy should be:

- **no subsidy by default**;
- **minimal markup**;
- fees set to approximately cover the relay's gas spend and operational slippage.

That means you should configure the relay so the estimated reimbursement is roughly:

$$
	ext{required fee} \approx \text{gas used} \times \text{gas price} + \text{safety buffer}
$$

with the safety buffer being small but non-zero.

Practically, this means:

- do not set the relay's fee percentage to zero unless you intentionally want sponsorship;
- do not set it high enough to target profit extraction;
- do keep enough spread to survive mild gas estimation error and block-to-block gas price movement.

### Where that fee shows up in the flow

The normal flow is:

1. client asks the relay for an estimate;
2. relay calculates the required reimbursement amount;
3. client signs a request containing that `tokenAmount`;
4. relay executes the transaction;
5. if execution succeeds, the smart wallet pays `tokenAmount` to `feesReceiver` inside the same on-chain transaction.

So the relay does **not** just "charge later" off-chain. The reimbursement amount is part of the signed on-chain request.

### When reimbursement happens

Reimbursement happens **during the same relayed transaction**, not in a later settlement cycle.

More specifically:

- on the **deploy path**, the wallet is created, performs the requested call, and then pays the relay fee;
- on the **relay path**, the already-deployed smart wallet performs the requested call, and then pays the relay fee.

This ordering matters:

- the worker pays gas to submit the transaction up front;
- the wallet reimburses the configured fee **after** the downstream call runs;
- any remaining balance is then returned according to the wallet logic.

So from your perspective as relay operator:

- **gas spend happens first operationally**;
- **fee reimbursement happens in the successful on-chain execution path**.

### Who gets reimbursed

The reimbursement is sent to the request's `feesReceiver` address.

In practice, that is the relay-side fee recipient exposed by `/chain-info`.

That address may be:

- the worker EOA directly; or
- a collector / fee receiver contract, depending on your relay setup.

For hostr, the simpler initial setup is:

- reimburse to the relay-controlled fee receiver;
- periodically inspect balances and sweep if needed.

### Important caveat on failed transactions

You are **not** guaranteed reimbursement for every attempted relay.

The important operational rule is:

- if the relayed transaction succeeds, the reimbursement path is expected to run in that same transaction;
- if the transaction reverts or fails before fee payment completes, the relay worker may still have burned gas without being reimbursed.

This is exactly why prefunding is still required even when your relay is configured to charge fees.

### Hostr recommendation

For hostr production, the funding policy should be:

- charge fees that aim for **cost recovery, not profit**;
- treat reimbursement as **same-transaction recovery on success**;
- keep manager/worker RBTC balances high enough to survive failed relays and volatility;
- review actual realized reimbursement versus gas spend before tightening margins.

### Funding runbook

When the relay server is running, inspect `/chain-info` to get:

- `relayManagerAddress`
- `relayWorkerAddress`
- `feesReceiver`

Operational runbook:

1. send RBTC to the relay manager;
2. ensure registration stake is present;
3. verify the worker gets replenished;
4. monitor `ready` status.

### README-level rule

**Do not rely on fees alone to keep the relay solvent.**

Assume periodic funding is required.

---

## 6. Deployment and address tracking

### Recommended source of truth

Commit relay contract addresses in-repo.

Recommended files:

- `dependencies/rif-relay-contracts/contract-addresses.json`
- optionally a hostr-owned normalized copy such as:
  - `infrastructure/rif-relay/mainnet.json`
  - `infrastructure/rif-relay/testnet.json`

### Recommended production process

Initial deploys should be run manually from a trusted operator machine.

#### Testnet

```bash
cd dependencies/rif-relay-contracts
export PK=0x...
npx hardhat deploy --network testnet
```

#### Mainnet

```bash
cd dependencies/rif-relay-contracts
export PK=0x...
npx hardhat deploy --network mainnet
```

Then:

1. commit the resulting address file;
2. update client config with the hostr relay URL / verifier / factory addresses;
3. deploy the relay server container using those addresses.

### CI recommendation

For now:

- **do not** let CI deploy relay contracts automatically;
- **do** let CI build and deploy the server/container and client code;
- keep deploys as a manual ops step until the contract surface stabilizes.

That matches your current stage of development.

---

## 7. Verifier design

## What the verifier should do

The hostr verifier should be broader than Boltz’s claim-only verifier, but still policy-driven.

Recommended policy model:

- allowlisted target contract addresses;
- allowlisted method selectors per contract;
- optional method-level constraints;
- optional fee / value / gas bounds;
- no arbitrary target execution.

### Suggested verifier shape

At a high level, the verifier should validate:

1. target contract is allowlisted;
2. selector is approved for that contract;
3. for payable methods, `value` fits policy;
4. for release/arbitrate/claim methods, the request shape is valid;
5. optional anti-griefing checks pass.

### Suggested storage layout

```solidity
mapping(address => bool) public allowedContracts;
mapping(address => mapping(bytes4 => bool)) public allowedSelectors;
mapping(address => mapping(bytes4 => MethodPolicy)) public methodPolicies;
```

Where `MethodPolicy` could include fields like:

- `bool enabled`
- `bool payableAllowed`
- `uint256 maxValue`
- `uint256 maxGasLimit`
- `bool requireTradeExists`
- `bool requireTrustedWrapper`

### What not to do

Do **not** build a verifier that just says:

> any signed call is fine, pay the gas.

That turns the relay into a generic gas sponsor and makes griefing much easier.

---

## 8. Verifier update process

This is the most important operational distinction.

## A. Allowlist / config-only change

Examples:

- add a new escrow wrapper address;
- remove an old wrapper address;
- add an additional supported contract.

Use the existing tasks in [dependencies/rif-relay-contracts/hardhat.config.ts](dependencies/rif-relay-contracts/hardhat.config.ts):

```bash
npx hardhat allow-contracts --contract-list "0xYourWrapper" --network testnet
npx hardhat allow-contracts --contract-list "0xYourWrapper" --network mainnet
```

This does **not** require:

- verifier redeploy;
- relay server redeploy;
- client config update.

## B. Verifier logic change

Examples:

- new supported method selectors;
- new validation rules;
- new fee logic;
- new anti-griefing rules.

This **does** require:

1. compile and deploy a new verifier;
2. record new verifier addresses;
3. update client config to point to the new verifier(s);
4. roll out the app / server config.

### Recommended versioning policy

Use explicit verifier versions:

- `HostrEscrowDeployVerifierV1`
- `HostrEscrowRelayVerifierV1`
- `HostrEscrowDeployVerifierV2`
- `HostrEscrowRelayVerifierV2`

Do not mutate verifier semantics invisibly.

### Recommended development rule

During rapid development:

- expect frequent verifier redeploys on local dev and testnet;
- minimize mainnet verifier changes until wrapper method names stabilize.

### Stable interface strategy

To reduce verifier churn, freeze a small relayed method surface early.

For example, only sponsor wrapper methods like:

- `relayedCreateTrade(...)`
- `relayedRelease(...)`
- `relayedClaim(...)`
- `relayedArbitrate(...)`

Then let internal implementation behind those methods evolve without changing selectors.

---

## 9. How `MultiEscrow.sol` needs to change

Your current contract in [escrow/contracts/contracts/MultiEscrow.sol](escrow/contracts/contracts/MultiEscrow.sol) is not relay-ready yet.

### Current blockers

#### 1. Direct `msg.sender` role checks

Current methods compare `msg.sender` directly to stored buyer/seller/arbiter addresses.

Examples:

- `onlyArbiter(...)`
- `releaseToCounterparty(...)`

Under RIF Relay, the target contract sees the **smart wallet** as `msg.sender`, not the user EOA.

So the current direct role checks will fail unless the trade stores smart-wallet addresses instead of EOAs.

#### 2. No relayed identity abstraction

`MultiEscrow` currently has no way to interpret:

- smart wallet owner;
- wrapper-authorized caller;
- or signed user intent.

#### 3. No wrapper-specific sponsored entrypoints

The contract currently exposes raw business methods only.

That makes verifier policy and future compatibility harder.

### Recommended changes

#### Option A — wrapper contract owns relayed entrypoints (recommended)

Keep `MultiEscrow` mostly simple.

Add a separate wrapper contract that:

- receives relayed calls;
- resolves identity rules;
- forwards into `MultiEscrow`.

This is the cleanest option.

#### Option B — make `MultiEscrow` smart-wallet aware

If you want `MultiEscrow` itself to be the relayed target, add:

1. a trusted factory / wallet model;
2. a helper to resolve whether `msg.sender` is:
   - the direct EOA, or
   - a smart wallet whose owner hash matches the expected user;
3. role checks that use that helper instead of raw `msg.sender` equality.

Because RIF smart wallets expose `getOwner()`, you can design an adapter check around wallet ownership if needed.

### Minimum recommended product interface

Whether the wrapper sits outside `MultiEscrow` or inside it, define stable sponsored entrypoints such as:

- `createTradeRelayed(...)`
- `releaseToCounterpartyRelayed(...)`
- `claimRelayed(...)`
- `arbitrateRelayed(...)`
- `claimAndCreateTradeRelayed(...)`

### Payable flow considerations

If a relayed method needs to fund a trade, then:

- the method must be payable;
- the wallet / wrapper flow must be able to forward value;
- the contract must not assume the caller EOA itself holds RBTC.

### Recommended contract design rule

Preserve selector stability.

Even if internal trade struct logic changes, try to keep the sponsored entrypoint selectors stable so verifier/client churn stays low.

---

## 10. Recommended hostr directory / ownership plan

### Contracts

Recommended additions:

- `dependencies/rif-relay-contracts/contracts/verifier/HostrEscrowDeployVerifier.sol`
- `dependencies/rif-relay-contracts/contracts/verifier/HostrEscrowRelayVerifier.sol`
- `escrow/contracts/contracts/HostrEscrowRelayAdapter.sol`

### Config

Recommended additions:

- `docker/rif-relay/testnet.json5`
- `docker/rif-relay/mainnet.json5`
- `infrastructure/rif-relay/README.md` only if later needed

### Client config

Recommended change:

- stop treating hostr relay addresses as implicit Boltz config;
- either rename config fields later, or keep the field names temporarily but point them at hostr-owned infrastructure.

---

## 11. Rollout plan

### Step 1 — contract fork

- fork Boltz verifier logic into hostr verifier contracts;
- remove `BoltzUtils.validateClaim(...)` dependency;
- add contract + selector allowlist logic.

### Step 2 — wrapper contract

- introduce a relayed escrow wrapper;
- freeze initial sponsored method selectors.

### Step 3 — local dev

- replace the Boltz verifier deployment path in local Anvil with hostr verifier deployment;
- point [escrow/lib/injection.dart](escrow/lib/injection.dart) at local hostr verifier addresses.

### Step 4 — testnet

- deploy relay contracts to Rootstock testnet;
- deploy wrapper + `MultiEscrow` testnet versions;
- run `allow-contracts` for the wrapper;
- start hostr relay server;
- update client testnet config.

### Step 5 — mainnet

- manual deploy from operator machine;
- commit address records;
- update production config;
- fund manager/stake;
- start relay server;
- monitor readiness and balances.

---

## 12. Decisions to lock now

To avoid churn, lock these decisions before implementation:

1. **One relay per escrow wrapper family?**
   - recommended: yes.

2. **Use the same admin key as `ESCROW_PRIVATE_KEY`?**
   - acceptable for deploy / ownership / registration;
   - not for worker hot keys.

3. **Use a wrapper instead of relaying directly into raw `MultiEscrow`?**
   - recommended: yes.

4. **Allow arbitrary transactions?**
   - recommended: no.

5. **Assume fees keep the relay solvent automatically?**
   - recommended: no.

---

## 13. Immediate next implementation tasks

1. create `HostrEscrowDeployVerifier.sol`;
2. create `HostrEscrowRelayVerifier.sol`;
3. define the initial sponsored selector set;
4. design `HostrEscrowRelayAdapter.sol`;
5. decide how buyer/seller/arbiter identity maps to smart wallets;
6. add testnet/mainnet relay config files;
7. add committed address tracking for hostr-owned relay deployments;
8. switch the SDK from Boltz relay addresses to hostr-owned addresses.

---

## 14. Bottom line

The right mental model is:

- **self-host the relay server**;
- **own the verifier policy**;
- **tie each relay to a stable escrow wrapper**;
- **keep admin key reuse limited to deploy/ownership duties**;
- **expect ongoing funding and monitoring**;
- **treat verifier logic changes as versioned contract upgrades**;
- **treat contract allowlist changes as normal on-chain admin operations**.

That gives you a production path that is much closer to Boltz operationally, but under hostr control.
