# Hostr App

Flutter application for peer‑to‑peer accommodation built on Nostr and Lightning.

## Architecture

- Routing: `auto_route` (see `lib/router.dart` and generated `router.gr.dart`)
- DI: `get_it` + `injectable` (see `lib/injection.dart` and `lib/injection.config.dart`)
- State: `flutter_bloc` + `hydrated_bloc` for persistence
- Data: `lib/data/**` (Nostr, NWC, APIs), generated clients in `swagger_generated/` and `*.g.dart`
- UI: `lib/presentation/**` (screens, widgets, themes)

### Standards (logic vs UI)

- Keep logic/testable code in `lib/logic/**` and `lib/data/**`; widgets should consume cubits/services via providers.
- Long-running work should emit `ProgressSnapshot` updates from `lib/logic/progress/progress.dart` so the UI can render progress consistently.
- Prefer constructor injection for cubits/services (pass dependencies to constructors; avoid GetIt lookups inside widgets).
- Add unit tests for cubits/managers in `test/logic/**`; see `test/logic/event_publisher_cubit_test.dart` for a pattern.

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

## Automation

- Screenshots: `./bin/generate_screenshots.sh` (set `DEVICE_ID=<device>` to override the target; defaults to macOS desktop). Outputs to `app/screenshots/`.
- Widgetbook/storybook: `./bin/generate_widgetbook.sh` (runs build_runner inside `widgetbook_workspace`).
- Tests: `flutter test` for unit/widget; integration screenshots live in `integration_test/screenshot.dart`.
- Icons (single source of truth = `assets/images/logo/logo.svg`):
  - Run `./bin/generate_icons.sh` to generate:
    - Canonical 1024px launcher source PNGs (main padded icon, Android adaptive foreground + monochrome, iOS dark/tinted variants)
    - Themed navbar icon assets without the lower wordmark text
  - Then run `dart run flutter_launcher_icons` to regenerate platform launcher icons.

## Notes

- Non‑prod environments allow self‑signed TLS via global `HttpOverrides` for local testing.
- Generated files (`*.g.dart`, `swagger_generated`) are excluded from analysis in `analysis_options.yaml`.

## Troubleshooting

- If injection errors occur, ensure codegen is up to date:
  - Run build_runner to regenerate `*.g.dart` and `injection.config.dart`.
- Check that mock services are running when using `mock` environment (see `lib/setup.dart`).
