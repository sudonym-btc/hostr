import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

const _publishedAtTag = 'published_at';

// ── Tag-read mixin ──────────────────────────────────────────────────────────
// Defines all tag-promoted field getters ONCE. Mixed into both ListingTags
// and Listing so callers can use either `listing.negotiable` or
// `listing.parsedTags.negotiable`.

mixin ListingTagRead {
  EventTags get tagSource;

  // ── NIP-99 tag-promoted fields ────────────────────────────────────
  String get title => tagSource.getTagValue('title') ?? '';
  List<String> get images => tagSource.getTags('image');
  List<IMeta> get imageMetas => tagSource.tags
      .where((tag) => tag.isNotEmpty && tag.first == 'imeta')
      .map(IMeta.fromTag)
      .where((meta) => meta.url.isNotEmpty)
      .toList();

  bool get active => tagSource.getTagBool('active', defaultValue: true);
  bool get negotiable => tagSource.getTagBool('negotiable');
  int get minStay => tagSource.getTagInt('minStay') ?? 1;
  String? get checkIn => tagSource.getTagValue('checkIn');
  String? get checkOut => tagSource.getTagValue('checkOut');
  String get location => tagSource.getTagValue('location') ?? '';
  int get quantity => tagSource.getTagInt('quantity') ?? 1;
  ListingType get listingType =>
      tagSource.getTagEnum('type', ListingType.values) ?? ListingType.room;
  bool get instantBook =>
      tagSource.getTagBool('instantBook', defaultValue: true);
  bool get allowSelfSignedReservation =>
      tagSource.getTagBool('allowSelfSignedReservation');
  List<Price> get prices => tagSource.getTagPrices();
  List<CancellationPolicy> get cancellationPolicies =>
      tagSource.getTagCancellationPolicies();
  List<CancellationPolicy> get cancellationPolicy => cancellationPolicies;
  Specifications get specifications => Specifications.fromTags(tagSource.tags);

  @Deprecated('Use specifications instead')
  Specifications get amenities => specifications;

  /// Optional security deposit that the guest must lock alongside the
  /// payment amount. Stored as `['securityDeposit', amount, denomination, decimals]`.
  DenominatedAmount? get securityDeposit =>
      tagSource.getTagDenominatedAmount('securityDeposit');

  /// Optional minimum payment amount the host will accept.
  /// Stored as `['minPaymentAmount', amount, denomination, decimals]`.
  DenominatedAmount? get minPaymentAmount =>
      tagSource.getTagDenominatedAmount('minPaymentAmount');

  /// Maximum time in seconds after the reservation end date that the escrow
  /// must unlock at. Stored as `['maxDisputePeriod', '<seconds>']`.
  /// Defaults to 2 weeks (1 209 600 s) when not set.
  static const int defaultMaxDisputePeriod = 14 * 24 * 60 * 60; // 2 weeks
  int get maxDisputePeriod =>
      tagSource.getTagInt('maxDisputePeriod') ?? defaultMaxDisputePeriod;
}

// ── Tags class ──────────────────────────────────────────────────────────────

class ListingTags extends EventTags with ListingTagRead {
  ListingTags(super.tags);

  @override
  EventTags get tagSource => this;
}

// ── Event class ─────────────────────────────────────────────────────────────

class Listing extends Event<ListingTags> with ListingTagRead {
  static const List<int> kinds = [kNostrKindListing];
  static final EventTagsParser<ListingTags> _tagParser = ListingTags.new;

  // ── Tag promotions (single-letter relay-indexed duplicates) ────────
  //
  // Each rule duplicates a multi-letter tag as a single-letter indexed
  // tag so relays can filter on it via NIP-01.  Different letters give
  // us free AND across filter dimensions.
  //
  // | Letter | Dimension     | Source tag example                    |
  // |--------|---------------|---------------------------------------|
  // | T      | Listing type  | ['type', 'house']        → ['T','house']  |
  // | s      | Bool features | ['spec', 'pool']         → ['s','pool']   |
  // | c      | Max guests    | ['spec','max_guests','4'] → ['c','4']     |
  // | b      | Beds          | ['spec','beds','2']       → ['b','2']     |
  // | B      | Bedrooms      | ['spec','bedrooms','2']   → ['B','2']     |
  // | R      | Bathrooms     | ['spec','bathrooms','2']  → ['R','2']     |
  // | N      | Negotiable    | ['negotiable','true']     → ['N','true']  |

