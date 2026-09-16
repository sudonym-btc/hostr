# Payment driver boundary

NMDK owns EVM escrow and Lightning swap mechanisms. Hostr supplies application
identity, Lightning payment access, preferences and Nostr event subscriptions.
The Flutter application renders driver state and initiates operations through
the Hostr composition layer.

## Package ownership

| Location | Responsibility |
| --- | --- |
| `dependencies/nmdk/packages/marketplace_evm` | Dart swap lifecycle, recovery journal, EVM transport, transaction/contract calls, fee quotes, signing, escrow validation, balance discovery and automatic withdrawals |
| `dependencies/nmdk/packages/marketplace_models` | Canonical Dart marketplace events, payment proofs, amounts and tokens |
| `dependencies/nmdk/dependencies/marketplace-evm-ts` | TypeScript EVM driver |
| `dependencies/nmdk/dependencies/marketplace-cashu-ts` | TypeScript Cashu driver |
| `dependencies/nmdk/dependencies/marketplace-driver-interface-ts` | Common TypeScript payment policy contract |
| `dependencies/nmdk/dependencies/marketplace-evm-contracts` | Solidity source and contract artifacts |
| `hostr_sdk` | Identity, booking and messaging workflows, Nostr publication, driver construction and application adapters |
| `app` | User interface and operation presentation |

Hostr imports `package:marketplace_evm/...` and
`package:marketplace_models/...` directly. The former `models` package and
payment forwarding files in `hostr_sdk` are removed. Each type and mechanism
has one implementation in NMDK; no conversion or compatibility layer sits
between the application and its drivers.

## Application ports

`marketplace_evm/ports.dart` defines key access, the active user, Lightning
payments, driver configuration, operation factories and recovery progress.
`marketplace_evm/funds_monitor_ports.dart` defines payment events, escrow service
discovery and withdrawal preferences. Hostr implements these contracts; NMDK
must never import Hostr, depend on its service container, or reference a path
outside its package.

The balance monitor belongs to the driver because it combines token discovery,
DEX quotes, fee and dust checks, settlement recovery and atomic escrow withdrawal
with swap lockup. Its full implementation moves together. Hostr still owns the
user's withdrawal preference and the Nostr source of advertised escrow services.

The Hostr escrow daemon remains an application consumer: it watches driver
events, resolves booking participants and publishes booking notices. Contract
encoding, ownership signatures, escrow settlement and event decoding remain in
the driver. `signEvmAddressOwnership` is the shared EIP-191 signing helper for
normal operation and seed generation.

## State and generation

HD derivation paths, reserved account zero, trade IDs, operation namespaces,
persistence formats and integer amount precision are defined by the canonical
driver. Their conformance fixtures exercise the same definitions in each
language.

Generated bindings belong beside their canonical inputs in NMDK. Do not restore
ABI or Boltz OpenAPI generation to Hostr. Hostr generators only produce
application code. Sharing a JSON shape does not replace testing
signatures, integer amount behavior or transaction encoding in both languages.

NMDK's `scripts/generate-driver-bindings.mjs` reads the shared contract artifacts
and Boltz OpenAPI source for both languages. Run `npm run generate:drivers` from
NMDK after changing those inputs; its check mode detects stale generated inputs.
Use `--dart` when invoking the generator directly to rebuild Dart bindings too.

Hostr's `escrow/contracts` is a deployment wrapper for the same canonical
artifact. Its validation command checks that input; the deployment task reads
the canonical ABI and bytecode directly into an ethers factory before broadcasting. Compose supplies the NMDK contracts as a named build
context. The contract regression tests execute against NMDK bytecode,
including v7 withdrawal nonces, so local deployment cannot silently build the
former Hostr contract version.

## Verification

From the Hostr repository root:

```sh
node scripts/check-payment-boundary.mjs
```

This fails if implementation or forwarding files return to the removed Hostr directories,
if an NMDK Dart package depends on Hostr, if a driver import escapes its package,
if application code encodes contract calls, if removed forwarding imports return,
or if container builds omit the canonical path packages. The app, SDK and CLI
may inspect driver states; only NMDK constructs swap transitions or writes the
`swap_in` and `swap_out` journals. Hostr must not register an ABI builder,
including a disabled one.

Run package checks in addition to the boundary check:

```sh
cd dependencies/nmdk/packages/marketplace_evm
dart analyze
dart test
cd ../../dependencies/marketplace-evm-ts
npm run build
npm test
```

The standalone Dart monitor regression tests cover Boltz minimum amounts,
DEX conversion before dust checks, event replay ordering and explicit live
balance subscriptions. Ownership proof tests recover the signing address and
reject a changed Nostr identity. Existing Hostr tests exercise the adapters and
booking behavior through direct canonical package imports.

For the consuming application, run `dart test test/unit` from `hostr_sdk`, then
`flutter test` and
`flutter build web --target lib/main_production.dart --no-wasm-dry-run` from `app`. A successful
web build checks that the extracted packages remain browser compatible. Live
swap settlement tests additionally require the configured Boltz/EVM stack;
report those separately from deterministic unit checks.

