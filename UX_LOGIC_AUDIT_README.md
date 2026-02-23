# Hostr App Audit (Visual + Logic)

Date: 2026-02-23
Scope: `app/lib/presentation/**`, key app cubits, and `hostr_sdk/lib/**` usecases/streams/payments/seeding.

This document is intentionally **findings-only** and **plan-only** (no code changes yet).

---

## Visual

## 1) Spacing system audit

### Findings

- Spacing primitives are inconsistent across the UI:
  - `SizedBox(...)` used heavily in presentation (many raw literals like `4`, `6`, `8`, `10`, `12`, `15`, `16`, `24`, `40`).
  - `CustomPadding` exists and already ties to `kDefaultPadding`, but is not consistently used.
  - `Spacer()` is used very little relative to manual fixed-width/fixed-height spacing.
- Practical impact:
  - Visual rhythm changes between screens/components.
  - Harder to refactor density for compact/large form factors.
  - Increased cognitive noise from micro-inconsistencies.

### Principle to adopt

Use a single spacing scale derived from `kDefaultPadding`:

- Example token map (recommended):
  - `spaceXs = kDefaultPadding / 8`
  - `spaceSm = kDefaultPadding / 4`
  - `spaceMd = kDefaultPadding / 2`
  - `spaceLg = kDefaultPadding`
  - `spaceXl = kDefaultPadding * 1.5`
- Introduce 2 reusable widgets:
  - `AppGap.h(multiplier)` / `AppGap.w(multiplier)`
  - `DefaultSpacer(multiplier)` for flex layouts where proportional growth is desired.

### Priority hotspots

- Listing/detail and profile widgets with many literal `SizedBox` values.
- Payment flows and modal content where spacing currently mixes multiple scales.

---

## 2) Typography audit

### Findings

- There are only a small number of explicit `fontSize:` overrides, but they are not tokenized.
- Most text is theme-driven (good), but explicit overrides remain in profile/payment/reservation/search marker areas.

### Best principle for font sizes

- Keep a **small typographic set** to reduce cognitive load:
  - Display (rare)
  - Title
  - Body
  - Label/Caption
- In Flutter: prefer `ThemeData.textTheme` everywhere.
- Avoid ad-hoc `TextStyle(fontSize: X)` unless the style is first registered as an app token/semantic style.

### Recommended target

- 90%+ of app text should use `textTheme` semantic roles.
- Explicit size overrides only for exceptional UI (e.g., map marker rendering internals).

---

## 3) Icons, icon buttons, bitmap pills

### Findings

- Icon sizes are inconsistent (`12`, `14`, `16`, `18`, `20`, `30`, `48`, etc.) and not tokenized.
- Icon button usage is mixed (sometimes icon-only where textual affordance would be clearer).
- Price marker pills are custom-rendered and generally good, but text/icon sizing should align to typography tokens.

### Principles

- Tokenize icon sizes: e.g. `iconSm`, `iconMd`, `iconLg`, `iconXl`.
- Use icon-only buttons only when intent is universally obvious (close, copy, back, overflow).
- Use icon+label for actions with consequence/ambiguity (fund, swap, escrow actions).

---

## 4) Button hierarchy

### Findings

- Multiple button types are used (`FilledButton`, `ElevatedButton`, `OutlinedButton`, `TextButton`, `IconButton`) with inconsistent semantics.
- Some equivalent actions use different variants across screens.

### Recommended hierarchy

- **Primary**: `FilledButton` (one per area/modal).
- **Secondary**: `OutlinedButton` or `FilledButton.tonal`.
- **Tertiary**: `TextButton`.
- **IconButton**: utility actions only.

Define usage rules in a small design contract and enforce via component wrappers.

---

## 5) Animation consistency

### Findings

- Global animation constants exist (`kAnimationDuration`, `kAnimationCurve`, `kStaggerDelay`) which is excellent.
- Several widgets still use literal durations (`200ms`, `400ms`, `1s`, `1.5s`, `2s`, etc.).

### Principle

- One shared motion system:
  - Enter/exit duration
  - Emphasis duration
  - Debounce duration tokens
  - Shared curves
- Any literal duration should be justified by domain behavior (polling/network timeout) not visual preference.