  static const List<TagPromotion> promotions = [
    TagPromotion.direct(source: 'type', target: 'T'),
    TagPromotion.boolean(source: 'spec', target: 's'),
    TagPromotion.valued(source: 'spec', match: 'max_guests', target: 'c'),
    TagPromotion.valued(source: 'spec', match: 'beds', target: 'b'),
    TagPromotion.valued(source: 'spec', match: 'bedrooms', target: 'B'),
    TagPromotion.valued(source: 'spec', match: 'bathrooms', target: 'R'),
    TagPromotion.direct(source: 'instantBook', target: 'I'),
    TagPromotion.direct(source: 'negotiable', target: 'N'),
  ];

  /// Letters emitted by [promotions] — stripped during [rebuild] so they
  /// can be re-generated from the authoritative multi-letter tags.
  static final Set<String> _promotedLetters =
      TagPromotion.targetLetters(promotions);

  /// Returns a [ListingFilterBuilder] pre-configured with this event's
  /// kind and promotion rules.
  ///
  /// ```dart
  /// final filter = Listing.buildFilter()
  ///   .listingTypes([ListingType.house])
  ///   .minGuests(2)
  ///   .features(['pool', 'beachfront'])
  ///   .build();
  /// ```
  static ListingFilterBuilder buildFilter() =>
      ListingFilterBuilder(promotions, kind: kNostrKindListing);

  @override
  EventTags get tagSource => parsedTags;

  // ── NIP-99: description is the .content field (Markdown) ────────────
  String get description => content;

  Listing(
      {required super.pubKey,
      required super.tags,
      required super.content,
      super.createdAt,
      super.id,
      super.sig})
      : super(kind: kNostrKindListing, tagParser: _tagParser);

