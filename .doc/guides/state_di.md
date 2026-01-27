# State and DI Guide

A quick decision helper for when to use GetIt singletons, global Bloc providers, feature cubits, or workflows in the Hostr app.

## Decision cheatsheet

- Multi-step orchestration that talks to multiple services → Workflow
- Shared service/client/cache with no UI state → Global singleton (GetIt)
- App-wide UI/session state that many screens read → Global cubit (top-level BlocProvider)
- Screen/feature-specific UI state → Feature cubit (route-level BlocProvider)

## Global singleton (GetIt)

Use for stateless or long-lived services that sit below UI concerns.

- Good fits: data sources (Nostr, LN, storage), domain services, repositories, HTTP/LN clients, relay connectors, caches, schedulers.
- Traits: pure Dart, no Widget imports, no direct user interaction, safe to reuse across routes.
- Provider: register once in [app/lib/injection.dart](app/lib/injection.dart); inject via constructors.
- Avoid: storing UI state, depending on cubits, reaching into BuildContext.

## Global cubit (BlocProvider at app root)

Use when UI-facing state must persist for the whole app session and be readable across many routes.

- Good fits: auth/session identity, app mode/env, wallet connectivity, globally cached streams (e.g., message stream cache), hydrated counts that improve UX.
- Traits: exposes UI-ready state, may hydrate, may subscribe to services, rarely depends on other cubits.
- Provider: set up in app root bootstrap; hydrate intentionally; keep side effects in services/workflows.
- Avoid: housing heavy orchestration; calling other cubits; holding references to feature cubits.

## Feature cubit (route/screen scope)

Use for screen or flow-specific UI state that can be disposed when the route ends.

- Good fits: form state, screen filters/sorts, one reservation flow, one swap flow, paging/selection state.
- Traits: thin logic, delegates IO and complex steps to services/workflows; created via route-level providers or factories.
- Avoid: holding global caches, cross-feature responsibilities, or long-lived streams better suited for services.

## Workflow

Use when an interaction is multi-step, touches multiple services, or needs progress/reporting.

- Good fits: auth/login/signup, reservation booking, swaps, LNURL flows, event publishing, multi-step payments.
- Traits: orchestrates service calls, sequences steps, maps errors, optionally drives cubits or returns a typed result; no widget imports.
- Provider: injectable class constructed via GetIt; invoked from cubits or UI; report progress with `ProgressSnapshot`.
- Avoid: storing long-lived UI state; emitting widgets; depending on BuildContext.

## Patterns to keep

- Cubit → Service/Workflow → Data source. Avoid Cubit → Cubit calls.
- Prefer constructor injection over runtime `GetIt` lookups inside widgets or cubits.
- Hydrate only when it improves UX; otherwise keep state transient.

For architectural background and examples, see [docs/architecture/ideal-architecture.md](docs/architecture/ideal-architecture.md).