---

## 6) Modal style consistency

### Findings

- You already have a reusable `ModalBottomSheet` component (strong foundation).
- Many call-sites still directly invoke bottom sheets/dialogs with varying style density.

### Principle

- Route all modal content through one modal shell component.
- Keep title/subtitle/body/button zones identical across flows.

---

## 7) Perceived performance (preload + placeholders)

### Findings

- You already preload listing images (`ImagePreloader`, `PreloadListingImages`) — this is good.
- Some image states still use generic placeholders/progress indicators causing layout and perceived-jank differences.
- Filter screen and some bottom sheets are built only on click; this can feel delayed when dependency graph is heavy.

### Good practice guidance

- Preload expensive screens only when:
  - high-open-frequency,
  - high-build-cost,
  - no stale-data risk.
- Use skeleton/fixed-size placeholders to prevent resizing jumps.
- Keep dimensions stable during loading (especially media cards and carousels).

---

## 8) Translation/i18n

### Findings

- Localization support is present and used in many places.
- There are still many hardcoded English strings in presentation and widget files.

### Principle

- User-visible strings must go through localization layer.
- Reserve inline literals for temporary debug/dev surfaces only.

---

## Visual execution plan

### Phase V1 — Design tokens + wrappers

1. Add spacing/icon/typography/motion tokens in one source of truth.
2. Add wrapper components (`AppGap`, `AppButton`, `AppModal`, icon size helpers).
3. Document usage rules (short markdown spec).

### Phase V2 — Bulk refactor (safe mechanical)

1. Replace raw `SizedBox` literals with spacing tokens/wrappers.
2. Replace ad-hoc `fontSize` with textTheme semantics.
3. Normalize icon sizes and button variants.

### Phase V3 — Motion + modal normalization

1. Replace visual literal durations with motion tokens.
2. Move bottom-sheet/dialog call sites to shared modal shell.

### Phase V4 — UX polish/perf

1. Add skeleton placeholders with fixed dimensions.
2. Pre-warm high-frequency entry screens (filters/payment chooser) where warranted.
3. Validate in Widgetbook + integration screenshots.

### Visual acceptance criteria

- No raw visual spacing literals outside approved token helpers.
- No ad-hoc font sizes outside tokenized typography styles.
- All modal flows share same shell and button hierarchy.
- Consistent animation timing across presentation layer.

---

## Logic

## 1) High-load hotspots across app + sdk

### Findings

- Potential heavy fan-out from per-item subscriptions in listing-related widgets.
- Search map marker updates rebuild markers asynchronously and can churn under rapid list updates.
- `Requests.count()` currently materializes full query results and counts in memory (can be expensive).
- Some thread/message rebuild paths can become O(n^2)-ish for larger datasets.

### Recommendation

- Move toward aggregate/list-level subscriptions instead of per-item network subscriptions.
- Use batched updates and incremental diffing for maps/lists.
- Prefer protocol/server count mechanisms where available; avoid `toList().length` for large streams.

---

## 2) Stream lifecycle + listener cleanup

### Findings

- Many areas correctly cancel subscriptions on `dispose/close`.
- However lifecycle policy is mixed (manual lists in some modules, `takeUntil` + dispose subject in others).
- `CrudUseCase` owns a broadcast `_updates` controller but has no explicit dispose contract.

### Best practice recommendation

- Standardize to one pattern per layer:
  - UI/cubits: maintain explicit subscription registry + deterministic `close`/`dispose`.
  - Reactive pipelines: `takeUntil(_dispose$)` for derived streams.
- Every long-lived service with controllers/subjects should expose and be called with `dispose()`.
- Add leak tests for critical long-lived services.

---

## 3) Usecase correctness (CRUD/request batching/caching)

### Findings

- `CrudUseCase` batching for `getOne` and `findByTag` is a strong pattern.
- In-flight query dedup exists in `Requests` (good).
- Potential correctness/perf pitfalls remain in edge cases:
  - fallback fan-out queries after unmatched batch requests,
  - broad filters causing high relay load,
  - non-uniform caching toggles.

### Recommendation

- Introduce explicit query policy per usecase:
  - cache strategy,
  - timeout strategy,
  - retry policy,
  - dedupe key policy.