  Listing.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
        );

  // ── Factory constructor ─────────────────────────────────────────────
  factory Listing.create({
    required String pubKey,
    required String dTag,
    // Content fields (non-searchable)
    required String title,
    required String description,
    required List<String> images,
    List<IMeta> imageMetas = const [],
    // Tag fields (searchable)
    required List<Price> price,
    required String location,
    required ListingType type,
    required Specifications specifications,
    bool active = true,
    bool negotiable = false,
    int minStay = 1,
    String checkIn = '15:0',
    String checkOut = '11:0',
    int quantity = 1,
    bool instantBook = true,
    bool allowSelfSignedReservation = false,
    List<CancellationPolicy> cancellationPolicy = const [],
    DenominatedAmount? securityDeposit,
    DenominatedAmount? minPaymentAmount,
    int? maxDisputePeriod,
    List<List<String>> extraTags = const [],
    int? createdAt,
  }) {
    final eventCreatedAt =
        createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return Listing(
      pubKey: pubKey,
      createdAt: eventCreatedAt,
      tags: ListingTags(
        (TagBuilder()
              ..add('d', dTag)
              ..add('title', title)
              ..addAll(_imageTags(images, imageMetas))
              ..addIMetas(imageMetas)
              ..add('t', 'accommodation')
              ..add(_publishedAtTag, eventCreatedAt.toString())
              ..addBool('active', active)
              ..addBool('negotiable', negotiable)
              ..addInt('minStay', minStay)
              ..add('checkIn', checkIn)
              ..add('checkOut', checkOut)
              ..add('location', location)
              ..addInt('quantity', quantity)
              ..addEnum('type', type)
              ..addBool('instantBook', instantBook)
              ..addBool(
                  'allowSelfSignedReservation', allowSelfSignedReservation)
              ..addPrices(price)
              ..addCancellationPolicies(cancellationPolicy)
              ..addOptionalDenominatedAmount('securityDeposit', securityDeposit)
              ..addOptionalDenominatedAmount(
                  'minPaymentAmount', minPaymentAmount)
              ..addOptionalInt('maxDisputePeriod', maxDisputePeriod)
              ..addSpecifications(specifications)
              // Emit single-letter promoted duplicates for relay indexing.
              ..addAll(TagPromotion.promoteAll([
                ['type', type.name],
                ['instantBook', instantBook.toString()],
                ['negotiable', negotiable.toString()],
                ...specifications.toTags(),
              ], promotions))
              ..addAll(extraTags))
            .build(),
      ),
      content: description,
    );
  }

  // ── Copy-with ───────────────────────────────────────────────────────
  Listing rebuild({
    // Tag fields
    bool? active,
    bool? negotiable,
    int? minStay,
    String? checkIn,
    String? checkOut,
    String? location,
    int? quantity,
    ListingType? type,
    bool? instantBook,
    bool? allowSelfSignedReservation,
    List<Price>? prices,
    List<CancellationPolicy>? cancellationPolicy,
    Specifications? specifications,
    DenominatedAmount? securityDeposit,
    bool clearSecurityDeposit = false,
    DenominatedAmount? minPaymentAmount,
    bool clearMinPaymentAmount = false,
    int? maxDisputePeriod,
    bool clearMaxDisputePeriod = false,
    // Content fields
    String? title,
    String? description,
    List<String>? images,
    List<IMeta>? imageMetas,
    // Event-level
    String? pubKey,
    int? createdAt,
    List<List<String>>? extraTags,
  }) {
    final firstPublishedAt =
        parsedTags.getTagInt(_publishedAtTag) ?? this.createdAt;

    // Preserve non-promoted tags (d, g, etc.)
    // Also strip single-letter promoted tags — they'll be regenerated.
    final stripKeys = {
      'title',
      'image',
      'imeta',
      't',
      'active',
      'negotiable',
      'minStay',
      'checkIn',
      'checkOut',
      'location',
      'quantity',
      'type',
      'instantBook',
      'allowSelfSignedReservation',
      'price',
      'cancellationPolicy',
      'spec',
      'amenity', // back-compat: strip legacy amenity tags on rebuild
      'securityDeposit',
      'minPaymentAmount',
      'maxDisputePeriod',
      _publishedAtTag,
      ..._promotedLetters,
    };
    final preserved = parsedTags.tags
        .where((t) => t.isNotEmpty && !stripKeys.contains(t.first))
        .toList();
    final updatedImages = images ?? this.images;
    final updatedImageMetas =
        imageMetas ?? _imageMetasForImages(updatedImages, this.imageMetas);

    return Listing(
      pubKey: pubKey ?? this.pubKey,
      createdAt: createdAt ?? this.createdAt,
      tags: ListingTags(
        (TagBuilder()
              ..addAll(preserved)
              ..add('title', title ?? this.title)
              ..addAll(_imageTags(updatedImages, updatedImageMetas))
              ..addIMetas(updatedImageMetas)
              ..add('t', 'accommodation')
              ..add(_publishedAtTag, firstPublishedAt.toString())
              ..addBool('active', active ?? this.active)
              ..addBool('negotiable', negotiable ?? this.negotiable)
              ..addInt('minStay', minStay ?? this.minStay)
              ..add('checkIn', checkIn ?? this.checkIn ?? '15:0')
              ..add('checkOut', checkOut ?? this.checkOut ?? '11:0')
              ..add('location', location ?? this.location)
              ..addInt('quantity', quantity ?? this.quantity)
              ..addEnum('type', type ?? this.listingType)
              ..addBool('instantBook', instantBook ?? this.instantBook)
              ..addBool('allowSelfSignedReservation',
                  allowSelfSignedReservation ?? this.allowSelfSignedReservation)
              ..addPrices(prices ?? this.prices)
              ..addCancellationPolicies(
                  cancellationPolicy ?? this.cancellationPolicy)
              ..addOptionalDenominatedAmount(
                  'securityDeposit',
                  clearSecurityDeposit
                      ? null
                      : securityDeposit ?? this.securityDeposit)
              ..addOptionalDenominatedAmount(
                  'minPaymentAmount',
                  clearMinPaymentAmount
                      ? null
                      : minPaymentAmount ?? this.minPaymentAmount)
              ..addOptionalInt(
                  'maxDisputePeriod',
                  clearMaxDisputePeriod
                      ? null
                      : maxDisputePeriod ??
                          tagSource.getTagInt('maxDisputePeriod'))
              ..addSpecifications(specifications ?? this.specifications)
              // Emit single-letter promoted duplicates for relay indexing.
              ..addAll(TagPromotion.promoteAll([
                ['type', (type ?? this.listingType).name],
                ['instantBook', (instantBook ?? this.instantBook).toString()],
                ['negotiable', (negotiable ?? this.negotiable).toString()],
                ...(specifications ?? this.specifications).toTags(),
              ], promotions))
              ..addAll(extraTags ?? const []))
            .build(),
      ),
      content: description ?? this.description,
    );
  }

  static List<List<String>> _imageTags(
    List<String> images,
    List<IMeta> imageMetas,
  ) {
    final metaByUrl = {
      for (final meta in imageMetas)
        if (meta.url.isNotEmpty) meta.url: meta,
    };
    return images
        .map((url) => metaByUrl[url]?.toImageTag() ?? ['image', url])
        .toList();
  }

  static List<IMeta> _imageMetasForImages(
    List<String> images,
    List<IMeta> existingMetas,
  ) {
    final urls = images.toSet();
    return existingMetas.where((meta) => urls.contains(meta.url)).toList();
  }

  /// Whether two date ranges overlap using **half-open interval** semantics.
  ///
  /// Ranges are treated as `[start, end)` — the end date is exclusive.
  /// This matches standard hospitality convention: checkout day equals the
  /// next guest's checkin day without conflict.
  ///
  /// All dates are normalized to UTC midnight before comparison.
  /// When `start == end` (single-day), the range is inflated to one day.
  static bool datesOverlap({
    required DateTime startA,
    required DateTime endA,
    required DateTime startB,
    required DateTime endB,
  }) {
    DateTime normalize(DateTime value) {
      return DateTime.utc(value.year, value.month, value.day);
    }

    var aStart = normalize(startA);
    var aEnd = normalize(endA);
    var bStart = normalize(startB);
    var bEnd = normalize(endB);

    // Swap if inverted.
    if (aEnd.isBefore(aStart)) {
      final temp = aStart;
      aStart = aEnd;
      aEnd = temp;
    }
    if (bEnd.isBefore(bStart)) {
      final temp = bStart;
      bStart = bEnd;
      bEnd = temp;
    }

    // Inflate single-day ranges to span one day.
    if (aEnd.isAtSameMomentAs(aStart)) aEnd = aEnd.add(Duration(days: 1));
    if (bEnd.isAtSameMomentAs(bStart)) bEnd = bEnd.add(Duration(days: 1));

    // Half-open overlap: [aStart, aEnd) ∩ [bStart, bEnd)
    return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
  }

  static bool isAvailable(
    DateTime start,
    DateTime end,
    List<ReservationGroup> reservationGroups,
  ) {
    for (final group in reservationGroups) {
      if (group.cancelled) continue;

      final pairStart = group.start;
      final pairEnd = group.end;
      if (pairStart == null || pairEnd == null) continue;

      if (datesOverlap(
        startA: start,
        endA: end,
        startB: pairStart,
        endB: pairEnd,
      )) {
        return false;
      }
    }
    return true;
  }

  /// Compute the cheapest cost across all listed prices.
  ///
  /// - **Recurring prices** (frequency != null) require [start] and [end] to
  ///   compute units × unit-price.
  /// - **One-time / fixed prices** (frequency == null) are taken as-is,
  ///   multiplied by [quantity].
  ///
  /// Prices that need dates but don't have them are skipped.
  DenominatedAmount cost({DateTime? start, DateTime? end, int quantity = 1}) {
    final costs = <DenominatedAmount>[];
    for (final p in prices) {
      if (p.frequency != null) {
        // Recurring – need date range
        if (start == null || end == null) continue;
        final units = end.difference(start).inDays.abs() /
            FrequencyInDays.of(p.frequency);
        costs.add(DenominatedAmount(
          value: BigInt.from(units) * p.amount.value,
          denomination: p.amount.denomination,
          decimals: p.amount.decimals,
        ));
      } else {
        // One-time / fixed – just amount × quantity
        costs.add(DenominatedAmount(
          value: p.amount.value * BigInt.from(quantity),
          denomination: p.amount.denomination,
          decimals: p.amount.decimals,
        ));
      }
    }
    if (costs.isEmpty) {
      // Fallback: return first price as-is
      final p = prices.first;
      return DenominatedAmount(
        value: p.amount.value * BigInt.from(quantity),
        denomination: p.amount.denomination,
        decimals: p.amount.decimals,
      );
    }
    costs.sort((a, b) => a.value.compareTo(b.value));
    return costs.first;
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() {
    return '$hour:$minute';
  }
}

