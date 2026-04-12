# VariableAmountInput — Research & Plan

## 1. Existing Amount Widgets

### `AmountInputWidget` — the keypad

**File:** `app/lib/presentation/component/widgets/amount/amount_input.dart`

A `FormField<DenominatedAmount>` with a numeric keypad grid (1–9, `.`, 0, ⌫).

```
┌─────────────────────────────────┐
│        ₿ 50,000                 │   ← formatAmount(value)
│     0 — ₿ 100,000              │   ← min — max range label
│                                 │
│     [ 1 ]  [ 2 ]  [ 3 ]        │
│     [ 4 ]  [ 5 ]  [ 6 ]        │
│     [ 7 ]  [ 8 ]  [ 9 ]        │
│     [ . ]  [ 0 ]  [ ⌫ ]        │
└─────────────────────────────────┘
```

Key properties:

- `initialValue: DenominatedAmount?` (defaults to `DenominatedAmount.zero('BTC', 8)`)
- `min: DenominatedAmount?` — highlights value red when below
- `max: DenominatedAmount?` — highlights value red when above
- BTC branch: edits raw sats (integer), `.` button disabled
- Non-BTC branch: edits decimal string via `DenominatedAmount.fromDecimal()`
- **No denomination switcher** — denomination is fixed at construction time
- **No currency conversion** — min/max must already be in the same denomination

### `AmountEditorBottomSheet`

Same file. Wraps `AmountInputWidget` in a modal with a "Done" button.
Used by `Reserve._editAmount()` and `negotiation.dart` counter-offer flow.

### `AmountWidget` / `AmountFormField`

**File:** `app/lib/presentation/component/widgets/amount/amount.dart`

Display-only widget showing `formatAmount(amount)` in `displayMedium` with optional edit-tap (opens `AmountEditorBottomSheet`). Confirm button, fee widget, loading state.

### `formatAmount()` / `formatTokenAmount()`

Same file as `AmountInputWidget` (top of file).

- `formatAmount(DenominatedAmount)` — BTC → `"₿ 50,000"` (sats), USD → `"$ 12.50"`, ETH → `"Ξ 0.005"`
- `formatTokenAmount(TokenAmount)` — resolves denomination via `TokenDisplayResolver`, then delegates to `formatAmount()`

---

## 2. `DenominatedAmount` class

**File:** `models/lib/denominated_amount.dart`

```dart
class DenominatedAmount {
  final String denomination;  // "BTC", "USD", "ETH"
  final BigInt value;          // smallest-unit integer (sats, microdollars, wei)
  final int decimals;          // 8 for BTC, 6 for USD, 18 for ETH
}
```

Key features:

- `isBtc` / `isUsd` / `isEth` predicates (simple string equality)
- `rescale(int newDecimals)` — adjusts decimal precision
- `fromDecimal()` / `toDecimalString()` — human ↔ internal conversion
- Arithmetic: `+`, `-`, `*`, `scalarDiv()`, `compareTo()`, `<`, `<=`, `>`, `>=`
- `DenominatedAmount.zero(denomination, decimals)`
- `_assertSameDenomination()` guards — **cannot add/compare different denominations**

**Important:** There is no `CurrencyCode` type anywhere in the codebase. Denominations are plain `String` values (`"BTC"`, `"USD"`, `"ETH"`). The concept exists only as the `denomination` field.

---

## 3. Price / Frequency model

**File:** `models/lib/price.dart`

```dart
class Price {
  DenominatedAmount amount;
  Frequency? frequency;  // daily, weekly, monthly, yearly, or null (one-time)
}
```

Listings use `Price` with `Frequency.daily` as their nightly rate.

---

## 4. `TokenDisplayResolver`

**File:** `hostr_sdk/lib/usecase/evm/token_display_resolver.dart`

Resolves a `Token` (on-chain) or denomination `String` to `TokenDisplayInfo`:

```dart
class TokenDisplayInfo {
  final String denomination;   // "BTC", "USD", "ETH"
  final String symbol;         // "₿", "$", "Ξ"
  final bool showAsSmallestUnit;  // true for BTC (show in sats)
}
```

Static well-known map: `BTC → ₿`, `USD → $`, `ETH → Ξ`.

This is **display-only** — no exchange rates or conversion logic.

---

## 5. Quote Services (existing)

**File:** `hostr_sdk/lib/usecase/evm/operations/swap_in/swap_in_quote_service.dart`
**File:** `hostr_sdk/lib/usecase/evm/operations/swap_out/swap_out_quote_service.dart`

These are **swap-specific** quote services (Lightning ↔ on-chain via Boltz). They estimate gas, swap fees, and route through DEXes. They are NOT generic currency conversion services.

**There is no generic exchange-rate / fiat-conversion service in the codebase.** The app currently only works in BTC-denominated prices.

---

## 6. `EscrowMethod` and `AcceptedPaymentForm`

**File:** `models/lib/nostr/escrow_method.dart`

```dart
class AcceptedPaymentForm {
  final String denomination;  // "BTC", "USD"
  final String tokenTagId;    // e.g. "30:0xdAC17…" or "BTC"
}
```