- Add metrics counters for batched requests, fallback rate, and duplicate subscriptions.

---

## 4) Error handling (EntityCubit, payments/swaps, parser)

### Findings

- Error states exist but are mostly untyped/stringly in several paths.
- Payment/swap failures are surfaced but user messaging is not consistently actionable.
- Nostr parser currently throws on malformed event parse path; one bad event can poison a stream path if not isolated.

### Recommendation

- Adopt typed domain failures (network/validation/protocol/auth/retryable/non-retryable).
- Add user-safe mapping layer from domain failures to UX copy + recovery action.
- Parser strategy:
  - never crash broad stream on one malformed event,
  - emit parse failure telemetry,
  - quarantine invalid event and continue.

---

## 5) Nostr protocol future-proofing (immutability + migrations)

### Findings

- Since Nostr events are signed/immutable, schema mistakes are costly.

### Best-practice strategy

- Yes: add explicit protocol versioning in tags/content for your custom kinds.
- Prefer additive evolution (new fields optional) before breaking changes.
- On breaking changes:
  - support dual read (`vN` + `vN+1`) for a migration window,
  - write only latest version once app is upgraded,
  - optionally publish newly signed migrated events when user key is available.
- Keep parser backward compatible and tolerant to unknown fields.

---

## 6) Test architecture: fake relay vs real local stack

### Recommended strategy

Use a layered test pyramid:

1. **Fast deterministic unit tests** with fake request transport (no relay).
2. **Contract/integration tests** with mock relay semantics (wipable state between tests).
3. **End-to-end smoke tests** against real local relay + anvil.

Each tier should share scenario fixtures and setup/teardown primitives.

---

## 7) Seed builder extensions for repeatable scenarios

### Findings

- Seed pipeline and `TestSeedHelper` already provide a good foundation.

### Recommended extension set

- Scenario DSL for explicit actor states:
  - user/listings/reservations/messages/payments/escrow statuses.
- Deterministic IDs and named fixtures per scenario.
- Snapshot seed packs for “open this exact page in exact state”.
- Shared setup/teardown API used by widget tests, integration tests, and screenshot runs.

---

## 8) Widgetbook/page targeting + screenshot automation

### For specific page + specific seed data

- Yes, you can run app-level integration tests that:
  - bootstrap deterministic seed scenario,
  - deep-link directly to target route,
  - wait for settled state,
  - capture screenshot.

### For app-store screenshot pipeline

- Add dedicated screenshot scenario suite with stable mock/network assets.
- Generate named outputs per device/locale/theme.
- Make CI artifact upload + review part of PR workflow.

---

## Logic execution plan

### Phase L1 — Observability + contracts

1. Define typed failure model and error mapping matrix.
2. Add instrumentation for subscription counts, batch hit rate, fallback rate, parse failures.
3. Add lifecycle ownership map for long-lived streams/controllers.

### Phase L2 — Reliability hardening

1. Standardize stream disposal pattern per layer.
2. Add malformed-event tolerance in parser pipeline.
3. Add actionable error UX for Entity/Payment/Swap flows.

### Phase L3 — Performance and protocol hardening

1. Reduce per-item subscription fan-out where possible.
2. Optimize query/count paths and map/list churn.
3. Introduce explicit event versioning policy + migration playbook.

### Phase L4 — Testing + screenshots

1. Build reusable scenario fixtures on top of seed pipeline.
2. Split test suites by fake/mock/real tiers.
3. Add deterministic screenshot runner + CI artifacts.

### Logic acceptance criteria

- No known long-lived subscription leaks in smoke lifecycle tests.
- Parse failures are isolated and observable, not app-fatal.
- Payment/swap/domain errors map to clear user recovery actions.
- Deterministic scenario seeds can reproduce target pages for tests/screenshots.

---

## Suggested rollout order (combined)

1. Token foundations (visual) + failure taxonomy (logic).
2. Mechanical UI consistency refactor + parser/lifecycle hardening.
3. Seed scenario DSL + screenshot CI.
4. Protocol versioning rollout + migration tooling.

---

## Notes

- This report intentionally avoids direct code edits.
- Next step can be an implementation PR plan with concrete file-by-file changes and staged commits.