class CancellationPolicy {
  final Duration durationBeforeStart;
  final double refundFraction;

  const CancellationPolicy({
    required this.durationBeforeStart,
    required this.refundFraction,
  })  : assert(refundFraction >= 0),
        assert(refundFraction <= 1);

  @override
  bool operator ==(Object other) {
    return other is CancellationPolicy &&
        other.durationBeforeStart == durationBeforeStart &&
        other.refundFraction == refundFraction;
  }

  @override
  int get hashCode => Object.hash(durationBeforeStart, refundFraction);
}

enum ListingType { room, house, apartment, villa, hotel, hostel, resort }

// ── Specifications (tag-backed) ─────────────────────────────────────────────

/// Listing specifications — boolean features and valued details.
///
/// Serialised as `["spec", "<name>"]` (boolean) or
/// `["spec", "<name>", "<value>"]` (valued) Nostr tags.
class Specifications {
  final Map<String, dynamic> _data;

  Specifications([Map<String, dynamic>? data]) : _data = data ?? {};

  /// Generic accessor – enables `specs['pool']`.
  dynamic operator [](String key) => _data[key];

  /// Generic setter – enables `specs['pool'] = true`.
  void operator []=(String key, dynamic value) => _data[key] = value;

  // ── Boolean getters ───────────────────────────────────────────────
  bool get airconditioning => _data['airconditioning'] == true;
  bool get allows_pets => _data['allows_pets'] == true;
  bool get crib => _data['crib'] == true;
  bool get tumble_dryer => _data['tumble_dryer'] == true;
  bool get washer => _data['washer'] == true;
  bool get elevator => _data['elevator'] == true;
  bool get free_parking => _data['free_parking'] == true;
  bool get gym => _data['gym'] == true;
  bool get hair_dryer => _data['hair_dryer'] == true;
  bool get heating => _data['heating'] == true;
  bool get high_chair => _data['high_chair'] == true;
  bool get wireless_internet => _data['wireless_internet'] == true;
  bool get iron => _data['iron'] == true;
  bool get jacuzzi => _data['jacuzzi'] == true;
  bool get kitchen => _data['kitchen'] == true;
  bool get outlet_covers => _data['outlet_covers'] == true;
  bool get pool => _data['pool'] == true;
  bool get private_entrance => _data['private_entrance'] == true;
  bool get smoking_allowed => _data['smoking_allowed'] == true;
  bool get breakfast => _data['breakfast'] == true;
  bool get fireplace => _data['fireplace'] == true;
  bool get smoke_detector => _data['smoke_detector'] == true;
  bool get essentials => _data['essentials'] == true;
  bool get shampoo => _data['shampoo'] == true;
  bool get infants_allowed => _data['infants_allowed'] == true;
  bool get children_allowed => _data['children_allowed'] == true;
  bool get hangers => _data['hangers'] == true;
  bool get flat_smooth_pathway_to_front_door =>
      _data['flat_smooth_pathway_to_front_door'] == true;
  bool get grab_rails_in_shower_and_toilet =>
      _data['grab_rails_in_shower_and_toilet'] == true;
  bool get oven => _data['oven'] == true;
  bool get bbq => _data['bbq'] == true;
  bool get balcony => _data['balcony'] == true;
  bool get patio => _data['patio'] == true;
  bool get dishwasher => _data['dishwasher'] == true;
  bool get refrigerator => _data['refrigerator'] == true;
  bool get garden_or_backyard => _data['garden_or_backyard'] == true;
  bool get microwave => _data['microwave'] == true;
  bool get coffee_maker => _data['coffee_maker'] == true;
  bool get dishes_and_silverware => _data['dishes_and_silverware'] == true;
  bool get stove => _data['stove'] == true;
  bool get fire_extinguisher => _data['fire_extinguisher'] == true;
  bool get carbon_monoxide_detector =>
      _data['carbon_monoxide_detector'] == true;
  bool get luggage_dropoff_allowed => _data['luggage_dropoff_allowed'] == true;
  bool get beach_essentials => _data['beach_essentials'] == true;
  bool get beachfront => _data['beachfront'] == true;
  bool get baby_monitor => _data['baby_monitor'] == true;
  bool get babysitter_recommendations =>
      _data['babysitter_recommendations'] == true;
  bool get childrens_books_and_toys =>
      _data['childrens_books_and_toys'] == true;
  bool get game_console => _data['game_console'] == true;
  bool get street_parking => _data['street_parking'] == true;
  bool get paid_parking => _data['paid_parking'] == true;
  bool get hot_water => _data['hot_water'] == true;
  bool get lake_access => _data['lake_access'] == true;
  bool get single_level_home => _data['single_level_home'] == true;
  bool get waterfront => _data['waterfront'] == true;
  bool get first_aid_kit => _data['first_aid_kit'] == true;
  bool get handheld_shower_head => _data['handheld_shower_head'] == true;
  bool get home_step_free_access => _data['home_step_free_access'] == true;
  bool get lock_on_bedroom_door => _data['lock_on_bedroom_door'] == true;
  bool get mobile_hoist => _data['mobile_hoist'] == true;
  bool get path_to_entrance_lit_at_night =>
      _data['path_to_entrance_lit_at_night'] == true;
  bool get pool_hoist => _data['pool_hoist'] == true;
  bool get ev_charger => _data['ev_charger'] == true;
  bool get rollin_shower => _data['rollin_shower'] == true;
  bool get shower_chair => _data['shower_chair'] == true;
  bool get tub_with_shower_bench => _data['tub_with_shower_bench'] == true;
  bool get wide_clearance_to_bed => _data['wide_clearance_to_bed'] == true;
  bool get wide_clearance_to_shower_and_toilet =>
      _data['wide_clearance_to_shower_and_toilet'] == true;
  bool get wide_hallway_clearance => _data['wide_hallway_clearance'] == true;
  bool get baby_bath => _data['baby_bath'] == true;
  bool get changing_table => _data['changing_table'] == true;
  bool get room_darkening_shades => _data['room_darkening_shades'] == true;
  bool get stair_gates => _data['stair_gates'] == true;
  bool get table_corner_guards => _data['table_corner_guards'] == true;
  bool get extra_pillows_and_blankets =>
      _data['extra_pillows_and_blankets'] == true;
  bool get ski_in_ski_out => _data['ski_in_ski_out'] == true;
  bool get window_guards => _data['window_guards'] == true;
  bool get disabled_parking_spot => _data['disabled_parking_spot'] == true;
  bool get grab_rails_in_toilet => _data['grab_rails_in_toilet'] == true;
  bool get events_allowed => _data['events_allowed'] == true;
  bool get common_spaces_shared => _data['common_spaces_shared'] == true;
  bool get bathroom_shared => _data['bathroom_shared'] == true;
  bool get security_cameras => _data['security_cameras'] == true;

