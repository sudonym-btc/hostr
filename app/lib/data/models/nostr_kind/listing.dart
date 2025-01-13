import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';

import '../amount.dart';
import '../price.dart';
import 'reservation.dart';
import 'type_json_content.dart';

class Listing extends JsonContentNostrEvent<ListingContent> {
  static const List<int> kinds = [NOSTR_KIND_LISTING];

  Listing.fromNostrEvent(NostrEvent e)
      : super(
            parsedContent: ListingContent.fromJson(json.decode(e.content!)),
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);

  static isAvailable(DateTimeRange requested, List<Reservation> reservations) {
    for (Reservation r in reservations) {
      if (requested.start.isBefore(r.parsedContent.end) &&
          requested.end.isAfter(r.parsedContent.start)) {
        return false;
      }
    }
    return true;
  }

// Currently can only compare prices of the same currency
  Amount cost(DateTimeRange requested) {
    // Loop through prices and choose the cheepest result
    List<Amount> costs = parsedContent.price
        .map((p) => Amount(
            value:
                (requested.duration.inDays / FrequencyInDays.of(p.frequency)) *
                    p.amount.value,
            currency: p.amount.currency))
        .toList();
    costs.sort((a, b) => a.value.compareTo(b.value));
    return costs.first;
  }
}

class ListingContent extends EventContent {
  final String title;
  final String description;
  final List<Price> price;
  final bool allowBarter;
  final Duration minStay;
  final TimeOfDay checkIn;
  final TimeOfDay checkOut;
  final String location;
  final int quantity;
  final ListingType type;
  final List<String> images;
  final Amenities amenities;

  ListingContent(
      {required this.title,
      required this.description,
      required this.price,
      this.allowBarter = false,
      required this.minStay,
      required this.checkIn,
      required this.checkOut,
      required this.location,
      required this.quantity,
      required this.type,
      required this.images,
      required this.amenities});

  @override
  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "description": description,
      "price": price.map((e) => e.toJson()).toList(),
      "allowBarter": allowBarter,
      "minStay": minStay.inDays,
      "checkIn": '${checkIn.hour}:${checkIn.minute}',
      "checkOut": '${checkOut.hour}:${checkOut.minute}',
      "location": location,
      "quantity": quantity,
      "type": type.toString().split('.').last,
      "images": images,
      "amenities": amenities.toMap(),
    };
  }

  static ListingContent fromJson(Map<String, dynamic> json) {
    return ListingContent(
      title: json["title"],
      description: json["description"],
      price: (json["price"] as List).map((e) => Price.fromJson(e)).toList(),
      allowBarter: json["allowBarter"],
      minStay: Duration(days: json["minStay"]),
      checkIn: TimeOfDay(
          hour: int.parse(json["checkIn"].split(':')[0]),
          minute: int.parse(json["checkIn"].split(':')[1])),
      checkOut: TimeOfDay(
          hour: int.parse(json["checkOut"].split(':')[0]),
          minute: int.parse(json["checkOut"].split(':')[1])),
      location: json["location"],
      quantity: json["quantity"],
      type: ListingType.values
          .firstWhere((e) => e.toString() == 'ListingType.${json["type"]}'),
      images: List<String>.from(json["images"]),
      amenities: Amenities.fromJSON(json["amenities"]),
    );
  }
}

enum ListingType { room, house, apartment, villa, hotel, hostel, resort }