An EscrowMethod event declares which denomination+token pairs a user will accept for payment. This is where multi-denomination support lives at the protocol level.

---

## 7. `EvmChainConfig` / `TokenConfig`

**File:** `hostr_sdk/lib/usecase/evm/config/evm_config.dart`

Each chain has a `nativeDenomination` (e.g. `"BTC"` for Rootstock, `"ETH"` for Arbitrum) and a map of well-known tokens with their denominations:

```dart
class TokenConfig {
  final String address;
  final String denomination;  // "BTC", "USD"
  ...
}
```

This is the source-of-truth for which denominations are available on which chain.

---

## 8. Existing form controllers

### `ListingPriceFieldController`

**File:** `app/lib/logic/forms/listing_price_field_controller.dart`

- Hardcoded to BTC/sats (`_denomination = 'BTC'`, `_decimals = 8`)
- Uses `TextEditingController` + `ThousandsSeparatorFormatter`
- Produces `DenominatedAmount` and `Price` objects

### `SatsAmountFieldController`

**File:** `app/lib/logic/forms/sats_amount_field_controller.dart`

- Also hardcoded to BTC/sats
- Handles optional (nullable) amounts
- Same `TextEditingController` + `ThousandsSeparatorFormatter` pattern

**Both controllers lack denomination switching.**

---

## 9. How `AmountInputWidget` is used today

### Reserve page (`reserve.dart`)

```dart
AmountEditorBottomSheet.show(
  context,
  initialAmount: _effectiveAmountFor(range),
  minAmount: DenominatedAmount(denomination: listingAmount.denomination, ...),
  maxAmount: listingAmount,
);
```

All values are in the listing's denomination (currently always BTC).

### Negotiation counter-offer (`negotiation.dart`)

```dart
AmountInputWidget(
  key: _amountFieldKey,
  initialValue: _amount,
  min: widget.minAmount,
  max: widget.maxAmount,
);
```

Again, all same-denomination. Validation uses raw `value` comparison.

### Payment flow (`payment.dart`)

```dart
DenominatedAmount(denomination: 'BTC', value: BigInt.zero, decimals: 8)
```

Hardcoded BTC.

---

## 10. Gaps & Requirements for `VariableAmountInput`

### What's missing

1. **Denomination switcher** — no widget lets the user toggle between BTC/USD/ETH
2. **Exchange rate service** — no conversion layer exists (swap quote services are too specialized)
3. **Cross-denomination min/max** — `AmountInputWidget` requires min/max in the same denomination as the input; no conversion
4. **Output denomination** — the input and the output denomination may differ (e.g. user types in USD but the tag is stored in BTC)

### Proposed `VariableAmountInput` widget

```dart
class VariableAmountInput extends FormField<DenominatedAmount> {
  /// The starting amount to display (may be in any denomination).
  final DenominatedAmount initialAmount;

  /// Lower bounds — one per denomination. The widget converts to the active
  /// denomination using the quote service.
  final List<DenominatedAmount> min;

  /// Upper bounds — same shape as [min].
  final List<DenominatedAmount> max;

  /// Denominations the user may type in / switch to (display side).
  /// e.g. ["BTC", "USD", "ETH"]
  final List<String> possibleDenominations;

  /// Denominations the output value may be stored in.
  /// Often the same as possibleDenominations, but may be a subset
  /// (e.g. only BTC for the tag, even if user typed USD).
  final List<String> possibleOutputDenominations;
}
```

### Architecture sketch

```
┌──────────────────────────────────────┐
│  ┌──────────────────────────────┐    │
│  │      ₿ 50,000               │    │
│  │    $4.85 — $97.00 range     │    │  ← min/max converted to active denom
│  └──────────────────────────────┘    │
│                                      │
│  [ BTC ▼ ]  denomination selector    │  ← SegmentedButton or Dropdown
│                                      │
│  ┌───┐ ┌───┐ ┌───┐                  │
│  │ 1 │ │ 2 │ │ 3 │                  │
│  ├───┤ ├───┤ ├───┤                  │
│  │ 4 │ │ 5 │ │ 6 │    keypad        │
│  ├───┤ ├───┤ ├───┤                  │
│  │ 7 │ │ 8 │ │ 9 │                  │
│  ├───┤ ├───┤ ├───┤                  │
│  │ . │ │ 0 │ │ ⌫ │                  │
│  └───┘ └───┘ └───┘                  │
└──────────────────────────────────────┘
```

### Key design decisions needed

#### A. Exchange Rate / Quote Service

**Option 1: Standalone `ExchangeRateService`**
New service in `hostr_sdk` that fetches BTC/USD, BTC/ETH rates from an API (e.g. CoinGecko, Binance, or the LNbits exchange rate providers already configured).

```dart
abstract class ExchangeRateService {
  /// Get the rate to convert 1 unit of [from] to [to].
  Future<double> getRate(String from, String to);

  /// Convert a DenominatedAmount from one denomination to another.
  Future<DenominatedAmount> convert(DenominatedAmount amount, String toDenomination, int toDecimals);
}
```

**Option 2: Piggyback on Boltz quote**
The swap quote services already know BTC ↔ ERC20 rates. But they're chain-specific and include swap fees — not clean for display purposes.