  // ── Numeric getters ───────────────────────────────────────────────
  int get bathtub => (_data['bathtub'] as int?) ?? 0;
  int get bathrooms => (_data['bathrooms'] as int?) ?? 0;
  int get beds => (_data['beds'] as int?) ?? 0;
  int get bedrooms => (_data['bedrooms'] as int?) ?? 0;
  int get max_guests => (_data['max_guests'] as int?) ?? 0;
  int get tv => (_data['tv'] as int?) ?? 0;

  // ── Construct from tags ───────────────────────────────────────────
  static Specifications fromTags(List<List<String>> tags) {
    final map = <String, dynamic>{};
    // Parse both 'spec' (current) and 'amenity' (legacy) tags.
    for (final tag in tags
        .where((t) => t.isNotEmpty && (t[0] == 'spec' || t[0] == 'amenity'))) {
      if (tag.length == 2) {
        map[tag[1]] = true;
      } else if (tag.length >= 3) {
        map[tag[1]] = int.tryParse(tag[2]) ?? tag[2];
      }
    }
    return Specifications(map);
  }

  // ── Serialize to tags ─────────────────────────────────────────────
  List<List<String>> toTags() {
    return _data.entries.expand((e) {
      if (e.value == true)
        return [
          ['spec', e.key]
        ];
      if (e.value is int && (e.value as int) > 0) {
        return [
          ['spec', e.key, '${e.value}']
        ];
      }
      return <List<String>>[];
    }).toList();
  }