class Amenities {
  bool airconditioning = false;
  bool allows_pets = false;
  int bathtub = 0;
  int beds = 0;
  int bedrooms = 0;
  int tv = 0;
  bool crib = false;
  bool tumble_dryer = false;
  bool washer = false;
  bool elevator = false;
  bool free_parking = false;
  bool gym = false;
  bool hair_dryer = false;
  bool heating = false;
  bool high_chair = false;
  bool wireless_internet = false;
  bool iron = false;
  bool jacuzzi = false;
  bool kitchen = false;
  bool outlet_covers = false;
  bool pool = false;
  bool private_entrance = false;
  bool smoking_allowed = false;
  bool breakfast = false;
  bool fireplace = false;
  bool smoke_detector = false;
  bool essentials = false;
  bool shampoo = false;
  bool infants_allowed = false;
  bool children_allowed = false;
  bool hangers = false;
  bool flat_smooth_pathway_to_front_door = false;
  bool grab_rails_in_shower_and_toilet = false;
  bool oven = false;
  bool bbq = false;
  bool balcony = false;
  bool patio = false;
  bool dishwasher = false;
  bool refrigerator = false;
  bool garden_or_backyard = false;
  bool microwave = false;
  bool coffee_maker = false;
  bool dishes_and_silverware = false;
  bool stove = false;
  bool fire_extinguisher = false;
  bool carbon_monoxide_detector = false;
  bool luggage_dropoff_allowed = false;
  bool beach_essentials = false;
  bool beachfront = false;
  bool baby_monitor = false;
  bool babysitter_recommendations = false;
  bool childrens_books_and_toys = false;
  bool game_console = false;
  bool street_parking = false;
  bool paid_parking = false;
  bool hot_water = false;
  bool lake_access = false;
  bool single_level_home = false;
  bool waterfront = false;
  bool first_aid_kit = false;
  bool handheld_shower_head = false;
  bool home_step_free_access = false;
  bool lock_on_bedroom_door = false;
  bool mobile_hoist = false;
  bool path_to_entrance_lit_at_night = false;
  bool pool_hoist = false;
  bool ev_charger = false;
  bool rollin_shower = false;
  bool shower_chair = false;
  bool tub_with_shower_bench = false;
  bool wide_clearance_to_bed = false;
  bool wide_clearance_to_shower_and_toilet = false;
  bool wide_hallway_clearance = false;
  bool baby_bath = false;
  bool changing_table = false;
  bool room_darkening_shades = false;
  bool stair_gates = false;
  bool table_corner_guards = false;
  bool extra_pillows_and_blankets = false;
  bool ski_in_ski_out = false;
  bool window_guards = false;
  bool disabled_parking_spot = false;
  bool grab_rails_in_toilet = false;
  bool events_allowed = false;
  bool common_spaces_shared = false;
  bool bathroom_shared = false;
  bool security_cameras = false;

