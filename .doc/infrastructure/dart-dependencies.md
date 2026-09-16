# Dart and Flutter dependency audit

Verified 2026-09-16 UTC against official pub.dev package metadata and the
[Flutter stable repository](https://github.com/flutter/flutter/releases/tag/3.47.4).
The latest stable SDK is **Flutter 3.47.4 / Dart 3.13.3**, revision
`9584c6713b324636289d067944a46fd6b49df14b`. Validation used the isolated
`/tmp/hostr-flutter-latest` installation; the globally installed SDK was untouched.
All seven projects require Dart `^3.13.0` and have refreshed dependency locks.

Every current direct dependency uses the latest published stable release except
Equatable, SQLite, and CLI QR, whose latest versions conflict with constraints
in other current upstream packages. The complete direct dependency inventory
below includes development dependencies. Path dependencies refer directly to
`marketplace_models`, `marketplace_evm`, and `hostr_sdk`; there is no `models`
compatibility package or NDK/Google Maps override.

## Upstream constraints and the single override

- NDK **0.9.3** requires `equatable ^2.0.8`, `elliptic ^0.3.12`, and `hooks ^1.0.0`.
  The resolved releases are Equatable **2.1.0**, Elliptic **0.3.12**, and Hooks
  **1.0.3**. SQLite **3.5.2** supports these hooks; newest SQLite **3.6.0**
  requires Hooks 2.2. This also constrains Code Assets **1.0.0**, Record Use
  **0.6.0**, Native Toolchain Rust **1.0.4**, and Native Toolchain C **0.18.0**.
- Latest ASCII QR **1.0.1** (via NDK) and QR Flutter **4.1.0** require QR 3.
  CLI therefore declares QR **3.0.2**, not newest QR 4.0.0.
- Latest BOLT11 Decoder **1.0.2** requires Decimal 2; resolved Decimal is **2.3.3**.
- Latest Chopper Generator **8.7.0** requires Analyzer `<14`. Generator projects
  resolve Analyzer **13.3.0**, shared analyzer **103.0.0**, and Source Gen **4.2.4**;
  pure model/CLI/service projects can resolve Analyzer 14.4.0.
- Flutter 3.47.4 pins Test API **0.7.12** and Material Color Utilities **0.13.0**.
  App tests resolve Test **1.31.1** / Test Core **0.6.18** / Package Config **2.2.0**;
  pure Dart projects use Test **1.32.0**. Flutter Launcher Icons **0.14.4**
  constrains CLI Util to **0.4.2**. Webcrypto **0.6.1** constrains Native Toolchain
  CMake to **0.2.7**. The app's complete resolved graph selects Path Provider
  Foundation **2.5.1**; `flutter pub outdated` reports it as the newest resolvable
  version for that graph (2.6.0 exists upstream).
- **PointyCastle 4.0.0 is the only dependency override.** Coinlib **5.0.0** declares
  PointyCastle 3, while Web3dart **3.0.3** and Wallet **0.0.18** require 4. Coinlib's
  only PointyCastle API use is `RIPEMD160Digest().process`, unchanged in 4. The
  canonical models suite verifies HASH160 and official BIP32/BIP340 vectors in
  `crypto_dependency_vectors_test.dart`; all three pass with Coinlib 5 + PC 4.

The published Web3dart Builders **3.0.1** still constrains Build 2, Dart Style 2,
and Wallet 0.0.17. It cannot coexist with the latest Swagger/Chopper generators.
The EVM package therefore declares a **direct Git dependency** on the maintained
[generator update](https://github.com/PatrickGeyer/web3dart_builders/commit/8622bd2cd434c6a6cad827265c52ec43457027f5),
exact revision `8622bd2cd434c6a6cad827265c52ec43457027f5`, rather than a global
generator override. It regenerates all six contract bindings successfully.

Unused direct dependencies were removed, including old terminal UI libraries in
the escrow service, unused app helpers, and the unused `ndk_bip32_keys` declaration.
NDK **0.9.3**, Google Maps Flutter **2.18.0**, and its web implementation **0.6.3+1**
now come from the registry instead of local or Git forks.

## Validation

Dependency resolution and full compatible lock upgrades succeeded for all seven
projects. Canonical model analysis and **126 tests** passed, including the new
cryptography vectors; driver analysis and **128 tests** passed. Regeneration using
Build Runner **2.16.1**, Swagger Generator **4.1.1**, Chopper **8.7.0**, and JSON
Serializable **6.14.1** succeeded, and the generated-source drift check passed.
These include current integer amount fixtures and 22 strict recovery/configuration
serialization regressions. Five SDK tests also verify the NDK 0.9.3 lazy NIP42
authentication lifecycle, socket reuse, identity changes, logout, and ephemeral
gift-wrap authors. Hostr application build and integration validation are tracked
separately in the payment-driver migration.

To refresh the audit, query `https://pub.dev/api/packages/<package>`, run
`dart pub upgrade` (or `flutter pub upgrade`), then `pub outdated --json` in each
project. Do not force transitive majors past upstream constraints merely to make
the outdated report empty.

## Direct dependency inventory

`=` means the resolved release is the current published stable release.
App, Widgetbook, SDK, CLI, Escrow, Models, and EVM identify the consuming projects.

| Dependency | Resolved | Latest | Projects |
| --- | --- | --- | --- |
| `app_links` | 7.2.1 | = | App |
| `args` | 2.7.0 | = | CLI |
| `auto_route` | 11.1.0 | = | App |
| `auto_route_generator` | 10.6.0 | = | App |
| `bech32` | 0.2.2 | = | App |
| `bip340` | 0.3.1 | = | SDK, Models |
| `bip39_mnemonic` | 4.1.0 | = | App, SDK |
| `bloc` | 9.2.1 | = | SDK, EVM |
| `bloc_test` | 10.0.0 | = | App |
| `blurhash_dart` | 1.2.1 | = | App |
| `bolt11_decoder` | 1.0.2 | = | App, Widgetbook, SDK, EVM |
| `build_runner` | 2.16.1 | = | App, Widgetbook, SDK, EVM |
| `carousel_slider` | 5.1.2 | = | App |
| `chopper` | 8.7.0 | = | SDK, EVM |
| `chopper_generator` | 8.7.0 | = | SDK, EVM |
| `coinlib` | 5.0.0 | = | SDK, Models |
| `coinlib_flutter` | 5.0.1 | = | App |
| `collection` | 1.19.1 | = | App, SDK, EVM |
| `convert` | 3.1.2 | = | App, SDK, Escrow, Models, EVM |
| `crypto` | 3.0.7 | = | App, SDK, CLI, Models, EVM |
| `cupertino_icons` | 1.0.9 | = | App |
| `date_count_down` | 4.0.0 | = | App |
| `eip712` | 1.0.1 | = | EVM |
| `equatable` | 2.1.0 | 3.0.0 | App, SDK |
| `eventide` | 2.4.0 | = | App |
| `faker` | 2.2.0 | = | Models |
| `flutter_bloc` | 9.1.1 | = | App |
| `flutter_launcher_icons` | 0.14.4 | = | App |
| `flutter_lints` | 6.0.0 | = | App, Widgetbook |
| `flutter_local_notifications` | 22.3.1 | = | App |
| `flutter_secure_storage` | 11.1.1 | = | App |
| `get_it` | 9.2.1 | = | App, SDK, Escrow |
| `google_maps_flutter` | 2.18.0 | = | App |
| `h3_dart` | 0.7.0 | = | Models |
| `h3_flutter` | 0.7.1 | = | App |
| `http` | 1.6.0 | = | App, SDK, EVM |
| `hydrated_bloc` | 11.0.0 | = | App, SDK, Escrow |
| `image` | 4.10.1 | = | App |
| `image_picker` | 1.2.3 | = | App |
| `image_picker_platform_interface` | 2.11.1 | = | App |
| `injectable` | 3.0.0 | = | App, SDK, EVM |
| `injectable_generator` | 3.1.3 | = | App, SDK |
| `intl` | 0.20.3 | = | App |
| `json_annotation` | 4.12.0 | = | SDK, EVM |
| `json_rpc_2` | 4.1.0 | = | Escrow |
| `json_serializable` | 6.14.1 | = | App, SDK, EVM |
| `lints` | 6.1.0 | = | SDK, CLI, EVM |
| `logger` | 2.8.0 | = | App, SDK, CLI, Escrow, Models, EVM |
| `logging` | 1.3.0 | = | EVM |
| `meta` | 1.19.0 | = | SDK, EVM |
| `mime` | 2.1.0 | = | CLI |
| `mobile_scanner` | 7.4.2 | = | App |
| `mockito` | 5.8.1 | = | App, Widgetbook, SDK |
| `mocktail` | 1.0.5 | = | App |
| `mocktail_image_network` | 1.3.0 | = | App |
| `ndk` | 0.9.3 | = | App, SDK, CLI, Escrow, Models, EVM |
| `opentelemetry` | 0.18.11 | = | EVM |
| `path` | 1.9.1 | = | CLI |
| `path_provider` | 2.1.6 | = | App |
| `permission_handler` | 13.0.2 | = | App |
| `permissionless` | 0.4.1 | = | EVM |
| `provider` | 6.1.5+1 | = | App |
| `qr` | 3.0.2 | 4.0.0 | CLI |
| `qr_flutter` | 4.1.0 | = | App |
| `rxdart` | 0.28.0 | = | App, Widgetbook, SDK, EVM |
| `scrollable_positioned_list` | 0.3.8 | = | App |
| `shared_preferences` | 2.5.5 | = | App |
| `shelf` | 1.4.2 | = | App, Widgetbook, SDK |
| `shelf_router` | 1.1.4 | = | App, Widgetbook, SDK |
| `sqlite3` | 3.5.2 | 3.6.0 | App, SDK, CLI, EVM |
| `stream_channel` | 2.1.4 | = | Escrow |
| `swagger_dart_code_generator` | 4.1.1 | = | SDK, EVM |
| `test` | 1.32.0 | = | SDK, CLI, Escrow, Models, EVM |
| `timeago` | 3.7.1 | = | App |
| `timelines_plus` | 2.0.1 | = | App |
| `toastification` | 3.2.0 | = | App |
| `url_launcher` | 6.3.2 | = | App |
| `wallet` | 0.0.18 | = | App, SDK, Escrow, EVM |
| `web` | 1.1.1 | = | App |
| `web3dart` | 3.0.3 | = | App, Widgetbook, SDK, Escrow, EVM |
| `web3dart_builders` | 3.0.1 (Git revision above) | 3.0.1 (incompatible published constraints) | EVM |
| `web_socket_channel` | 3.0.3 | = | EVM |
| `webcrypto` | 0.6.1 | = | App |
| `widgetbook` | 3.25.0 | = | Widgetbook |
| `widgetbook_annotation` | 3.11.0 | = | Widgetbook |
| `widgetbook_generator` | 3.24.0 | = | Widgetbook |
| `workmanager` | 0.10.10 | = | App |
