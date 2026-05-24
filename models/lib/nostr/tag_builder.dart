import 'package:models/main.dart';

/// Fluent builder for constructing Nostr event tag arrays.
///
/// Encodes Dart values into `["key", "stringValue"]` pairs.
/// Use [build] to produce the final `List<List<String>>`.
class TagBuilder {
  final List<List<String>> _tags = [];

  // ── Scalar helpers ──────────────────────────────────────────────────

  TagBuilder add(String key, String value) {
    _tags.add([key, value]);
    return this;
  }

  TagBuilder addBool(String key, bool value) {
    _tags.add([key, value.toString()]);
    return this;
  }

  TagBuilder addInt(String key, int value) {
    _tags.add([key, value.toString()]);
    return this;
  }

  TagBuilder addEnum<T extends Enum>(String key, T value) {
    _tags.add([key, value.name]);
    return this;
  }

  TagBuilder addDateTime(String key, DateTime value) {
    _tags.add([key, value.toUtc().toIso8601String()]);
    return this;
  }

  /// Only adds the tag if [value] is non-null.
  TagBuilder addOptional(String key, String? value) {
    if (value != null) _tags.add([key, value]);
    return this;
  }

  TagBuilder addOptionalBool(String key, bool? value) {
    if (value != null) _tags.add([key, value.toString()]);
    return this;
  }

  TagBuilder addOptionalInt(String key, int? value) {
    if (value != null) _tags.add([key, value.toString()]);
    return this;
  }

  TagBuilder addOptionalEnum<T extends Enum>(String key, T? value) {
    if (value != null) _tags.add([key, value.name]);
    return this;
  }

  TagBuilder addOptionalDateTime(String key, DateTime? value) {
    if (value != null) _tags.add([key, value.toUtc().toIso8601String()]);
    return this;
  }

  TagBuilder addOptionalAmount(String key, TokenAmount? value) {
    if (value != null) {
      _tags.add([key, '${value.toDecimalString()}:${value.token.tagId}']);
    }
    return this;
  }

  /// Encodes a [DenominatedAmount] as `[key, amount, denomination, decimals]`.
  /// Only adds the tag when [value] is non-null.
  TagBuilder addOptionalDenominatedAmount(
      String key, DenominatedAmount? value) {
    if (value != null) {
      _tags.add([
        key,
        value.toDecimalString(),
        value.denomination,
        value.decimals.toString(),
      ]);
    }
    return this;
  }

  // ── NIP-99 image helpers ────────────────────────────────────────────

  /// Encodes each image URL as `["image", "url"]` (NIP-99 / NIP-58).
  TagBuilder addImages(List<String> images) {
    for (final url in images) {
      _tags.add(['image', url]);
    }
    return this;
  }

  /// Adds a NIP-92 inline media metadata tag.
  TagBuilder addIMeta(IMeta meta) {
    _tags.add(meta.toTag());
    return this;
  }

  /// Adds multiple NIP-92 inline media metadata tags.
  TagBuilder addIMetas(Iterable<IMeta> metas) {
    for (final meta in metas) {
      addIMeta(meta);
    }
    return this;
  }

  // ── NIP-99 price helpers ────────────────────────────────────────────

  /// Encodes each [Price] per NIP-99:
  /// - Recurring: `["price", "amount", "currency", "frequency"]`
  /// - One-time:  `["price", "amount", "currency"]`
  TagBuilder addPrices(List<Price> prices) {
    for (final p in prices) {
      final tag = [
        'price',
        p.amount.toDecimalString(),
        p.amount.denomination,
      ];
      if (p.frequency != null) {
        tag.add(p.frequency!.nip99Name);
      }
      _tags.add(tag);
    }
    return this;
  }

  /// Encodes each [CancellationPolicy] as a field-labeled tag.
  TagBuilder addCancellationPolicies(List<CancellationPolicy> policies) {
    for (final policy in policies) {
      final durationBeforeStart = policy.durationBeforeStart;
      final durationAfterOrder = policy.durationAfterOrder;
      if (durationBeforeStart == null && durationAfterOrder == null) {
        throw ArgumentError(
          'Cancellation policy must include durationBeforeStart, '
          'durationAfterOrder, or both.',
        );
      }
      if ((durationBeforeStart?.isNegative ?? false) ||
          (durationAfterOrder?.isNegative ?? false)) {
        throw ArgumentError(
          'Cancellation policy durations must be non-negative.',
        );
      }
      final tag = [
        'cancellationPolicy',
        'refundFraction',
        policy.refundFraction.toString(),
      ];
      if (durationBeforeStart != null) {
        tag.addAll([
          'secondsBeforeStart',
          durationBeforeStart.inSeconds.toString(),
        ]);
      }
      if (durationAfterOrder != null) {
        tag.addAll([
          'secondsAfterOrder',
          durationAfterOrder.inSeconds.toString(),
        ]);
      }
      _tags.add(tag);
    }
    return this;
  }

  // ── Specification helpers ───────────────────────────────────────────

  /// Adds a boolean spec tag.
  TagBuilder spec(String name) {
    _tags.add(['spec', name]);
    return this;
  }

  /// Adds a valued spec tag (only when value > 0).
  TagBuilder specValue(String name, int value) {
    if (value > 0) _tags.add(['spec', name, value.toString()]);
    return this;
  }

  /// Bulk-add from a [Specifications] object.
  TagBuilder addSpecifications(Specifications specifications) {
    _tags.addAll(specifications.toTags());
    return this;
  }

  /// Add tags and their single-letter promoted duplicates.
  ///
  /// For each tag, every matching [TagPromotion] rule emits an additional
  /// indexed copy. The original multi-letter tags are always included.
  TagBuilder addWithPromotions(
    List<List<String>> tags,
    List<TagPromotion> promotions,
  ) {
    _tags.addAll(tags);
    _tags.addAll(TagPromotion.promoteAll(tags, promotions));
    return this;
  }

  // ── Merge / build ───────────────────────────────────────────────────

  TagBuilder addAll(List<List<String>> existing) {
    _tags.addAll(existing);
    return this;
  }

  List<List<String>> build() => List.unmodifiable(_tags);
}
