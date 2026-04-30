import 'package:ndk/ndk.dart';

/// Describes how a multi-letter source tag should be duplicated as a
/// single-letter indexed tag for relay-side filtering.
///
/// Example:
/// ```dart
/// // Promote ['spec', 'beachfront'] → ['s', 'beachfront']
/// TagPromotion.boolean(source: 'spec', target: 's');
///
/// // Promote ['spec', 'max_guests', '4'] → ['c', '4']
/// TagPromotion.valued(source: 'spec', match: 'max_guests', target: 'c');
///
/// // Promote ['type', 'house'] → ['T', 'house']
/// TagPromotion.direct(source: 'type', target: 'T');
/// ```
class TagPromotion {
  /// Source tag name to match on (e.g. `'spec'`, `'type'`).
  final String source;

  /// If non-null, only promote tags where `tag[1] == match`.
  /// If null, promote all tags with this source name.
  final String? match;

  /// The single-letter tag key to emit (e.g. `'s'`, `'c'`, `'T'`).
  final String target;

  /// Which index of the source tag to use as the promoted value.
  ///
  /// - `1` → uses `tag[1]` (the spec name or enum value)
  /// - `2` → uses `tag[2]` (the numeric/string value)
  final int valueIndex;

  const TagPromotion({
    required this.source,
    required this.target,
    this.match,
    this.valueIndex = 1,
  });

  /// Promote all boolean specs: `['spec', 'pool']` → `['s', 'pool']`.
  const TagPromotion.boolean({
    required this.source,
    required this.target,
  })  : match = null,
        valueIndex = 1;

  /// Promote a specific valued spec: `['spec', 'max_guests', '4']` → `['c', '4']`.
  const TagPromotion.valued({
    required this.source,
    required this.match,
    required this.target,
  }) : valueIndex = 2;

  /// Promote a direct tag: `['type', 'house']` → `['T', 'house']`.
  const TagPromotion.direct({
    required this.source,
    required this.target,
  })  : match = null,
        valueIndex = 1;

  /// Returns the promoted tag if [tag] matches this rule, or `null`.
  List<String>? promote(List<String> tag) {
    if (tag.isEmpty || tag[0] != source) return null;
    if (match != null && (tag.length < 2 || tag[1] != match)) return null;
    if (tag.length <= valueIndex) return null;
    return [target, tag[valueIndex]];
  }

  /// Collect the set of all target letters from a list of promotions.
  static Set<String> targetLetters(List<TagPromotion> promotions) =>
      promotions.map((p) => p.target).toSet();

  /// Apply all [promotions] to a list of tags, returning the promoted
  /// duplicates only (the originals are NOT included).
  static List<List<String>> promoteAll(
    List<List<String>> tags,
    List<TagPromotion> promotions,
  ) {
    final results = <List<String>>[];
    for (final tag in tags) {
      for (final rule in promotions) {
        final promoted = rule.promote(tag);
        if (promoted != null) results.add(promoted);
      }
    }
    return results;
  }

