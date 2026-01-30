# Hostr — AI Coding Agent Guide

This monorepo powers a peer‑to‑peer accommodation platform built on Nostr and Lightning. Use these notes to work productively across the Flutter app, escrow daemon, and local infrastructure.

## Big Picture

- **Monorepo layout:** [app](app) (Flutter client), [escrow](escrow) (Dart daemon + contracts), [infrastructure](infrastructure) (Terraform, GKE, DNS), plus local Docker stack in [docker-compose.yml](docker-compose.yml).
- **Data flow:** App publishes/reads Nostr events via a relay; media is served via Blossom; payments use LND/LNbits; the escrow daemon watches Nostr and Rootstock/EVM and coordinates settlement. See [app/README.md](app/README.md) and [README.md](README.md).
- **Local stack services:** Nostr Relay (`relay.hostr.development`), Blossom, `bitcoind` (regtest), `lnd1/2`, `lnbits1/2`, `albyhub1/2`, optional `evm`, `escrow`. Configs in [docker](docker) and [docker-compose.yml](docker-compose.yml).

## Developer Workflows

- **Start full local stack:** `./scripts/start_local.sh` → brings up Docker, waits healthy, seeds Nostr with mock events via [models/lib/stubs/seed.dart](models/lib/stubs/seed.dart), deploys Hardhat escrow contract, starts the Dart escrow CLI, then the container.
  - Channel setup and LNbits bootstrap: [scripts/setup_local.sh](scripts/setup_local.sh), [scripts/aliases.sh](scripts/aliases.sh), [scripts/setup_lnbits.sh](scripts/setup_lnbits.sh).
- **Alternative stack (Boltz):** `./scripts/start.sh` → starts Boltz bundle under `docker/boltz`, then `docker-compose up`.
- **Wait for health:** `./scripts/wait_for_healthy.sh` is used by scripts to block until services report healthy.
- **Run the app:** choose the environment entrypoint in [app/lib/main_development.dart](app/lib/main_development.dart), [app/lib/main_staging.dart](app/lib/main_staging.dart), [app/lib/main_production.dart](app/lib/main_production.dart), or [app/lib/main_mock.dart](app/lib/main_mock.dart). Each calls `setup(env)` from [app/lib/setup.dart](app/lib/setup.dart).
- **Tests:** in [app/test](app/test). Run `cd app && flutter test`. See pattern in [app/test/logic/event_publisher_cubit_test.dart](app/test/logic/event_publisher_cubit_test.dart).
- **Codegen:** `cd app && flutter pub run build_runner build --delete-conflicting-outputs` for `injection.config.dart`, `router.gr.dart`, `*.g.dart`. Generated files are excluded in [app/analysis_options.yaml](app/analysis_options.yaml).
- **Screenshots & widgetbook:** `app/bin/generate_screenshots.sh` and `app/bin/generate_widgetbook.sh`; outputs to [app/screenshots](app/screenshots) and `app/widgetbook_workspace`.

## App Architecture & Conventions

- **Routing:** `auto_route` → see [app/lib/router.dart](app/lib/router.dart) and generated `router.gr.dart`.
- **DI:** `get_it` + `injectable` → bootstrap in [app/lib/injection.dart](app/lib/injection.dart); avoid direct `GetIt` lookups inside widgets; prefer constructor injection for `Cubit`/services.
- **State:** `flutter_bloc` + `hydrated_bloc` → persist selected cubit state; storage set in `setup(env)` in [app/lib/setup.dart](app/lib/setup.dart).
- **Progress reporting:** Use `ProgressSnapshot` from [app/lib/logic/progress/progress.dart](app/lib/logic/progress/progress.dart) with a stable `operation` name and `inProgress/success/failure` transitions. Example in [app/lib/logic/cubit/event_publisher.cubit.dart](app/lib/logic/cubit/event_publisher.cubit.dart) and its tests.
- **Separation:** Place testable logic in `lib/logic/**` and `lib/data/**`; UI in `lib/presentation/**` consuming cubits/services via providers.
- **Environments:** `Env.mock/dev/test/staging/prod` constants in [app/lib/injection.dart](app/lib/injection.dart). Non‑prod enables permissive TLS (`Dio` + `HttpOverrides`) in [app/lib/setup.dart](app/lib/setup.dart).

## Nostr & External Integrations

- **Nostr service:** Contract in [app/lib/data/sources/nostr/nostr/nostr.service.dart](app/lib/data/sources/nostr/nostr/nostr.service.dart) (`broadcast`, `subscribe`, `count`, `trustedEscrows`). Implementation composes `getIt<Ndk>`.
- **Relays:** Connect via the injected `RelayConnector` in `setup(env)`; don’t instantiate `Ndk` directly in UI code.
- **Media:** Blossom server is exposed at `blossom.hostr.development` in Docker; mock server runs in `mock/test` via [app/lib/data/sources/nostr/mock.blossom.dart](app/lib/data/sources/nostr/mock.blossom.dart).
- **Payments:** Local LND and LNbits are provisioned by scripts; LNbits admin and `lnurlp` extension are configured via [setup_lnbits.sh](setup_lnbits.sh).
- **Escrow:** Hardhat deploys contracts in [escrow/contracts](escrow/contracts); the Dart escrow client/CLI lives in [escrow](escrow) and is started by `start_local.sh`. Container receives `CONTRACT_ADDR` via environment when re‑`docker-compose up`.

## Practical Examples

- **Publish events with progress:** Follow [app/lib/logic/cubit/event_publisher.cubit.dart](app/lib/logic/cubit/event_publisher.cubit.dart) emitting `inProgress` with `fraction` and context, then `success/failure`. Test with `bloc_test` and `mockito` as in [app/test/logic/event_publisher_cubit_test.dart](app/test/logic/event_publisher_cubit_test.dart).
- **Query counts:** Use `NostrService.count(filters: [...])` instead of ad‑hoc querying; respects DI and relay settings.
- **Trusted escrows:** Read via `NostrService.trustedEscrows()` (NIP‑51 list kind).

## Commands (copy/paste)

- Local stack:
  ```bash
  ./scripts/start_local.sh
  ```
- Alternative stack (Boltz):
  ```bash
  ./scripts/start.sh
  ```
- App tests & codegen:
  ```bash
  cd app
  flutter test
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- Seed relay manually:
  ```bash
  (cd models && dart run lib/stubs/seed.dart ws://relay.hostr.development)
  ```
- Deploy contracts:
  ```bash
  (cd escrow/contracts && npx hardhat ignition deploy ./ignition/modules/Escrow.ts --network localhost)
  ```

If any section is unclear or missing details you rely on, tell me what you want to do next and I’ll refine these instructions.