## Scope of language parity

Both TypeScript and Dart now implement the EVM escrow and Lightning swap driver.
Cashu remains a TypeScript driver. ABIs, Boltz wire models, integer amount models
and EIP-712 signing contracts are generated from the same sources and checked
against shared conformance fixtures. The TypeScript marketplace policy DTOs and
NMDK's Dart Nostr event serialization describe distinct product layers: changing those persisted
formats changes the protocol; unreleased development data can be reset and reseeded. Their differences are recorded
in NMDK's `DRIVER_CONTRACTS.md`.

The canonical escrow artifact is version 7. Deployments and driver signing
share that artifact's domain and withdrawal nonce rules. The driver validates
the deployed code and EIP-712 domain before use.

## Current-format boundary

Removed imports, old recovery schemas, decimal-valued amount JSON and version 6
escrow deployments are not accepted through fallback adapters. Current amount
JSON uses an integer-unit string plus explicit denomination and precision.
Recovery records require the operation and account identity fields written by
the current driver. Hostr is not live, so this is a clean development cutover:
reset disposable chains and local recovery journals, deploy the canonical v7
artifact, refresh the generated address configuration and reseed events. No
migration or v6 compatibility layer is required. Contract bytecode is immutable,
so replacing v6 means a fresh deployment; Hostr's deployment task overwrites the
selected network's recorded address. NMDK's stack rejects stale contract domains
before publishing trusted deployment configuration. These code changes do not
perform a reset or erase existing development data.

External Lightning invoice handoff also belongs to NMDK. Hostr CLI calls
`SwapInOperation.prepareExternalPayment()` instead of writing the swap journal.
The driver validates the invoice and atomically persists its waiting state before
returning it. Tests cover retries, recovery and competing internal dispatch.

## Upgrade validation

Validated locally on Flutter 3.47.4 / Dart 3.13.3 and Node 26.8.2 / npm 12.0.2:

- Production Hostr web build and 59 application tests.
- 768 Hostr SDK tests, 126 canonical model tests and 128 Dart driver tests.
- 22 CLI tests and six escrow service tests; three CLI tests require the live
  development stack and were skipped.
- Native CLI and escrow service bundles; compiled CLI help-command smoke check.
- Clean app, Widgetbook, SDK, CLI, escrow and canonical package analysis.
- TypeScript driver suites, generated-source conformance and package consumer smoke tests.
- 31 deployment-contract tests, seven Foundry tests including fuzz coverage,
  39 MCP tests, 17 relay tests and 15 boundary guard regressions.
- All 75 Hostr/NMDK CI action steps use verified current release commits;
  both workflow collections pass Actionlint 1.7.12.

The [dependency audit](dart-dependencies.md) records the remaining upstream
version constraints. Live settlement and recreating disposable development
databases are separate from these deterministic checks.

## Container and local development builds

The app, escrow daemon and MCP image copy `marketplace_models` and
`marketplace_evm` to `/workspace/dependencies/nmdk/packages` before resolving
Dart dependencies. MCP bundles native libraries from
`marketplace_models/native`. The local escrow service binds both canonical
`lib` directories for development; it has no model facade mount.

CI uses Flutter 3.47.4 with Dart 3.13.3 and Node 26.8.2 with npm 12.0.2. Native builds use Rust 1.98.1; application nginx uses
the stable 1.30.4 release. Dependency lockfiles record the tested package
versions; mechanism and contract changes are validated in their NMDK package.

## Development service versions

The September 2026 image refresh pins published image digests. The Boltz
backend and generated OpenAPI source both target 3.13.0. The active stacks use
Bitcoin Core 31.1, LND 0.21.3-beta (the project's stable release naming), Foundry
1.8.3, Nutshell 0.20.3, LNbits 1.6.1, Alby Hub 1.24.0, PostgreSQL 18.6 and Redis
8.10.1. Proxy images use nginx-proxy 1.11.6 and acme-companion 2.8.2;
observability uses LGTM 0.33.0 and Collector 0.160.0.

The development Foundry services that write bind-mounted state explicitly run
with their previous root UID. The current official Foundry image defaults to a
different UID. Signet's container build installs pnpm 12.4.2 explicitly because
Node 26 no longer includes Corepack.

Version exceptions are deliberate and verifiable: Fulmine 0.3.25 is the latest
stable release (0.4.0 candidates are excluded); the Hostr relay stays at the
current `fix/nip42-compliance` branch head `520d4c0`, which is ahead of its
repository's default branch. Boltz helper images and Pimlico development
helpers publish rolling tags, so their resolved digests provide reproducibility.

The refresh validates registry availability, Compose rendering, and disposable
Bitcoin/LND/Foundry startup tooling. It does not claim a completed live swap or
an upgrade of existing databases. No existing stack or persistent volume is
started or reset by these checks. Recreate disposable development databases for
the new Nutshell and PostgreSQL versions; no application migration layer is
needed for this unreleased setup.
