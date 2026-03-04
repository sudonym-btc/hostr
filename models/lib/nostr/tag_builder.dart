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

  TagBuilder addAmount(String key, Amount amount) {
    _tags.add([key, '${amount.toDecimalString()}:${amount.currency.name}']);
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

  TagBuilder addOptionalAmount(String key, Amount? value) {
    if (value != null) {
      _tags.add([key, '${value.toDecimalString()}:${value.currency.name}']);
    }
    return this;
  }

  // ── Price helpers ───────────────────────────────────────────────────

  /// Encodes each [Price] as `["price", "decimalAmount:currency:frequency"]`.
  TagBuilder addPrices(List<Price> prices) {
    for (final p in prices) {
      _tags.add([
        'price',
        '${p.amount.toDecimalString()}:${p.amount.currency.name}:${p.frequency.name}',
      ]);
    }
    return this;
  }

  // ── Amenity helpers ─────────────────────────────────────────────────

  /// Adds boolean amenity tags (only when true).
  TagBuilder amenity(String name) {
    _tags.add(['amenity', name]);
    return this;
  }

  /// Adds numeric amenity tags (only when value > 0).
  TagBuilder amenityInt(String name, int value) {
    if (value > 0) _tags.add(['amenity', name, value.toString()]);
    return this;
  }

  /// Bulk-add from an [Amenities] object.
  TagBuilder addAmenities(Amenities amenities) {
    _tags.addAll(amenities.toTags());
    return this;
  }

  // ── Merge / build ───────────────────────────────────────────────────

  TagBuilder addAll(List<List<String>> existing) {
    _tags.addAll(existing);
    return this;
  }

  List<List<String>> build() => List.unmodifiable(_tags);
}
