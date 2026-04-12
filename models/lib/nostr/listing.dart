import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

// ── Tag-read mixin ──────────────────────────────────────────────────────────
// Defines all tag-promoted field getters ONCE. Mixed into both ListingTags
// and Listing so callers can use either `listing.allowBarter` or
// `listing.parsedTags.allowBarter`.

mixin ListingTagRead {
  EventTags get tagSource;

  // ── NIP-99 tag-promoted fields ────────────────────────────────────
  String get title => tagSource.getTagValue('title') ?? '';
  List<String> get images => tagSource.getTags('image');

  bool get active => tagSource.getTagBool('active', defaultValue: true);
  bool get allowBarter => tagSource.getTagBool('allowBarter');
  int get minStay => tagSource.getTagInt('minStay') ?? 1;
  String? get checkIn => tagSource.getTagValue('checkIn');
  String? get checkOut => tagSource.getTagValue('checkOut');
  String get location => tagSource.getTagValue('location') ?? '';
  int get quantity => tagSource.getTagInt('quantity') ?? 1;
  ListingType get listingType =>
      tagSource.getTagEnum('type', ListingType.values) ?? ListingType.room;
  bool get requiresEscrow => tagSource.getTagBool('requiresEscrow');
  bool get allowSelfSignedReservation =>
      tagSource.getTagBool('allowSelfSignedReservation');
  List<Price> get prices => tagSource.getTagPrices();
  List<CancellationPolicy> get cancellationPolicies =>
      tagSource.getTagCancellationPolicies();
  List<CancellationPolicy> get cancellationPolicy => cancellationPolicies;
  Amenities get amenities => Amenities.fromTags(tagSource.tags);

  /// Optional security deposit that the guest must lock alongside the
  /// payment amount. Stored as `['securityDeposit', amount, denomination, decimals]`.
  DenominatedAmount? get securityDeposit =>
      tagSource.getTagDenominatedAmount('securityDeposit');
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
    // Tag fields (searchable)
    required List<Price> price,
    required String location,
    required ListingType type,
    required Amenities amenities,
    bool active = true,
    bool allowBarter = false,
    int minStay = 1,
    String checkIn = '15:0',
    String checkOut = '11:0',
    int quantity = 1,
    bool requiresEscrow = false,
    bool allowSelfSignedReservation = false,
    List<CancellationPolicy> cancellationPolicy = const [],
    DenominatedAmount? securityDeposit,
    List<List<String>> extraTags = const [],
    int? createdAt,
  }) {
    return Listing(
      pubKey: pubKey,
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: ListingTags(
        (TagBuilder()
              ..add('d', dTag)
              ..add('title', title)
              ..addImages(images)
              ..add('t', 'accommodation')
              ..addBool('active', active)
              ..addBool('allowBarter', allowBarter)
              ..addInt('minStay', minStay)
              ..add('checkIn', checkIn)
              ..add('checkOut', checkOut)
              ..add('location', location)
              ..addInt('quantity', quantity)
              ..addEnum('type', type)
              ..addBool('requiresEscrow', requiresEscrow)
              ..addBool(
                  'allowSelfSignedReservation', allowSelfSignedReservation)
              ..addPrices(price)
              ..addCancellationPolicies(cancellationPolicy)
              ..addOptionalDenominatedAmount('securityDeposit', securityDeposit)
              ..addAmenities(amenities)
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
    bool? allowBarter,
    int? minStay,
    String? checkIn,
    String? checkOut,
    String? location,
    int? quantity,
    ListingType? type,
    bool? requiresEscrow,
    bool? allowSelfSignedReservation,
    List<Price>? prices,
    List<CancellationPolicy>? cancellationPolicy,
    Amenities? amenities,
    DenominatedAmount? securityDeposit,
    bool clearSecurityDeposit = false,
    // Content fields
    String? title,
    String? description,
    List<String>? images,
    // Event-level
    String? pubKey,
    int? createdAt,
    List<List<String>>? extraTags,
  }) {
    // Preserve non-promoted tags (d, g, etc.)
    final preserved = parsedTags.tags
        .where((t) =>
            t.isNotEmpty &&
            !const {
              'title',
              'image',
              't',
              'active',
              'allowBarter',
              'minStay',
              'checkIn',
              'checkOut',
              'location',
              'quantity',
              'type',
              'requiresEscrow',
              'allowSelfSignedReservation',
              'price',
              'cancellationPolicy',
              'amenity',
              'securityDeposit',
            }.contains(t.first))
        .toList();

    return Listing(
      pubKey: pubKey ?? this.pubKey,
      createdAt: createdAt ?? this.createdAt,
      tags: ListingTags(
        (TagBuilder()
              ..addAll(preserved)
              ..add('title', title ?? this.title)
              ..addImages(images ?? this.images)
              ..add('t', 'accommodation')
              ..addBool('active', active ?? this.active)
              ..addBool('allowBarter', allowBarter ?? this.allowBarter)
              ..addInt('minStay', minStay ?? this.minStay)
              ..add('checkIn', checkIn ?? this.checkIn ?? '15:0')
              ..add('checkOut', checkOut ?? this.checkOut ?? '11:0')
              ..add('location', location ?? this.location)
              ..addInt('quantity', quantity ?? this.quantity)
              ..addEnum('type', type ?? this.listingType)
              ..addBool('requiresEscrow', requiresEscrow ?? this.requiresEscrow)
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
              ..addAmenities(amenities ?? this.amenities)
              ..addAll(extraTags ?? const []))
            .build(),
      ),
      content: description ?? this.description,
    );
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

// ── Amenities (tag-backed) ──────────────────────────────────────────────────

class Amenities {
  final Map<String, dynamic> _data;

  Amenities([Map<String, dynamic>? data]) : _data = data ?? {};

  /// Generic setter – enables `amenities['pool'] = true`.
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
  int get beds => (_data['beds'] as int?) ?? 0;
  int get bedrooms => (_data['bedrooms'] as int?) ?? 0;
  int get tv => (_data['tv'] as int?) ?? 0;

  // ── Construct from tags ───────────────────────────────────────────
  static Amenities fromTags(List<List<String>> tags) {
    final map = <String, dynamic>{};
    for (final tag in tags.where((t) => t.isNotEmpty && t[0] == 'amenity')) {
      if (tag.length == 2) {
        map[tag[1]] = true;
      } else if (tag.length >= 3) {
        map[tag[1]] = int.tryParse(tag[2]) ?? tag[2];
      }
    }
    return Amenities(map);
  }

  // ── Serialize to tags ─────────────────────────────────────────────
  List<List<String>> toTags() {
    return _data.entries.expand((e) {
      if (e.value == true)
        return [
          ['amenity', e.key]
        ];
      if (e.value is int && (e.value as int) > 0) {
        return [
          ['amenity', e.key, '${e.value}']
        ];
      }
      return <List<String>>[];
    }).toList();
  }

  // ── Legacy compat: toMap / fromJSON (used by UI forms) ────────────
  static Amenities fromJSON(Map<String, dynamic> json) {
    return Amenities(Map<String, dynamic>.from(json));
  }

  Map<String, dynamic> toMap() {
    // Return a full map with defaults for all known keys
    return {
      'airconditioning': airconditioning,
      'allows_pets': allows_pets,
      'bathtub': bathtub,
      'beds': beds,
      'bedrooms': bedrooms,
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