**Option 3: Static / pre-fetched rates**
At listing-creation time, the host declares prices in BTC. The widget could accept a `Map<String, double>` of rates (e.g. fetched once when opening the screen).

**Recommendation:** Option 1 or 3. Option 2 conflates swap pricing with display rates. The simplest first step is Option 3 — pass rates in from above, convert locally. Upgrade to Option 1 (live service) later.

#### B. Denomination switching

When the user changes denomination:

1. Convert the current `value` to the new denomination using the rate
2. Convert `min`/`max` bounds to the new denomination
3. Re-render the keypad (BTC = integer sats, USD = 2-decimal, ETH = 8-decimal)

The `.` button should enable/disable based on denomination (currently hardcoded for BTC).

#### C. Output denomination

When the form is submitted:

- If `possibleOutputDenominations` contains the active denomination → emit as-is
- Otherwise → convert back to the preferred output denomination

This matters for listing tags like `securityDeposit` and `minPaymentAmount` which store `DenominatedAmount` — should they always be BTC? Or match the listing's price denomination?

**Current behavior:** Listings are BTC-only. Tags store sats. So for now, output denomination = BTC.

**Future:** When multi-denomination listings exist, the output denomination should match the listing's price denomination.

#### D. `possibleDenominations` source

For the edit-listing use case, the denominations come from:

1. The chain configs (`EvmChainConfig.nativeDenomination` + `TokenConfig.denomination`)
2. The user's `EscrowMethod.acceptedPaymentForms`
3. A hardcoded default: `["BTC"]`

For now, since the app only supports BTC-priced listings, `possibleDenominations` would be `["BTC"]` and the denomination switcher would be hidden (single option).

---

## 11. Refactoring path

### Phase 1: Extract keypad into composable pieces (no new features)

1. Extract the keypad grid from `AmountInputWidget` into a standalone `NumericKeypad` widget
2. Extract the denomination-aware display (symbol + formatting) into a helper
3. Keep `AmountInputWidget` as a thin wrapper that composes these pieces

### Phase 2: Add denomination switcher

1. Create `VariableAmountInput` that wraps `NumericKeypad` + denomination selector
2. Accept `possibleDenominations` — render `SegmentedButton` if >1, hide if ==1
3. When switching denomination, convert value + min/max using a rate map

### Phase 3: Exchange rate integration

1. Create `ExchangeRateService` (or accept `Map<String, Map<String, double>>` rates)
2. Wire into `VariableAmountInput` for live conversion
3. Show secondary amount label (e.g. "≈ $4.85" below the main amount)

### Phase 4: Replace existing controllers

1. Replace `SatsAmountFieldController` with a denomination-aware version
2. Upgrade `ListingPriceFieldController` to support non-BTC denominations
3. Update `edit_listing_inputs.dart` to use `VariableAmountInput`

---

## 12. Files that will need changes

| File                                                                       | Change                                                             |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| `app/lib/presentation/component/widgets/amount/amount_input.dart`          | Extract `NumericKeypad`, add `VariableAmountInput`                 |
| `app/lib/presentation/component/widgets/amount/amount.dart`                | Possibly add denomination label                                    |
| `app/lib/logic/forms/sats_amount_field_controller.dart`                    | Replace with denomination-aware controller                         |
| `app/lib/logic/forms/listing_price_field_controller.dart`                  | Support multiple denominations                                     |
| `app/lib/presentation/screens/shared/listing/edit_listing_inputs.dart`     | Use `VariableAmountInput` for price, security deposit, min payment |
| `app/lib/presentation/screens/shared/listing/edit_listing.controller.dart` | Handle denomination in price/security/min fields                   |
| `hostr_sdk/lib/usecase/` (new file)                                        | `ExchangeRateService`                                              |
| `models/lib/denominated_amount.dart`                                       | Possibly add `convertTo()` with rate param                         |

---

## 13. Open Questions

1. **Should `VariableAmountInput` be a `FormField<DenominatedAmount>`?** — Probably yes, to match `AmountInputWidget`'s existing pattern and be usable in `Form`s.

2. **Where do exchange rates come from?** — LNbits has a full exchange rate provider system (Binance, Coinbase, etc.) but it's server-side Python. The app could:
   - Call LNbits API for rates
   - Call a public API directly (CoinGecko, Binance)
   - Use Boltz pricing as a rough proxy

3. **Should the denomination switcher live inside the keypad or outside?** — Inside (like `VariableAmountInput`) for self-contained usage. The parent provides the list of possible denominations.

4. **What about `possibleOutputDenominations`?** — This may be premature. For now, the output denomination = the active denomination. Conversion on output can be added when multi-denomination listings land.

5. **No `CurrencyCode` type exists.** Should we create one? Could be a simple:
   ```dart
   /// Well-known denomination codes used across the protocol.
   abstract final class Denomination {
     static const btc = 'BTC';
     static const usd = 'USD';
     static const eth = 'ETH';
   }
   ```
   Or just keep using raw strings (current approach). The `TokenDisplayInfo` constants already serve as the de facto registry.