  static fromJSON(Map<String, dynamic> json) {
    Amenities i = Amenities();

    i.airconditioning = json['airconditioning'] ?? false;
    i.allows_pets = json['allows_pets'] ?? false;
    i.bathtub = json['bathtub'] ?? 0;
    i.beds = json['beds'] ?? 0;
    i.bedrooms = json['bedrooms'] ?? 0;
    i.tv = json['tv'] ?? 0;
    i.crib = json['crib'] ?? false;
    i.tumble_dryer = json['tumble_dryer'] ?? false;
    i.washer = json['washer'] ?? false;
    i.elevator = json['elevator'] ?? false;
    i.free_parking = json['free_parking'] ?? false;
    i.gym = json['gym'] ?? false;
    i.hair_dryer = json['hair_dryer'] ?? false;
    i.heating = json['heating'] ?? false;
    i.high_chair = json['high_chair'] ?? false;
    i.wireless_internet = json['wireless_internet'] ?? false;
    i.iron = json['iron'] ?? false;
    i.jacuzzi = json['jacuzzi'] ?? false;
    i.kitchen = json['kitchen'] ?? false;
    i.outlet_covers = json['outlet_covers'] ?? false;
    i.pool = json['pool'] ?? false;
    i.private_entrance = json['private_entrance'] ?? false;
    i.smoking_allowed = json['smoking_allowed'] ?? false;
    i.breakfast = json['breakfast'] ?? false;
    i.fireplace = json['fireplace'] ?? false;
    i.smoke_detector = json['smoke_detector'] ?? false;
    i.essentials = json['essentials'] ?? false;
    i.shampoo = json['shampoo'] ?? false;
    i.infants_allowed = json['infants_allowed'] ?? false;
    i.children_allowed = json['children_allowed'] ?? false;
    i.hangers = json['hangers'] ?? false;
    i.flat_smooth_pathway_to_front_door =
        json['flat_smooth_pathway_to_front_door'] ?? false;
    i.grab_rails_in_shower_and_toilet =
        json['grab_rails_in_shower_and_toilet'] ?? false;
    i.oven = json['oven'] ?? false;
    i.bbq = json['bbq'] ?? false;
    i.balcony = json['balcony'] ?? false;
    i.patio = json['patio'] ?? false;
    i.dishwasher = json['dishwasher'] ?? false;
    i.refrigerator = json['refrigerator'] ?? false;
    i.garden_or_backyard = json['garden_or_backyard'] ?? false;
    i.microwave = json['microwave'] ?? false;
    i.coffee_maker = json['coffee_maker'] ?? false;
    i.dishes_and_silverware = json['dishes_and_silverware'] ?? false;
    i.stove = json['stove'] ?? false;
    i.fire_extinguisher = json['fire_extinguisher'] ?? false;
    i.carbon_monoxide_detector = json['carbon_monoxide_detector'] ?? false;
    i.luggage_dropoff_allowed = json['luggage_dropoff_allowed'] ?? false;
    i.beach_essentials = json['beach_essentials'] ?? false;
    i.beachfront = json['beachfront'] ?? false;
    i.baby_monitor = json['baby_monitor'] ?? false;
    i.babysitter_recommendations = json['babysitter_recommendations'] ?? false;
    i.childrens_books_and_toys = json['childrens_books_and_toys'] ?? false;
    i.game_console = json['game_console'] ?? false;
    i.street_parking = json['street_parking'] ?? false;
    i.paid_parking = json['paid_parking'] ?? false;
    i.hot_water = json['hot_water'] ?? false;
    i.lake_access = json['lake_access'] ?? false;
    i.single_level_home = json['single_level_home'] ?? false;
    i.waterfront = json['waterfront'] ?? false;
    i.first_aid_kit = json['first_aid_kit'] ?? false;
    i.handheld_shower_head = json['handheld_shower_head'] ?? false;
    i.home_step_free_access = json['home_step_free_access'] ?? false;
    i.lock_on_bedroom_door = json['lock_on_bedroom_door'] ?? false;
    i.mobile_hoist = json['mobile_hoist'] ?? false;
    i.path_to_entrance_lit_at_night =
        json['path_to_entrance_lit_at_night'] ?? false;
    i.pool_hoist = json['pool_hoist'] ?? false;
    i.ev_charger = json['ev_charger'] ?? false;
    i.rollin_shower = json['rollin_shower'] ?? false;
    i.shower_chair = json['shower_chair'] ?? false;
    i.tub_with_shower_bench = json['tub_with_shower_bench'] ?? false;
    i.wide_clearance_to_bed = json['wide_clearance_to_bed'] ?? false;
    i.wide_clearance_to_shower_and_toilet =
        json['wide_clearance_to_shower_and_toilet'] ?? false;
    i.wide_hallway_clearance = json['wide_hallway_clearance'] ?? false;
    i.baby_bath = json['baby_bath'] ?? false;
    i.changing_table = json['changing_table'] ?? false;
    i.room_darkening_shades = json['room_darkening_shades'] ?? false;
    i.stair_gates = json['stair_gates'] ?? false;
    i.table_corner_guards = json['table_corner_guards'] ?? false;
    i.extra_pillows_and_blankets = json['extra_pillows_and_blankets'] ?? false;
    i.ski_in_ski_out = json['ski_in_ski_out'] ?? false;
    i.window_guards = json['window_guards'] ?? false;
    i.disabled_parking_spot = json['disabled_parking_spot'] ?? false;
    i.grab_rails_in_toilet = json['grab_rails_in_toilet'] ?? false;
    i.events_allowed = json['events_allowed'] ?? false;
    i.common_spaces_shared = json['common_spaces_shared'] ?? false;
    i.bathroom_shared = json['bathroom_shared'] ?? false;
    i.security_cameras = json['security_cameras'] ?? false;

    return i;
  }

  Map<String, dynamic> toMap() {
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