  /// Canonical value for a boolean-feature conjunction tag.
  ///
  /// Nostr filters OR values within one tag key, so a query like
  /// `#s=[kitchen,allows_pets]` cannot mean "kitchen AND pets". Listings also
  /// emit compound `S` tags for every boolean-feature combination, allowing a
  /// multi-feature query to target one exact value instead.
  static String booleanCombinationValue(Iterable<String> featureNames) {
    final normalized = featureNames
        .map((feature) => feature.trim())
        .where((feature) => feature.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return normalized.join('+');
  }

  /// Emit compound boolean-feature tags for all combinations of size >= 2.
  static List<List<String>> promoteBooleanCombinations(
    List<List<String>> tags, {
    required String target,
    String source = 'spec',
  }) {
    final features = tags
        .where((tag) => tag.length == 2 && tag.first == source)
        .map((tag) => tag[1].trim())
        .where((feature) => feature.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (features.length < 2) return const [];

    final results = <List<String>>[];
    void collect(int index, List<String> selected) {
      if (index == features.length) {
        if (selected.length >= 2) {
          results.add([target, booleanCombinationValue(selected)]);
        }
        return;
      }
      collect(index + 1, selected);
      selected.add(features[index]);
      collect(index + 1, selected);
      selected.removeLast();
    }

    collect(0, <String>[]);
    results.sort((a, b) => a[1].compareTo(b[1]));
    return results;
  }
}

/// Builds an NDK [Filter] from user-facing search criteria, using
/// [TagPromotion] rules to map criteria to the correct single-letter
/// tag keys.
///
/// Usage:
/// ```dart
/// final filter = ListingFilterBuilder(Listing.promotions)
///   .listingTypes([ListingType.house, ListingType.villa])
///   .minGuests(2)
///   .features(['beachfront', 'pool'])
///   .build();
/// ```
class ListingFilterBuilder {
  static const String booleanFeatureCombinationTag = 'S';

  final List<TagPromotion> _promotions;
  final Map<String, List<String>> _tags = {};
  final int _kind;

  ListingFilterBuilder(this._promotions, {required int kind}) : _kind = kind;

  /// Find the target letter for a given source + match combination.
  String? _targetFor({required String source, String? match}) {
    for (final p in _promotions) {
      if (p.source == source && p.match == match) return p.target;
    }
    // Fallback: find any rule matching just the source (for boolean/direct).
    if (match == null) return null;
    for (final p in _promotions) {
      if (p.source == source && p.match == null) return p.target;
    }
    return null;
  }

  /// Filter by listing type(s). Maps to the `'type'` promotion target.
  ListingFilterBuilder listingTypes(List<Enum> types) {
    final target = _targetFor(source: 'type');
    if (target != null) {
      _tags[target] = types.map((t) => t.name).toList();
    }
    return this;
  }

  /// Filter by minimum guest capacity. Generates values from [min] to [max].
  ListingFilterBuilder minGuests(int min, {int max = 20}) {
    final target = _targetFor(source: 'spec', match: 'max_guests');
    if (target != null) {
      _tags[target] = List.generate(max - min + 1, (i) => '${min + i}');
    }
    return this;
  }

  /// Filter by minimum beds. Generates values from [min] to [max].
  ListingFilterBuilder minBeds(int min, {int max = 20}) {
    final target = _targetFor(source: 'spec', match: 'beds');
    if (target != null) {
      _tags[target] = List.generate(max - min + 1, (i) => '${min + i}');
    }
    return this;
  }

  /// Filter by minimum bedrooms. Generates values from [min] to [max].
  ListingFilterBuilder minBedrooms(int min, {int max = 20}) {
    final target = _targetFor(source: 'spec', match: 'bedrooms');
    if (target != null) {
      _tags[target] = List.generate(max - min + 1, (i) => '${min + i}');
    }
    return this;
  }

  /// Filter by minimum bathrooms. Generates values from [min] to [max].
  ListingFilterBuilder minBathrooms(int min, {int max = 20}) {
    final target = _targetFor(source: 'spec', match: 'bathrooms');
    if (target != null) {
      _tags[target] = List.generate(max - min + 1, (i) => '${min + i}');
    }
    return this;
  }

  /// Filter by boolean features (e.g. `['beachfront', 'pool']`).
  /// These map to the boolean spec promotion target.
  ListingFilterBuilder features(List<String> featureNames) {
    final target = _targetFor(source: 'spec');
    final normalized = featureNames
        .map((feature) => feature.trim())
        .where((feature) => feature.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (normalized.isEmpty) return this;

    if (normalized.length == 1 && target != null) {
      _tags.update(target, (v) => [...v, ...normalized],
          ifAbsent: () => normalized);
    } else {
      _tags[ListingFilterBuilder.booleanFeatureCombinationTag] = [
        TagPromotion.booleanCombinationValue(normalized),
      ];
    }
    return this;
  }

  /// Filter to listings where price negotiation is supported.
  ListingFilterBuilder negotiable() {
    final target = _targetFor(source: 'negotiable');
    if (target != null) {
      _tags[target] = ['true'];
    }
    return this;
  }

  /// Merge additional raw tag filters (e.g. geohash).
  ListingFilterBuilder rawTags(Map<String, List<String>> tags) {
    for (final entry in tags.entries) {
      _tags.update(entry.key, (v) => [...v, ...entry.value],
          ifAbsent: () => entry.value);
    }
    return this;
  }

  /// Build the NDK [Filter].
  Filter build() {
    return Filter(
      kinds: [_kind],
      tags: _tags.isEmpty ? null : _tags,
    );
  }
}
