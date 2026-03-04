import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

// ── Tag-read mixin ──────────────────────────────────────────────────────────
// Defines all tag-promoted field getters ONCE. Mixed into both ListingTags
// and Listing so callers can use either `listing.allowBarter` or
// `listing.parsedTags.allowBarter`.

mixin ListingTagRead {
  EventTags get tagSource;

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
  Amenities get amenities => Amenities.fromTags(tagSource.tags);
}

// ── Tags class ──────────────────────────────────────────────────────────────

class ListingTags extends EventTags with ListingTagRead {
  ListingTags(super.tags);

  @override
  EventTags get tagSource => this;
}

// ── Event class ─────────────────────────────────────────────────────────────

class Listing extends JsonContentNostrEvent<ListingContent, ListingTags>
    with ListingTagRead {
  static const List<int> kinds = [kNostrKindListing];
  static final EventTagsParser<ListingTags> _tagParser = ListingTags.new;
  static final EventContentParser<ListingContent> _contentParser =
      ListingContent.fromJson;

  @override
  EventTags get tagSource => parsedTags;

  // ── Content-only convenience getters ────────────────────────────────
  String get title => parsedContent.title;
  String get description => parsedContent.description;
  List<String> get images => parsedContent.images;

  Listing(
      {required super.pubKey,
      required super.tags,
      required super.content,
      super.createdAt,
      super.id,
      super.sig})
      : super(
            kind: kNostrKindListing,
            tagParser: _tagParser,
            contentParser: _contentParser);

  Listing.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          contentParser: _contentParser,
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
    bool allowBarter = false,
    int minStay = 1,
    String checkIn = '15:0',
    String checkOut = '11:0',
    int quantity = 1,
    bool requiresEscrow = false,
    bool allowSelfSignedReservation = false,
    List<List<String>> extraTags = const [],
    int? createdAt,
  }) {
    return Listing(
      pubKey: pubKey,
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: ListingTags(
        (TagBuilder()
              ..add('d', dTag)
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
              ..addAmenities(amenities)
              ..addAll(extraTags))
            .build(),
      ),
      content: ListingContent(
        title: title,
        description: description,
        images: images,
      ),
    );
  }

  // ── Copy-with ───────────────────────────────────────────────────────
  Listing rebuild({
    // Tag fields
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
    Amenities? amenities,
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
              'amenity',
            }.contains(t.first))
        .toList();

    return Listing(
      pubKey: pubKey ?? this.pubKey,
      createdAt: createdAt ?? this.createdAt,
      tags: ListingTags(
        (TagBuilder()
              ..addAll(preserved)
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
              ..addAmenities(amenities ?? this.amenities)
              ..addAll(extraTags ?? const []))
            .build(),
      ),
      content: ListingContent(
        title: title ?? this.title,
        description: description ?? this.description,
        images: images ?? this.images,
      ),
    );
  }

  static bool isAvailable(
    DateTime start,
    DateTime end,
    List<ReservationPairStatus> reservationPairs,
  ) {
    DateTime normalize(DateTime value) {
      return DateTime(value.year, value.month, value.day);
    }

    var normalizedStart = normalize(start);
    var normalizedEnd = normalize(end);

    if (normalizedEnd.isBefore(normalizedStart)) {
      final temp = normalizedStart;
      normalizedStart = normalizedEnd;
      normalizedEnd = temp;
    }

    final effectiveEnd = normalizedEnd.isAtSameMomentAs(normalizedStart)
        ? normalizedEnd.add(Duration(days: 1))
        : normalizedEnd;

    for (final pair in reservationPairs) {
      if (pair.cancelled) {
        continue;
      }

      final pairStartValue = pair.start;
      final pairEndValue = pair.end;
      if (pairStartValue == null || pairEndValue == null) {
        continue;
      }

      final reservationStart = normalize(pairStartValue);
      final reservationEnd = normalize(pairEndValue);

      final overlaps = normalizedStart.isBefore(reservationEnd) &&
          effectiveEnd.isAfter(reservationStart);
      if (overlaps) {
        return false;
      }
    }
    return true;
  }

  // Currently can only compare prices of the same currency
  Amount cost(DateTime start, DateTime end) {
    // Loop through prices and choose the cheapest result
    List<Amount> costs = prices
        .map((p) => Amount(
            value: BigInt.from(end.difference(start).inDays.abs() /
                    FrequencyInDays.of(p.frequency)) *
                p.amount.value,
            currency: p.amount.currency))
        .toList();
    costs.sort((a, b) => a.value.compareTo(b.value));
    return costs.first;
  }
}

// ── Content (non-searchable fields only) ────────────────────────────────────

class ListingContent extends EventContent {
  final String title;
  final String description;
  final List<String> images;

  ListingContent({
    required this.title,
    required this.description,
    required this.images,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "description": description,
      "images": images,
    };
  }

  static ListingContent fromJson(Map<String, dynamic> json) {
    return ListingContent(
      title: json["title"] ?? '',
      description: json["description"] ?? '',
      images: json["images"] != null ? List<String>.from(json["images"]) : [],
    );
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
