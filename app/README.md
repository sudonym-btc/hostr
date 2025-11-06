# Hostr App

Flutter application for peer‑to‑peer accommodation built on Nostr and Lightning.

## Architecture

- Routing: `auto_route` (see `lib/router.dart` and generated `router.gr.dart`)
- DI: `get_it` + `injectable` (see `lib/injection.dart` and `lib/injection.config.dart`)
- State: `flutter_bloc` + `hydrated_bloc` for persistence
- Data: `lib/data/**` (Nostr, NWC, APIs), generated clients in `swagger_generated/` and `*.g.dart`
- UI: `lib/presentation/**` (screens, widgets, themes)

## Environments

- `main_development.dart` → dev
- `main_staging.dart` → staging
- `main_production.dart` → prod
- `main_mock.dart` / tests → mock/test

See `lib/setup.dart` for environment bootstrapping and mock servers.

## Run

- Dev: use `main_development.dart`
- Prod: use `main_production.dart`

From VS Code, choose the corresponding launch/entrypoint; from CLI, select the file as the `-t` target.

## Notes

- Non‑prod environments allow self‑signed TLS via `Dio` and global `HttpOverrides` for local testing.
- Generated files (`*.g.dart`, `swagger_generated`) are excluded from analysis in `analysis_options.yaml`.

## Troubleshooting

- If injection errors occur, ensure codegen is up to date:
  - Run build_runner to regenerate `*.g.dart` and `injection.config.dart`.
- Check that mock services are running when using `mock` environment (see `lib/setup.dart`).
