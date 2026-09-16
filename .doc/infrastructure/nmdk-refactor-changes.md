# NMDK / Hostr refactor changes

Hostr is a consumer of NMDK payment drivers and canonical models. This is a pre-launch cutover: disposable development deployments and state can be recreated without a v6 compatibility or data-migration layer.

## Features

- **Canonical Dart models:** moved marketplace events, amounts, tokens, cryptography helpers and native assets from Hostr into NMDK. Deleted the Hostr model package and forwarding files.
- **Standalone Dart drivers:** moved swaps, escrow, EVM transport/signing, durable operation state, recovery, fees and funds monitoring into NMDK behind typed application ports.
- **Shared contracts:** Solidity defines contract bindings and EIP-712 signing rules; one pinned Boltz OpenAPI defines both REST clients; one amount schema defines strict TypeScript/Dart integer serialization. Shared fixtures cover precision, signatures, calldata and rejected formats.
- **TypeScript drivers:** updated EVM, Cashu, marketplace interfaces, Nostr models and web application dependencies; removed duplicate amount definitions and stale lockfiles.
- **Current API only:** removed compatibility imports, old amount aliases, legacy serialization fallbacks, duplicate NIP-04 notice delivery and proactive relay authentication. SDK instances have independent dependency scopes.
- **CLI payment handoff:** the driver validates and atomically persists external invoice handoff. The CLI does not construct swap transitions or mutate the swap journal.
- **Clean v7 development deployment:** Hostr deploys the canonical artifact afresh and replaces the selected network address. Both NMDK stack initializers reject stale deployed domains; reset/redeploy replaces immutable contract code.
- **Canonical deployment artifacts:** Hardhat 3 deploys and tests NMDK artifacts directly. Removed nested contract snapshots; stack launchers mount the canonical package.
- **Flutter upgrades:** current Flutter/Dart, NDK APIs, Maps plugin, generated code and application dependency updates. Removed the vendored Maps fork.
- **Reproducible tooling:** upgraded npm packages, compilers, generators, pinned service images and CI action releases. Tooling requiring older TypeScript compiler APIs is isolated from the driver builds.
- **Boundary enforcement:** CI rejects Hostr payment mechanisms, old imports, direct swap journal writes, duplicate contract/model sources and reverse NMDK dependencies.
- **Reliable preview test:** isolated Blossom transport verifies that listing previews stage the original image once and reference the staged URL.

## Validation

- Production Hostr web build, native CLI and escrow bundles, and compiled CLI help smoke check passed.
- 1,109 Dart tests passed: SDK 768, models 126, drivers 128, app 59, CLI 22, escrow service 6. Three CLI development-stack tests were skipped.
- TypeScript package suites, shared conformance fixtures, installed-package smoke tests, marketplace app and documentation builds passed.
- Canonical deployment contracts: 31 tests; Foundry: seven tests with fuzz coverage; MCP: 39; relay: 19; boundary guard: 16.
- Clean-v7 initializer checks: six tests; the deployment regression verifies replacement of an old configured address.
- All 75 Hostr/NMDK action steps use verified release pins, and both workflow collections pass Actionlint.
- NMDK npm audit reports zero vulnerabilities. Live provider settlement and persistent database migration were not exercised.

See [payment driver ownership](payment-drivers.md), [Dart dependency constraints](dart-dependencies.md), and [cross-language contracts](driver-contracts.md).

## Feature commit schedule