  // ── Legacy compat: toMap / fromJSON (used by UI forms) ────────────
  static Specifications fromJSON(Map<String, dynamic> json) {
    return Specifications(Map<String, dynamic>.from(json));
  }

  Map<String, dynamic> toMap() {
    // Return a full map with defaults for all known keys
    return {
      'airconditioning': airconditioning,
      'allows_pets': allows_pets,
      'bathrooms': bathrooms,
      'bathtub': bathtub,
      'beds': beds,
      'bedrooms': bedrooms,
      'max_guests': max_guests,
      'tv': tv,
      'crib': crib,
      'tumble_dryer': tumble_dryer,
      'washer': washer,
      'elevator': elevator,
      'free_parking': free_parking,
      'gym': gym,
      'hair_dryer': hair_dryer,
      'heating': heating,
      'high_chair': high_chair,
      'wireless_internet': wireless_internet,
      'iron': iron,
      'jacuzzi': jacuzzi,
      'kitchen': kitchen,
      'outlet_covers': outlet_covers,
      'pool': pool,
      'private_entrance': private_entrance,
      'smoking_allowed': smoking_allowed,
      'breakfast': breakfast,
      'fireplace': fireplace,
      'smoke_detector': smoke_detector,
      'essentials': essentials,
      'shampoo': shampoo,
      'infants_allowed': infants_allowed,
      'children_allowed': children_allowed,
      'hangers': hangers,
      'flat_smooth_pathway_to_front_door': flat_smooth_pathway_to_front_door,
      'grab_rails_in_shower_and_toilet': grab_rails_in_shower_and_toilet,
      'oven': oven,
      'bbq': bbq,
      'balcony': balcony,
      'patio': patio,
      'dishwasher': dishwasher,
      'refrigerator': refrigerator,
      'garden_or_backyard': garden_or_backyard,
      'microwave': microwave,
      'coffee_maker': coffee_maker,
      'dishes_and_silverware': dishes_and_silverware,
      'stove': stove,
      'fire_extinguisher': fire_extinguisher,
      'carbon_monoxide_detector': carbon_monoxide_detector,
      'luggage_dropoff_allowed': luggage_dropoff_allowed,
      'beach_essentials': beach_essentials,
      'beachfront': beachfront,
      'baby_monitor': baby_monitor,
      'babysitter_recommendations': babysitter_recommendations,
      'childrens_books_and_toys': childrens_books_and_toys,
      'game_console': game_console,
      'street_parking': street_parking,
      'paid_parking': paid_parking,
      'hot_water': hot_water,
      'lake_access': lake_access,
      'single_level_home': single_level_home,
      'waterfront': waterfront,
      'first_aid_kit': first_aid_kit,
      'handheld_shower_head': handheld_shower_head,
      'home_step_free_access': home_step_free_access,
      'lock_on_bedroom_door': lock_on_bedroom_door,
      'mobile_hoist': mobile_hoist,
      'path_to_entrance_lit_at_night': path_to_entrance_lit_at_night,
      'pool_hoist': pool_hoist,
      'ev_charger': ev_charger,
      'rollin_shower': rollin_shower,
      'shower_chair': shower_chair,
      'tub_with_shower_bench': tub_with_shower_bench,
      'wide_clearance_to_bed': wide_clearance_to_bed,
      'wide_clearance_to_shower_and_toilet':
          wide_clearance_to_shower_and_toilet,
      'wide_hallway_clearance': wide_hallway_clearance,
      'baby_bath': baby_bath,
      'changing_table': changing_table,
      'room_darkening_shades': room_darkening_shades,
      'stair_gates': stair_gates,
      'table_corner_guards': table_corner_guards,
      'extra_pillows_and_blankets': extra_pillows_and_blankets,
      'ski_in_ski_out': ski_in_ski_out,
      'window_guards': window_guards,
      'disabled_parking_spot': disabled_parking_spot,
      'grab_rails_in_toilet': grab_rails_in_toilet,
      'events_allowed': events_allowed,
      'common_spaces_shared': common_spaces_shared,
      'bathroom_shared': bathroom_shared,
      'security_cameras': security_cameras,
    };
  }
}

/// Backwards-compatible alias.
@Deprecated('Use Specifications instead')
typedef Amenities = Specifications;
