# Hostr App — Visual & Logic Audit

> Full audit of the Hostr Flutter app, hostr_sdk, and models layer.
> Date: 2026-02-23. **No code changes — findings and execution plan only.**

---

# Table of Contents

- [Part A — Visual](#part-a--visual)
  - [V1. Spacing & Padding](#v1-spacing--padding)
  - [V2. Typography & Font Sizes](#v2-typography--font-sizes)
  - [V3. Buttons — Types, Roles, Icons](#v3-buttons--types-roles-icons)
  - [V4. Icon Sizes](#v4-icon-sizes)
  - [V5. Animations](#v5-animations)
  - [V6. Modals & Bottom Sheets](#v6-modals--bottom-sheets)
  - [V7. Image Loading & Placeholders](#v7-image-loading--placeholders)
  - [V8. Loading Indicators](#v8-loading-indicators)
  - [V9. Translations / l10n](#v9-translations--l10n)
- [Part B — Logic](#part-b--logic)
  - [L1. Error Handling](#l1-error-handling)
  - [L2. Stream & Listener Lifecycle](#l2-stream--listener-lifecycle)
  - [L3. Caching, Batching & Use Cases](#l3-caching-batching--use-cases)
  - [L4. Load & Performance Hotspots](#l4-load--performance-hotspots)
  - [L5. Nostr Protocol Future-Proofing](#l5-nostr-protocol-future-proofing)
  - [L6. Test Infrastructure & Automation](#l6-test-infrastructure--automation)
- [Execution Plan](#execution-plan)

---

# Part A — Visual

## V1. Spacing & Padding

### Current State

A `kDefaultPadding = 32` constant exists in `app/lib/config/constants.dart`, and a `CustomPadding` widget wraps `Padding` with multipliers of `kDefaultPadding`. This is a good foundation, but **~75% of spacing in the app bypasses it**.

**SizedBox hardcoded values found across presentation files:**

| Value (px) | Approx. uses | Equivalent `kDefaultPadding` fraction |
| :--------: | :----------: | :-----------------------------------: |
|     4      |     ~12      |                  1/8                  |
|     6      |      ~5      |        _(non-standard — 3/16)_        |
|     8      |     ~20      |                  1/4                  |
|     10     |      ~3      |        _(non-standard — 5/16)_        |
|     12     |      ~8      |                  3/8                  |
|     15     |      1       |           _(non-standard)_            |
|     16     |     ~18      |                  1/2                  |
|     24     |      ~9      |                  3/4                  |
|     32     |      ~1      |                  1×                   |
|     40     |      ~1      |                  5/4                  |

That's **10 distinct spacing values**, of which 3 (6, 10, 15) don't align to any clean fraction of the base grid.

Raw `EdgeInsets` with hardcoded values appear ~65 times across the presentation layer, duplicating values that `CustomPadding` already provides (e.g. `EdgeInsets.symmetric(horizontal: 32)` literally equals `kDefaultPadding`).

### Recommendation

Adopt a **4px base grid** spacing scale (industry standard, used by Material 3):

```
kSpace0  =  0
kSpace1  =  4   (kDefaultPadding / 8)
kSpace2  =  8   (kDefaultPadding / 4)
kSpace3  = 12   (kDefaultPadding * 3/8)
kSpace4  = 16   (kDefaultPadding / 2)
kSpace5  = 24   (kDefaultPadding * 3/4)
kSpace6  = 32   (kDefaultPadding)
kSpace7  = 48   (kDefaultPadding * 1.5)
kSpace8  = 64   (kDefaultPadding * 2)
```

Create a `Spacer` (or `Gap`) widget:

```dart
class Gap extends StatelessWidget {
  final double size;
  const Gap(this.size, {super.key});
  const Gap.xs({super.key}) : size = kSpace1;   //  4
  const Gap.sm({super.key}) : size = kSpace2;   //  8
  const Gap.md({super.key}) : size = kSpace4;   // 16
  const Gap.lg({super.key}) : size = kSpace6;   // 32
  const Gap.xl({super.key}) : size = kSpace7;   // 48

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}
```

Then replace all `SizedBox(height: 16)` with `Gap.md()`, etc. This eliminates magic numbers and makes spacing auditable via search.

### Files to Change (top offenders)

- `presentation/component/widgets/reservation/trade_header.dart` — 8+ SizedBoxes
- `presentation/component/widgets/flow/payment/payment.dart` — 6+ SizedBoxes
- `presentation/component/widgets/inbox/thread/thread_header.dart` — 5+ SizedBoxes
- `presentation/component/widgets/listing/listing_list_item.dart` — 4 SizedBoxes
- `presentation/screens/shared/listing/listing_view.dart` — mixed SizedBox + EdgeInsets
- `presentation/screens/shared/profile/` — multiple files

---

## V2. Typography & Font Sizes

### Current State

The app uses Flutter's `textTheme` tokens in **most** places (good), but 7 distinct hardcoded `fontSize` values leak through:

| Hardcoded size | Files                                                                              | Should be                             |
| :------------: | ---------------------------------------------------------------------------------- | ------------------------------------- |
|       11       | `trade_header.dart`                                                                | `labelSmall` (11)                     |
|       12       | `trade_header.dart`, `listing_list_item.dart`, `price_tag.dart`, `inbox_item.dart` | `bodySmall` (12)                      |
|       14       | `trade_header.dart`                                                                | `bodyMedium` (14)                     |
|       16       | `trade_header.dart`                                                                | `bodyLarge` (16) or `titleSmall` (14) |
|       20       | `price.dart`                                                                       | `titleLarge` (22)                     |
|       24       | `review_list_item.dart` (star icon context)                                        | `headlineSmall` (24)                  |
|       28       | `price_marker.dart`                                                                | `headlineMedium` (28)                 |

### Best Practice — Type Scale

Material 3 defines exactly 15 text styles in 5 roles × 3 sizes. For a mobile accommodation app, you realistically need **5–7 distinct sizes** to minimize cognitive load:

| Role         | Token           | Typical size | Use in Hostr                         |
| ------------ | --------------- | :----------: | ------------------------------------ |
| **Display**  | `displayMedium` |      45      | Splash screen, hero numbers          |
| **Headline** | `headlineSmall` |      24      | Section headers on detail pages      |
| **Title**    | `titleLarge`    |      22      | Screen/section titles, form labels   |
| **Title**    | `titleMedium`   |      16      | Card titles, list item primary text  |
| **Body**     | `bodyMedium`    |      14      | Descriptions, message text           |
| **Body**     | `bodySmall`     |      12      | Captions, timestamps, secondary info |
| **Label**    | `labelSmall`    |      11      | Badges, chips, minimal annotations   |

**Rule:** Never use a raw `fontSize:` in widget code. Always use `Theme.of(context).textTheme.bodySmall` (with optional `.copyWith(fontWeight: ...)` for emphasis). This keeps the scale consistent and lets theme changes propagate everywhere.

### Files to Change

- `presentation/component/widgets/reservation/trade_header.dart` — **worst offender**, 5 hardcoded sizes (11, 12, 14, 16)
- `presentation/component/widgets/listing/price_tag.dart` — hardcoded 12
- `presentation/component/widgets/listing/price.dart` — hardcoded 20
- `presentation/component/widgets/search/price_marker.dart` — hardcoded 28
- `presentation/component/widgets/listing/listing_list_item.dart` — hardcoded 12

---

## V3. Buttons — Types, Roles, Icons

### Current State

Four button types are used across the app:

| Type                                | Count | Primary use                      |
| ----------------------------------- | :---: | -------------------------------- |
| `FilledButton` / `.tonal` / `.icon` |  ~32  | CTAs, confirmations              |
| `ElevatedButton`                    |  ~7   | Swap flows, some CTAs            |
| `TextButton`                        |  ~8   | Cancel, clear, secondary actions |
| `OutlinedButton`                    |  ~2   | Tertiary/toggles                 |
| `IconButton`                        |  ~10  | Navigation, copy, close          |

**Problem:** `ElevatedButton` and `FilledButton` are used interchangeably for primary CTAs. The swap flow screens (`swap_in.dart`, `swap_out.dart`) and `dev.dart` use `ElevatedButton`, while everything else uses `FilledButton`. This creates a visual inconsistency — `ElevatedButton` has elevation/shadow, `FilledButton` is flat.

### Best Practice — Button Hierarchy

| Role            | Widget                                 | When to use                                                | Icon?                                                  |
| --------------- | -------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------ |
| **Primary CTA** | `FilledButton`                         | One per screen max. The main action (Pay, Reserve, Submit) | Only if icon adds clarity (e.g. send ✈, not generic ✓) |
| **Secondary**   | `FilledButton.tonal`                   | Supporting actions (Use Escrow, Edit)                      | Optional                                               |
| **Tertiary**    | `TextButton`                           | Cancel, Clear, Skip — low-commitment actions               | Rarely                                                 |
| **Destructive** | `FilledButton` + red `backgroundColor` | Delete, Refund, Block                                      | Icon for emphasis (⚠)                                  |
| **Icon-only**   | `IconButton`                           | Toolbar actions, close, copy, navigation                   | Always                                                 |

**When to use icons on buttons:**

- ✅ When the action has a universally recognized symbol (copy 📋, send ✈, close ✕)
- ✅ When used alongside other icon-only buttons in a row (toolbar)
- ❌ When the button already has clear text ("Pay" doesn't need a 💰 icon)
- ❌ When the icon is decorative rather than communicative

### Action Items

1. Replace all `ElevatedButton` with `FilledButton` across `swap_in.dart`, `swap_out.dart`, `dev.dart`
2. Define button presets in theme (or a `AppButton` wrapper) so primary/secondary/destructive styling is centralized
3. Audit icon usage on `FilledButton.icon` — ensure icons are communicative, not decorative

---

## V4. Icon Sizes

### Current State

**10 distinct icon sizes** are hardcoded across the app:

| Size | Where                 | Role                 |
| :--: | --------------------- | -------------------- |
|  12  | Copy icon, comment    | Detail actions       |
|  14  | Key icon, chips       | Inline indicators    |
|  16  | 6+ files              | Default small icons  |
|  18  | Amount input          | Field icons          |
|  20  | Multiple              | Standard interactive |
|  30  | Search nav            | Navigation           |
|  32  | Detail view           | Section icons        |
|  40  | CircleAvatar fallback | Profile              |
|  48  | Error icons           | Status               |
|  80  | Verified badge detail | Hero icon            |

The same icon (`Icons.copy`) appears at sizes 12, 16, and 18 in different files.

### Recommendation

Define an icon size scale mirroring the spacing scale:

```dart
const kIconXs  = 14.0;  // Chips, inline labels
const kIconSm  = 16.0;  // List item trailing, copy actions
const kIconMd  = 20.0;  // Standard interactive icons
const kIconLg  = 24.0;  // Navigation bar, section headers (Material default)
const kIconXl  = 32.0;  // Empty states, feature icons
const kIconHero = 48.0; // Error/success status, onboarding
```

Standardize: all copy icons → `kIconSm`, all nav icons → `kIconLg`, etc.

---

## V5. Animations

### Current State

Animation constants are well-defined in `config/constants.dart`:

```dart
const kAnimationDuration = Duration(milliseconds: 300);
const kAnimationCurve = Curves.easeInOut;
const kStaggerDelay = Duration(milliseconds: 60);
```

The `AnimatedListItem` widget correctly defaults to these. Most `AnimatedSwitcher` usages reference `kAnimationDuration`.

**Deviations:**

| File                          | Duration              | Curve                            | Issue                        |
| ----------------------------- | --------------------- | -------------------------------- | ---------------------------- |
| `listing_carousel.dart`       | `300ms` _(hardcoded)_ | `Curves.easeInOut` _(hardcoded)_ | Should reference constants   |
| `money_in_flight.dart`        | `400ms`               | `Curves.easeInOut`               | Non-standard duration        |
| `trade_timeline.dart`         | `200ms`               | `Curves.easeOut`                 | Different curve              |
| `trade_header.dart` (shimmer) | `1500ms`              | —                                | Correct for shimmer          |
| `search_box.dart`             | `1000ms`              | —                                | Debounce, not animation (OK) |

### Recommendation

1. Replace hardcoded `Duration(milliseconds: 300)` in `listing_carousel.dart` with `kAnimationDuration`
2. Decide: is `400ms` intentional for `money_in_flight.dart`? If not, use `kAnimationDuration`. If yes, define `kAnimationDurationSlow = Duration(milliseconds: 400)`
3. Consider adding `kAnimationDurationFast = Duration(milliseconds: 150)` for micro-interactions (button press feedback, chip toggles)
4. Standardize on one curve family. `easeInOut` is correct for most transitions. `easeOut` is appropriate for elements entering the screen (quick start, gentle stop)

### Preloading & Perceived Performance

**Can filter screens be preloaded?** Yes — create the filter bottom sheet widget eagerly in the parent and show/hide it rather than constructing on tap. The `SearchFilterCubit` state should already be warm. In practice, if the bottom sheet construction is < 16ms (one frame), preloading isn't necessary. Profile first with DevTools timeline.

**Preloading images / placeholders:**

- Currently `BlossomImage` shows `CircularProgressIndicator` while loading and Flutter's `Placeholder()` (a colored cross) on error — both are jarring
- Add `FadeInImage`-style crossfade from a shimmer/skeleton placeholder to the loaded image
- Consider adding `precacheImage()` calls for above-the-fold listing images when the list screen initializes
- Implement `CachedNetworkImage` (or equivalent) to avoid re-downloading on every screen revisit

---

## V6. Modals & Bottom Sheets

### Current State

15 `showModalBottomSheet` callsites exist. A `ModalBottomSheet` wrapper widget provides consistent internal layout. But:

| Issue                                                                | Affected files                                              |
| -------------------------------------------------------------------- | ----------------------------------------------------------- |
| `isScrollControlled` inconsistently set                              | 7 of 15 don't set it                                        |
| `useSafeArea` only set in 1 of 15 callsites                          | All except `listing_view.dart`                              |
| Several callsites bypass `ModalBottomSheet` and build custom layouts | `listing_view.dart`, `trade_header.dart`, `search_box.dart` |
| No shared `showAppModalBottomSheet()` helper                         | Each callsite configures independently                      |

### Recommendation

Create a single entry point:

```dart
Future<T?> showAppModal<T>(BuildContext context, {
  required Widget child,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  bool isDismissible = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  useSafeArea: useSafeArea,
  isDismissible: isDismissible,
  builder: (_) => child,
);
```

Then replace all 15 callsites. This ensures consistent `isScrollControlled` and `useSafeArea` defaults.

---

## V7. Image Loading & Placeholders

### Current State

- `BlossomImage` is the standard image widget — resolves SHA-256 hashes via Blossom server, falls back to `Image.network`
- **No disk caching** — no `CachedNetworkImage` or equivalent anywhere in the codebase
- Error state shows Flutter's `Placeholder()` widget (a colored diagonal cross) — not production-ready
- Loading state shows a raw `CircularProgressIndicator`
- Some files bypass `BlossomImage` and use raw `Image.network` (relay favicons, badge images)

### Recommendation

1. **Add `cached_network_image` package** — provides disk + memory caching, placeholder builders, and error builders out of the box
2. **Replace `Placeholder()` with a branded error widget** — e.g. a subtle grey rectangle with a broken-image icon
3. **Replace loading `CircularProgressIndicator` with a shimmer skeleton** matching the image's aspect ratio. This prevents layout shift when images load.
4. **Wrap `BlossomImage` to use caching internally** — so every `BlossomImage` benefits without changing callsites
5. **Precache hero images** — call `precacheImage()` for the first N listing images visible on the home/search screen

---

## V8. Loading Indicators

### Current State

27 `CircularProgressIndicator` instances across the app with **4 different `strokeWidth` values** (default ~4.0, 4, 2, 1.5). Additionally:

- Some use `.adaptive()`, others don't
- A custom `AsymptoticProgressBar` exists (nice!) but is used in only one place
- A private `_ShimmerSurface` in `trade_header.dart` is not reusable

### Recommendation

1. Create a shared `AppLoadingIndicator` widget with size presets:
   - `.small()` — `strokeWidth: 2`, 16x16, for inline/list contexts
   - `.medium()` — `strokeWidth: 3`, 24x24, default
   - `.large()` — `strokeWidth: 4`, 48x48, for full-page loading
2. Extract `_ShimmerSurface` into a reusable `ShimmerPlaceholder` widget
3. Create `ShimmerListItem`, `ShimmerCard` skeleton widgets for list/card loading states (prevents layout shift)
4. Use `CircularProgressIndicator.adaptive()` everywhere for platform-native feel on iOS

---

## V9. Translations / l10n

### Current State

- **~51 strings** use `AppLocalizations.of(context)!` (translated)
- **~70 strings** are hardcoded English `Text('...')` literals (not translated)
- Only English ARB file exists (`app_en.arb` with ~68 keys)
- No pluralization rules, no parameterized messages beyond simple string interpolation

**Hardcoded string hotspots:**

- `dev.dart` (debug screen — acceptable)
- `payment.dart`, `payment_method.dart` — "Pay directly", "Use Escrow", "Copy", "Open wallet"
- `swap_in.dart`, `swap_out.dart` — "Confirm", "Continue"
- `listing_view.dart` — "Blocked Dates", "Block Dates", "Retry"
- `background_tasks.dart` — all debug strings (acceptable)
- `edit_review.dart` — "Save"
- Various error messages — "Error:", "Unknown message type", "No wallet connected"

### Recommendation

1. **Immediate:** Extract all user-facing hardcoded strings to `app_en.arb`. Debug-only strings (dev.dart, background_tasks.dart) can stay hardcoded
2. **Naming convention:** Use `camelCase` keys matching the semantic role: `payDirectly`, `useEscrow`, `blockedDates`, `retryButton`, `noWalletConnected`
3. **Error messages:** Create parameterized ARB entries: `"errorGeneric": "Something went wrong: {details}"` with `@errorGeneric` metadata for placeholders
4. **Plurals:** Add plural rules for counts: `"reviewCount": "{count, plural, =0{No reviews} =1{1 review} other{{count} reviews}}"`
5. **When ready for multi-language:** add `app_es.arb`, `app_fr.arb`, etc. The Flutter l10n tooling will generate all delegates automatically

---

# Part B — Logic

## L1. Error Handling

### Current State — 5+ Inconsistent Patterns

| Pattern                                     | Cubits                                                   | Severity          |
| ------------------------------------------- | -------------------------------------------------------- | ----------------- |
| `EntityCubitStateError(dynamic error)`      | `EntityCubit`, `ProfileCubit`                            | ⚠️ `dynamic` type |
| Status enum + `String? error` field         | `ReservationCubit`, `ThreadReplyCubit`                   | OK                |
| Sealed class with error subclass            | `OnboardingCubit`, `AvailabilityCubit`                   | ✅ Best           |
| No error state at all                       | `ListCubit`, `CountCubit`                                | ⛔ Critical       |
| SDK operations with typed failure + rethrow | `PayOperation`, `SwapInOperation`, `EscrowFundOperation` | ⚠️ Double-report  |

### Critical Issues

#### 1. `ListCubit` has NO error handling

The `next()` method has a `try/finally` with **no `catch`**. The `sync()` subscription listener has **no `onError`**. This is the core data-fetching cubit — any relay failure crashes the stream silently.

#### 2. `CountCubit.count()` has no `try/catch`

`CountCubitStateError` is defined but **never emitted** — dead code. Exceptions from `nostrService.requests.count()` propagate unhandled.

#### 3. `PayOperation` double-reports errors

Each stage (`resolve`, `finalize`, `complete`) emits `PayFailed` AND rethrows the exception. If the caller also catches, the error surfaces twice. Additionally, `complete()` closes the cubit in a `finally` block — so `PayFailed` is emitted, then the cubit immediately closes, potentially causing a race condition in `BlocBuilder`.

#### 4. Swap failures discard error details

The UI renders `SwapInFailed` / `SwapOutFailed` as hardcoded `"Swap failed."` strings, ignoring the `error` field that contains actionable information (e.g. "insufficient inbound liquidity", "invoice expired").

#### 5. No global error boundary

`runZonedGuarded` only calls `debugPrint`. No crash reporting (Sentry, Crashlytics). No `FlutterError.onError`. No `BlocObserver` for cubit error monitoring.

#### 6. Raw error strings shown to users

`PayFailed` and auth errors show `e.toString()` directly in the UI — exposing internal stack traces, exception class names, or cryptic relay errors to users.

### Recommendations

1. **Standardize on sealed error states.** Every cubit should use:
   ```dart
   sealed class MyState { ... }
   class MyError extends MyState { final String userMessage; final Object? cause; }
   ```
2. **Add `try/catch` to `ListCubit.next()`** — emit an error state, enable retry
3. **Wire up `CountCubitStateError`** — emit it in the `catch` block
4. **Remove rethrow from `PayOperation`** — emit `PayFailed` only, don't rethrow. Let UI handle via `BlocListener`
5. **Don't close the cubit in `PayOperation.complete()` on failure** — let the UI decide when to dismiss
6. **Map errors to user-friendly messages** — create an `ErrorMapper` that converts known exceptions to localized strings. Unknown errors → generic "Something went wrong. Please try again."
7. **Add global `BlocObserver`** for logging all cubit transitions and errors
8. **Add Sentry/Crashlytics** in `runZonedGuarded` and `FlutterError.onError`
9. **Use `BlocListener` for transient error toasts** — complement `BlocBuilder` error rendering with snackbar notifications for errors the user should know about but that don't replace the screen

---

## L2. Stream & Listener Lifecycle

### Current State — ✅ Generally Well-Managed

All cubits with subscriptions properly override `close()` and cancel subscriptions:

- `ThreadCubit` — cancels all subs, closes participant cubits, deactivates trade
- `ListCubit` — cancels 5 subscriptions, closes `itemStream` and nostr response
- `NwcConnectivityCubit` — cancels connections subscription + per-cubit map
- `OnboardingCubit` — cancels threads subscription, has `reset()`

All widgets with subscriptions cancel in `dispose()`:

- `ListingListItemWidget` — cancels reservation subscription, closes stream and cubits
- `SearchMapWidget` — cancels list subscription
- `EscrowFundWidget` — cancels selector subscription, closes operation and cubit

### Best Practice: `_subscriptions` list vs `takeUntil` vs individual fields

| Approach                                      | When to use                                                                                                                     |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Individual fields** (`_sub1`, `_sub2`)      | When you have 1–3 named subscriptions with distinct lifecycle                                                                   |
| **`List<StreamSubscription> _subscriptions`** | When subscriptions are dynamic or numerous (e.g. `ThreadCubit`)                                                                 |
| **`takeUntil(dispose$)`** with RxDart         | When using RxDart extensively and want declarative cleanup. Requires a `PublishSubject<void> _dispose$` that emits in `close()` |
| **`CompositeSubscription`** (RxDart)          | Alternative to list — `composite.add(stream.listen(...))`, then `composite.dispose()`                                           |

The current codebase uses approach 1 and 2, which is fine. No change required unless you adopt RxDart more heavily.

### One Risk Found

`ProfileCubit` doesn't override `close()` and holds no subscriptions — but it's created dynamically by `ThreadCubit` which is responsible for closing it. This delegation pattern is correct but **fragile**: if any other code creates a `ProfileCubit` without closing it, it will leak. Consider documenting this ownership convention.

---

## L3. Caching, Batching & Use Cases

### CRUD UseCase Architecture

`CrudUseCase<T>` is the backbone. Key behaviors:

| Feature                        | Status | Notes                                                                                         |
| ------------------------------ | ------ | --------------------------------------------------------------------------------------------- |
| **In-flight query dedup**      | ✅     | `_inFlightQueries` keyed by serialized filter — identical concurrent queries share one stream |
| **`getOne` batching**          | ✅     | 500ms debounce window, combines filters, matches results back to callers                      |
| **`findByTag` batching**       | ✅     | 500ms debounce, merges tag values into one relay query                                        |
| **NDK cache (subscribe)**      | ✅     | Initial query uses `cacheRead: true`, live uses `cacheWrite: true`                            |
| **NDK cache (one-shot query)** | ❌     | `cacheRead: false` — every `getOne`/`list` hits the relay                                     |
| **Application-level cache**    | ❌     | No in-memory or disk cache for domain objects                                                 |
| **Retry on failure**           | ❌     | No retry logic anywhere in the SDK                                                            |
| **`count()` efficiency**       | ❌     | Fetches ALL events and calls `.length` — no relay-side COUNT support                          |

### Caching Strategy Recommendations

1. **Enable `cacheRead: true` for `query()`** — the NDK's `MemCacheManager` already supports this; flipping the flag would give free in-memory caching for repeated queries (e.g. viewing the same listing twice)
2. **Add a TTL-based invalidation** — cached items should expire after N minutes. Stale-while-revalidate pattern: return cached immediately, refetch in background, update if changed
3. **Profile-level caching** — user profiles (`kind: 0`) are fetched repeatedly; add a `ProfileCache` keyed by pubkey with a 5-minute TTL
4. **Listing image caching** — adopt `cached_network_image` for disk-level image caching (see V7)
5. **Relay-side COUNT** — NIP-45 defines `COUNT` messages. If your relays support it, implement a proper `count()` that doesn't download all events. The NDK may already support this — check `Ndk.requests.count()`

### Batching Tuning

The 500ms debounce window is a trade-off:

- **Pro:** Maximizes batching — more calls coalesce into fewer relay queries
- **Con:** Adds 500ms latency to every first request in a batch window

Consider **adaptive debounce**: start at 50ms, extend to 500ms only when under high load (>5 pending requests). For UI-triggered fetches (user taps a listing), 50ms is imperceptible; for background syncs, 500ms is fine.

---

## L4. Load & Performance Hotspots

### 🔴 Critical

#### 1. Subscription Explosion per Active Trade

Each `ThreadTrade` opens **3–4 concurrent Nostr subscriptions** (all reservations, filtered reservations, reviews, zaps, escrow events). A user with 10 active trades = **30–50 concurrent relay subscriptions**. Most relays cap at 10–20 concurrent subscriptions and will start closing older ones.

**Fix:** Multiplex trade subscriptions. Instead of per-trade subscriptions, open ONE subscription per kind that covers all active trades using combined filters, then dispatch events to the appropriate trade in-memory.

#### 2. N+1 Query in `subscribeToMyReservations()`

For each reservation request message in the thread stream, a full `getListingReservations()` relay query fires. 20 messages = 20 queries.

**Fix:** Batch listing IDs from all messages, then fire a single `findByTag` query covering all listings at once.

#### 3. `count()` Downloads Everything

`CrudUseCase.count()` fetches all matching events and calls `.toList().length`. For listings with hundreds of reservations, this is hugely wasteful.

**Fix:** Implement NIP-45 `COUNT` if relays support it, or cache counts locally with invalidation on new events.

### 🟡 Moderate

#### 4. Thread Rebuild on Every `sync()`

`Threads._rebuildThreadsFromMessages()` clears all threads and re-processes every persisted message on each login. With 500+ messages, this is O(n) on startup.

**Fix:** Incremental thread updates — only process new messages since last sync timestamp.

#### 5. Gift-wrap Fan-out

Each DM creates N+1 gift-wraps (one per recipient + self). A message to 3 participants = 4 broadcasts. This is inherent to NIP-17 and can't be avoided, but it's worth monitoring.

#### 6. No Query-level Caching for `query()`

Since `query()` uses `cacheRead: false`, the same listing/metadata is fetched repeatedly when navigating between screens.

---

## L5. Nostr Protocol Future-Proofing

### Event Versioning — Currently None

There is **zero versioning infrastructure**:

- No `version` field in any event content JSON
- No version tag on events
- `fromJson` methods have no fallback for missing fields
- Adding a required field to `ListingContent` would crash parsing of every existing listing on relays

**Impact scenario:** You add `cancellationPolicy` to `ListingContent`. Every old listing on relays fails to parse → `fromJson` throws → parser rethrows → stream crashes.

### Recommendations

#### 1. Add a Content Version Field

```json
{ "v": 1, "title": "...", "description": "...", ... }
```

Add `"v"` to all custom event content. Start at `1`. Increment on breaking changes.

#### 2. Make `fromJson` Tolerant

Use `json["field"] ?? defaultValue` for all fields. `Amenities.fromJSON` already does this correctly — propagate the pattern to `ListingContent`, `ReservationContent`, `ReviewContent`, etc.

#### 3. Add a Version Tag to Events

```
["v", "1"]
```

This allows relay-side filtering by version if needed, and lets clients ignore events they can't parse.

#### 4. Implement a Migrator

When the app starts, query for own events with outdated versions, re-sign with updated content, and republish. Since Nostr events are immutable (signed), migration requires publishing new replaceable events (same `d`-tag, newer `created_at`).

```dart
class EventMigrator {
  Future<void> migrate(List<Nip01Event> myEvents) async {
    for (final event in myEvents) {
      final version = event.getTagValue('v') ?? '0';
      if (int.parse(version) < currentVersion) {
        final migrated = migrateContent(event, from: version, to: currentVersion);
        await broadcast(migrated); // replaceable: same d-tag overwrites
      }
    }
  }
}
```

#### 5. Parser Error Resilience

The parser currently rethrows on malformed events, crashing the entire stream. Change to:

```dart
T? safeParser<T>(Nip01Event event) {
  try {
    return parser<T>(event);
  } catch (e, st) {
    logger.warning('Skipping malformed event ${event.id}: $e');
    return null;  // Skip, don't crash
  }
}
```

Then filter nulls from the stream. This is critical for forward-compatibility — a newer client might publish events that an older client can't parse.

#### 6. Kind Number Issue

`kNostrKindEscrowService = 40021` is in the ephemeral range (≥40000). Relays are not expected to store ephemeral events. Move to 30000–39999 range (parameterized replaceable).

#### 7. Tag Collision Risk

Single-letter tags `l`, `r`, `t`, `h` may collide with future NIP standardizations (NIP-32 already uses `l` for labels). Options:

- Formally propose these tag usages in a NIP
- Switch to multi-character tags (e.g., `listing`, `reservation`)
- Accept the collision risk and handle it in the parser by checking `event.kind` before interpreting tags

### Nostr Best Practices for Schema Evolution

1. **Replaceable events are your friend** — same `pubkey + kind + d-tag` naturally supersedes old versions
2. **Content is opaque to relays** — you can change JSON structure freely; relays only index tags
3. **Tags are the public API** — treat tag names and semantics as stable; content JSON as internal
4. **Backwards-compatible additions** — new optional fields with defaults are always safe
5. **Breaking changes** — require a new kind number or a version tag that old clients can filter out

---

## L6. Test Infrastructure & Automation

### Current State

| Area                  | Status          | Notes                                             |
| --------------------- | --------------- | ------------------------------------------------- |
| SDK unit tests        | ✅ 11 files     | Good coverage of core logic                       |
| SDK integration tests | ✅ 3 files      | Real Docker stack, escrow + swap flows            |
| App unit tests        | ❌ Nearly empty | Only 1 smoke test (2+3=5) and 1 cubit test        |
| App widget tests      | ❌ Empty        | Directory scaffolded but no tests                 |
| App integration tests | ⚠️ Minimal      | 1 screenshot test with 6 screens                  |
| Widgetbook            | ✅              | Well-structured, multi-device frames              |
| Shared test helpers   | ⚠️              | `_Fake*` classes duplicated across SDK test files |
| Visual regression     | ❌              | No golden test comparison                         |

### Seed Data Architecture — Two Systems

**System 1: Static Stubs** (`models/lib/stubs/`) — Hardcoded mock data with 3 fixed keypairs. Used for `Env.mock` quick startup.

**System 2: SeedPipeline** (`hostr_sdk/lib/seed/`) — Sophisticated deterministic seed generation with configurable user count, host ratio, thread progression stages, per-user overrides. This is excellent but **only used in SDK tests**, not in app integration tests.

### What's Missing for Desired Workflows

#### Flutter Drive to Specific Pages

The current integration test uses `appRouter.navigate()` which works but requires full app bootstrap. For surgical page testing:

1. **Create a `TestScenario` class:**

   ```dart
   class TestScenario {
     final SeedPipelineConfig seedConfig;
     final List<PageRouteInfo> pages;  // auto_route page definitions
     final String name;
   }
   ```

2. **Define scenarios:**

   ```dart
   final hostWithBookings = TestScenario(
     name: 'host-with-bookings',
     seedConfig: SeedPipelineConfig(
       seed: 42,
       userCount: 5,
       hostRatio: 0.5,
       threadStageSpec: ThreadStageSpec.allCompleted(),
     ),
     pages: [HostBookingsRoute()],
   );
   ```

3. **Run per-scenario:** `flutter test integration_test/scenarios/host_with_bookings_test.dart`

#### App Store Screenshot Pipeline

1. **Device matrix:** Run against multiple simulators/emulators — define in a shell script:

   ```bash
   DEVICES=("iPhone 16 Pro Max" "iPhone SE" "iPad Pro 12.9")
   for device in "${DEVICES[@]}"; do
     flutter test integration_test/ -d "$device"
   done
   ```

2. **Locale matrix:** Before each screenshot set, switch locale:

   ```dart
   await tester.binding.setLocale('es', 'ES');
   ```

3. **Framing:** Use `screenshots` or `device_frame` package to add device bezels, then composite with Fastlane's `frameit` or a custom script.

4. **CI integration:** On tagged commits, run the screenshot pipeline and upload to an artifact store. Fastlane `deliver` can submit to App Store Connect directly.

#### Shared Test Setup/Teardown

1. **Extract `_Fake*` classes** from SDK test files into `hostr_sdk/test/helpers/`:

   ```
   test/helpers/
     fake_requests.dart
     fake_auth.dart
     fake_messaging.dart
     test_fixtures.dart
   ```

2. **Create app-level test helpers** in `app/test/helpers/`:

   ```
   test/helpers/
     pump_app.dart         — wraps MaterialApp + providers + router
     scenario_runner.dart  — seeds data + navigates to page
     mock_providers.dart   — pre-configured BlocProviders for widget tests
   ```

3. **Use `SeedPipeline` in app tests** — bridge the SDK's seed system into the app's `TestRequests`:
   ```dart
   final pipeline = SeedPipeline(config);
   final events = await pipeline.build();
   final requests = TestRequests();
   requests.seedEvents(events);
   ```

#### Mock Relay vs Real Relay Strategy

| Test type              | Data source                               | Speed     | Reliability              | Use for                             |
| ---------------------- | ----------------------------------------- | --------- | ------------------------ | ----------------------------------- |
| **Unit tests**         | `TestRequests` (in-memory)                | ⚡ Fast   | 100% deterministic       | Business logic, cubits, parsers     |
| **Widget tests**       | `TestRequests` (in-memory)                | ⚡ Fast   | 100% deterministic       | UI rendering, interaction           |
| **Integration (mock)** | `MockRelay` (local WebSocket)             | 🔶 Medium | ~99% deterministic       | Full relay protocol, gift-wrap flow |
| **Integration (real)** | Docker stack (`./scripts/start_local.sh`) | 🐌 Slow   | ~95% (depends on Docker) | Escrow, swaps, on-chain, end-to-end |

**Strategy:**

1. Default to `TestRequests` for all app tests (fast, deterministic)
2. Use `MockRelay` only when testing relay-specific behavior (subscription management, auth, reconnection)
3. Use real Docker stack only for escrow/swap integration tests and manual QA
4. Tag tests: `@Tags(['unit'])`, `@Tags(['integration'])`, `@Tags(['e2e'])` — run subsets in CI

---

# Execution Plan

## Phase 1 — Foundation (Week 1)

_No visible UI changes, but enables everything else._

|  #  | Task                                                                   | Priority | Estimated Effort |
| :-: | ---------------------------------------------------------------------- | :------: | :--------------: |
| 1.1 | Define spacing scale constants (`kSpace0`–`kSpace8`) + `Gap` widget    |    🔴    |        2h        |
| 1.2 | Define icon size constants (`kIconXs`–`kIconHero`)                     |    🔴    |       30m        |
| 1.3 | Add `kAnimationDurationFast` constant                                  |    🟢    |       15m        |
| 1.4 | Create `showAppModal()` helper with standard defaults                  |    🟠    |        1h        |
| 1.5 | Create `AppLoadingIndicator` widget with `.small()/.medium()/.large()` |    🟠    |        1h        |
| 1.6 | Extract `_ShimmerSurface` into reusable `ShimmerPlaceholder`           |    🟠    |        1h        |
| 1.7 | Create `AppErrorWidget` (replaces `Placeholder()` for image errors)    |    🟠    |       30m        |
| 1.8 | Create `ErrorMapper` service (exceptions → user-friendly strings)      |    🔴    |        2h        |

## Phase 2 — Visual Consistency (Week 2)

_Systematic sweep across all presentation files._

|  #   | Task                                                               | Priority | Estimated Effort |
| :--: | ------------------------------------------------------------------ | :------: | :--------------: |
| 2.1  | Replace all hardcoded `SizedBox` spacing with `Gap.*`              |    🔴    |        4h        |
| 2.2  | Replace all hardcoded `fontSize:` with `textTheme.*`               |    🔴    |        2h        |
| 2.3  | Replace all `ElevatedButton` with `FilledButton` for primary CTAs  |    🟠    |        1h        |
| 2.4  | Replace all hardcoded icon sizes with `kIcon*` constants           |    🟠    |        2h        |
| 2.5  | Replace hardcoded animation durations/curves with constants        |    🟢    |       30m        |
| 2.6  | Replace all `showModalBottomSheet` with `showAppModal()`           |    🟠    |        2h        |
| 2.7  | Replace all `CircularProgressIndicator` with `AppLoadingIndicator` |    🟠    |        1h        |
| 2.8  | Add `cached_network_image`, wire into `BlossomImage`               |    🟠    |        2h        |
| 2.9  | Add shimmer placeholders to image loading and list loading         |    🟠    |        3h        |
| 2.10 | Extract remaining hardcoded strings to `app_en.arb`                |    🟡    |        2h        |

## Phase 3 — Error Handling (Week 3)

|  #  | Task                                                                       | Priority | Estimated Effort |
| :-: | -------------------------------------------------------------------------- | :------: | :--------------: |
| 3.1 | Add `try/catch` + error state to `ListCubit`                               |    ⛔    |        2h        |
| 3.2 | Wire `CountCubitStateError` emission                                       |    🔴    |       30m        |
| 3.3 | Fix `PayOperation` — remove rethrow, don't close on failure                |    🔴    |        2h        |
| 3.4 | Show actual error details in swap failure UI                               |    🟠    |        1h        |
| 3.5 | Standardize all cubit error states to sealed classes                       |    🟠    |        4h        |
| 3.6 | Add `BlocObserver` for global error/transition logging                     |    🟠    |        1h        |
| 3.7 | Integrate Sentry/Crashlytics in `runZonedGuarded` + `FlutterError.onError` |    🟠    |        2h        |
| 3.8 | Add `BlocListener`-based error snackbars for transient errors              |    🟡    |        3h        |

## Phase 4 — Performance & Protocol (Week 4)

|  #  | Task                                                                    | Priority | Estimated Effort |
| :-: | ----------------------------------------------------------------------- | :------: | :--------------: |
| 4.1 | Make parser error-resilient (skip malformed events, don't crash stream) |    ⛔    |        2h        |
| 4.2 | Add `"v": 1` to all custom event content JSON                           |    🔴    |        3h        |
| 4.3 | Make all `fromJson` tolerant with `?? default` fallbacks                |    🔴    |        3h        |
| 4.4 | Enable `cacheRead: true` for `query()` in `CrudUseCase`                 |    🟠    |        1h        |
| 4.5 | Fix N+1 in `subscribeToMyReservations()` — batch listing IDs            |    🟠    |        3h        |
| 4.6 | Multiplex trade subscriptions to reduce subscription count              |    🟠    |        6h        |
| 4.7 | Fix `kNostrKindEscrowService` kind number (40021 → 3xxxx)               |    🟠    |        1h        |
| 4.8 | Implement NIP-45 COUNT if relays support it                             |    🟡    |        2h        |

## Phase 5 — Test Infrastructure (Week 5)

|  #  | Task                                                                  | Priority | Estimated Effort |
| :-: | --------------------------------------------------------------------- | :------: | :--------------: |
| 5.1 | Extract shared `_Fake*` classes to `hostr_sdk/test/helpers/`          |    🟠    |        2h        |
| 5.2 | Create `app/test/helpers/pump_app.dart` for widget test bootstrapping |    🟠    |        2h        |
| 5.3 | Bridge `SeedPipeline` into app integration tests via `TestRequests`   |    🟠    |        3h        |
| 5.4 | Create `TestScenario` framework for page-specific flutter drive tests |    🟠    |        4h        |
| 5.5 | Implement device × locale screenshot matrix script                    |    🟡    |        3h        |
| 5.6 | Add golden image tests for key widgets                                |    🟡    |        4h        |
| 5.7 | Add test tags (`unit`, `integration`, `e2e`) + CI configuration       |    🟡    |        2h        |
| 5.8 | Build `EventMigrator` for versioned event migration on app start      |    🟡    |        4h        |

---

> **Total estimated effort:** ~85 hours across 5 phases.
> Phases 1–2 are visual and can be done in parallel with Phase 3 (error handling).
> Phase 4 (performance/protocol) should come after Phase 3 since error resilience is a prerequisite.
> Phase 5 (testing) can begin any time but benefits from having Phases 1–4 complete.