At the user’s request, author and committer dates are evenly spaced after the latest GitHub profile commit found: [a3f18f793a0e](https://github.com/pats2sats/pats2sats.github.io/commit/a3f18f793a0e4fc8c8663ec5c7f5553bb72399ec), 2026-09-15 19:27:24 UTC−6. These dates are assigned metadata; validation was performed during this refactor.

Interval: **293 seconds**. Child repositories are committed before their consuming gitlinks.

| # | Repository | Date (UTC−6) | Feature |
| --- | --- | --- | --- |
| 1 | `dependencies/nmdk/dependencies/marketplace-driver-interface-ts` | 2026-09-15T19:32:17-06:00 | feat(models): generate one canonical marketplace amount contract |
| 2 | `dependencies/nmdk/dependencies/marketplace-driver-interface-ts` | 2026-09-15T19:37:10-06:00 | build: upgrade TypeScript and use aggregate documentation tooling |
| 3 | `dependencies/nmdk/dependencies/marketplace-evm-contracts` | 2026-09-15T19:42:03-06:00 | feat(contracts): generate shared signing types from the canonical escrow source |
| 4 | `dependencies/nmdk/dependencies/marketplace-evm-contracts` | 2026-09-15T19:46:56-06:00 | build(contracts): upgrade Solidity and TypeScript and regenerate artifacts |
| 5 | `dependencies/nmdk/dependencies/nostr-tools` | 2026-09-15T19:51:49-06:00 | refactor(marketplace): consume the shared amount contract |
| 6 | `dependencies/nmdk/dependencies/nostr-tools` | 2026-09-15T19:56:42-06:00 | build: upgrade crypto dependencies and modernize lint and benchmark tooling |
| 7 | `dependencies/nmdk/dependencies/marketplace-cashu-ts` | 2026-09-15T20:01:35-06:00 | build(cashu): upgrade the Cashu SDK and adapt signature fixtures |
| 8 | `dependencies/nmdk/dependencies/marketplace-cashu-stack` | 2026-09-15T20:06:28-06:00 | build(cashu): refresh pinned mint and Lightning container images |
| 9 | `dependencies/nmdk/dependencies/marketplace-evm-stack` | 2026-09-15T20:11:21-06:00 | feat(stack): deploy canonical v7 escrow and reject stale development contracts |
| 10 | `dependencies/nmdk/dependencies/marketplace-evm-ts/test/stack` | 2026-09-15T20:16:14-06:00 | feat(stack): deploy canonical v7 escrow and reject stale development contracts |
| 11 | `dependencies/nmdk/dependencies/marketplace-evm-ts` | 2026-09-15T20:21:07-06:00 | refactor(evm): consume generated Boltz and escrow signing contracts |
| 12 | `dependencies/nmdk/dependencies/marketplace-evm-ts` | 2026-09-15T20:26:00-06:00 | build(evm): upgrade account abstraction and TypeScript tooling |
| 13 | `dependencies/nmdk/dependencies/marketplace-app-ts` | 2026-09-15T20:30:53-06:00 | build(app): upgrade the marketplace web application toolchain |
| 14 | `dependencies/nmdk/dependencies/marketplace-location-h3-ts` | 2026-09-15T20:35:46-06:00 | build(h3): upgrade TypeScript and shared documentation tooling |
| 15 | `dependencies/nmdk/dependencies/marketplace-location-interface-ts` | 2026-09-15T20:40:39-06:00 | build(location): upgrade TypeScript and shared documentation tooling |
| 16 | `dependencies/nmdk` | 2026-09-15T20:45:32-06:00 | feat(models): add canonical Dart marketplace models and cross-language amount fixtures |
| 17 | `dependencies/nmdk` | 2026-09-15T20:50:25-06:00 | feat(dart): extract EVM and Lightning drivers with recovery and shared binding checks |
| 18 | `dependencies/nmdk` | 2026-09-15T20:55:18-06:00 | build(stack): refresh aggregate service images and verification |
| 19 | `dependencies/nmdk` | 2026-09-15T21:00:11-06:00 | build: upgrade and centralize the TypeScript workspace and CI toolchains |
| 20 | `hostr` | 2026-09-15T21:05:04-06:00 | refactor(payments): consume canonical NMDK models and drivers |
| 21 | `hostr` | 2026-09-15T21:09:57-06:00 | refactor(auth): isolate SDK scopes and use current NIP42 and NIP17 flows |
| 22 | `hostr` | 2026-09-15T21:14:50-06:00 | refactor(app): use canonical models and current Flutter plugins |
| 23 | `hostr` | 2026-09-15T21:19:43-06:00 | refactor(cli): delegate swap handoff and test staged listing previews |
| 24 | `hostr` | 2026-09-15T21:24:36-06:00 | refactor(escrow): consume NMDK settlement and remove old event fallbacks |
| 25 | `hostr` | 2026-09-15T21:29:29-06:00 | build(contracts): deploy canonical v7 artifacts with Hardhat 3 |
| 26 | `hostr` | 2026-09-15T21:34:22-06:00 | build(deps): upgrade JavaScript packages and release tooling |
| 27 | `hostr` | 2026-09-15T21:39:15-06:00 | build(containers): package canonical drivers and pin current services |
| 28 | `hostr` | 2026-09-15T21:44:08-06:00 | ci: enforce driver boundaries with current toolchains and pinned actions |
| 29 | `hostr` | 2026-09-15T21:49:01-06:00 | docs: document canonical drivers and the clean v7 development cutover |

## Included local work

The requested publication includes the remaining Cashu, relay and bunker edits as separate feature commits. Cashu SAT/USD services consume NMDK configuration and readiness helpers; Hostr defines no second payment protocol. The mint research is preserved and explicitly points to NMDK as the implemented contract. The seed-kind correction is preserved in the canonical model, and every project checkout tracks its published `main`.

## Publication fixes

Verification in clean committed checkouts identified and corrected issues that the existing development workspace concealed:

- Reconciled the two EVM stack checkouts onto one history. Replaced an unpublished upstream Boltz gitlink with a published revision and a stack-owned wallet readiness wrapper.
- Removed the orphaned escrow specification gitlink and propagated the complete, recursively cloneable dependency graph.
- Pinned npm 12 in Hostr so release tooling cannot shadow the required workspace package manager with npm 11.
- Built NMDK workspace exports before their runtime tests import them. Updated the package consumer check to npm 12's JSON output format.
- Made Compose structure and image checks independent of ignored local service environment files, while retaining runtime environment requirements.
- Regenerated the missing optional Boltz transaction confirmation field from the canonical schema and refreshed immutable package documentation links.
- Pinned Compose 5.5.1 through one checked installer for NMDK CI, integration and release jobs; rejected older local versions with installation guidance.
- Updated plugin validation to the current production plugin name and replaced broken documentation references with canonical NMDK specification links.
- Aligned Hostr relay admission with the canonical seed event kind, including authentication regression coverage. Removed obsolete seed, NIP-04 and NWC notification permissions from policy and deployment defaults.
- Updated Signet to 1.20.0 with one shared daemon/dashboard Dockerfile and current pnpm configuration. Its frozen SQLite dependency requires the latest Node 24 LTS patch; Hostr's own Node packages remain on Node 26. Both images compile and pass isolated HTTP startup checks.
- Fixed cold Bitcoin startup by preserving the image's executable path and matching container ownership to host data directories. A fresh Bitcoin 31.1 regtest instance initialized both wallets, mined 151 blocks and funded the test client; failures now print service logs before cleanup.
- Applied the same host ownership to writable EVM stack services. Fresh CLN 26.06.6 and LND 0.21.3 instances both reached block 151 using user/group 1001; corrected the Bash timeout script and added ownership checks for both stack checkouts.
- Added authenticated relay admission for canonical order lifecycle events 32122–32127 and reused policy defaults in the server.
- Standardized Signet configuration, TLS certificates, seed scripts and integration helpers on `bunker.hostr.development`.
- Integrated pinned Cashu SAT/USD mints with canonical NMDK config/readiness helpers, correct Lightning endpoints and a separate invoice payer. Disposable mint/Redis/relay startup, config readiness, TLS and startup failure checks passed. The SAT startup smoke used FakeWallet; it did not exercise Lightning payment settlement.
- Replaced timing sleeps in the SDK zap test with subscription-completion signals. Thirty focused repetitions and all 768 SDK unit tests passed.
- Made the plugin checkout and Hostr submodule configuration track the published `main`; preserved the old unrelated local plugin history on a separate branch.
- Fixed the Dart environment generator to emit NMDK imports and extended the boundary guard to generator scripts and package tools. All four generated environments match the committed sources after formatting.
- Routed the generated Cashu payment command through the shared Hostr Compose configuration, preserving the selected local/test environment and its payer service.

The clean-checkout verification also covers Widgetbook's production web build, all seven packed TypeScript packages in a blank consumer, both documentation production builds, repeated Dart binding generation without tracked drift, and the Linux MCP container build and daemon startup smoke check. A fresh recursive GitHub clone retrieved all 37 submodules and matched the verified repository trees. Follow-up correctness commits retain their actual creation dates; the original 29 feature commits keep the requested schedule above.
