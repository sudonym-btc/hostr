import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/models/price.dart';

import '../models/amount.dart';
import '../models/nostr_kind/listing.dart';
import 'keypairs.dart';

NostrKeyPairs keyPairs = NostrKeyPairs.generate();

var MOCK_LISTINGS = [
  Listing.fromNostrEvent(NostrEvent.fromPartialData(
      keyPairs: MockKeys.hoster,
      content: json.encode(ListingContent(
              description: """
A cozy, rustic cabin nestled in the woods. Perfect for a quiet retreat or a family vacation. Enjoy the serene surroundings and the beautiful nature trails. Close to local attractions and amenities.
The space
Charming cabin with a fully equipped kitchen, comfortable living area, and a spacious deck. Ideal for relaxing and enjoying the outdoors.
Guest access
Guests have access to the entire cabin and surrounding property.
Other things to note
The cabin is pet-friendly, but please keep an eye on your pets as the area is home to various wildlife.
""",
              price: [
                Price(
                    amount: Amount(value: 0.002, currency: Currency.BTC),
                    frequency: Frequency.daily)
              ], // 0.002 per day
              minStay: Duration(days: 2), // 2 days min stay
              checkIn: TimeOfDay(hour: 14, minute: 0),
              checkOut: TimeOfDay(hour: 11, minute: 0),
              location: '123 Forest Lane, Woodland',
              quantity: 1,
              images: [
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/2eecc731-6e8e-49c4-963a-2c9284c11900.jpeg?im_w=1200&im_format=avif',
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/3319ee8d-7f5f-4976-a936-cc74a7feb0c9.jpeg?im_w=720&im_format=avif',
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/ab1a5cdf-698f-4670-9088-1f2d08065f36.jpeg?im_w=720&im_format=avif',
                'https://a0.muscache.com/im/pictures/24c2d7ed-bf13-4050-aa3c-8dffd24b07e5.jpg?im_w=720&im_format=avif'
              ],
              type: ListingType.hostel,
              amenities:
                  Amenities.fromJSON({'wireless_internet': true, 'bbq': true}))
          .toJson()),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_LISTING,
      tags: [])),
  Listing.fromNostrEvent(NostrEvent.fromPartialData(
      keyPairs: MockKeys.hoster,
      content: json.encode(ListingContent(
              description: """
A cozy, rustic cabin nestled in the woods. Perfect for a quiet retreat or a family vacation. Enjoy the serene surroundings and the beautiful nature trails. Close to local attractions and amenities.
The space
Charming cabin with a fully equipped kitchen, comfortable living area, and a spacious deck. Ideal for relaxing and enjoying the outdoors.
Guest access
Guests have access to the entire cabin and surrounding property.
Other things to note
The cabin is pet-friendly, but please keep an eye on your pets as the area is home to various wildlife.
""",
              price: [
                Price(
                    amount: Amount(value: 0.002, currency: Currency.BTC),
                    frequency: Frequency.daily)
              ], // 0.002 per day
              minStay: Duration(days: 2), // 2 days min stay
              checkIn: TimeOfDay(hour: 14, minute: 0),
              checkOut: TimeOfDay(hour: 11, minute: 0),
              location: '123 Forest Lane, Woodland',
              quantity: 1,
              images: [
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/2eecc731-6e8e-49c4-963a-2c9284c11900.jpeg?im_w=1200&im_format=avif',
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/3319ee8d-7f5f-4976-a936-cc74a7feb0c9.jpeg?im_w=720&im_format=avif',
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/ab1a5cdf-698f-4670-9088-1f2d08065f36.jpeg?im_w=720&im_format=avif',
                'https://a0.muscache.com/im/pictures/24c2d7ed-bf13-4050-aa3c-8dffd24b07e5.jpg?im_w=720&im_format=avif'
              ],
              type: ListingType.hostel,
              amenities:
                  Amenities.fromJSON({'wireless_internet': true, 'bbq': true}))
          .toJson()),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_LISTING,
      tags: [])),
  Listing.fromNostrEvent(NostrEvent.fromPartialData(
      keyPairs: MockKeys.hoster,
      content: json.encode(ListingContent(
              description: """
A modern apartment in the heart of the city. Perfect for business travelers and tourists. Close to public transport and local attractions.
The space
Stylish apartment with a fully equipped kitchen, comfortable living area, and a balcony with city views. Ideal for relaxing after a day of exploring.
Guest access
Guests have access to the entire apartment.
Other things to note
The apartment is not suitable for pets.
""",
              price: [
                Price(
                    amount: Amount(value: 0.0015, currency: Currency.BTC),
                    frequency: Frequency.daily)
              ], // 0.0015 per day
              minStay: Duration(days: 1), // 1 day min stay
              checkIn: TimeOfDay(hour: 15, minute: 0),
              checkOut: TimeOfDay(hour: 11, minute: 0),
              location: '456 City Road, Metropolis',
              quantity: 1,
              images: [
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/2eecc731-6e8e-49c4-963a-2c9284c11900.jpeg?im_w=1200&im_format=avif',
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/3319ee8d-7f5f-4976-a936-cc74a7feb0c9.jpeg?im_w=720&im_format=avif',
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/ab1a5cdf-698f-4670-9088-1f2d08065f36.jpeg?im_w=720&im_format=avif',
                'https://a0.muscache.com/im/pictures/24c2d7ed-bf13-4050-aa3c-8dffd24b07e5.jpg?im_w=720&im_format=avif'
              ],
              type: ListingType.apartment,
              amenities:
                  Amenities.fromJSON({'wireless_internet': true, 'gym': true}))
          .toJson()),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_LISTING,
      tags: [])),
  Listing.fromNostrEvent(NostrEvent.fromPartialData(
      keyPairs: MockKeys.hoster,
      content: json.encode(ListingContent(
              description: """
A charming bed and breakfast in a quiet neighborhood. Perfect for a relaxing getaway. Close to local shops and restaurants.
The space
Cozy rooms with comfortable beds and a delicious breakfast served daily. Ideal for a peaceful retreat.
Guest access
Guests have access to their private rooms and common areas.
Other things to note
The bed and breakfast is family-friendly.
""",
              price: [
                Price(
                    amount: Amount(value: 0.001, currency: Currency.BTC),
                    frequency: Frequency.daily)
              ], // 0.001 per day
              minStay: Duration(days: 1), // 1 day min stay
              checkIn: TimeOfDay(hour: 13, minute: 0),
              checkOut: TimeOfDay(hour: 10, minute: 0),
              location: '789 Suburb Street, Quiet Town',
              quantity: 1,
              images: [
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/2eecc731-6e8e-49c4-963a-2c9284c11900.jpeg?im_w=1200&im_format=avif',
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/3319ee8d-7f5f-4976-a936-cc74a7feb0c9.jpeg?im_w=720&im_format=avif',
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/ab1a5cdf-698f-4670-9088-1f2d08065f36.jpeg?im_w=720&im_format=avif',
                'https://a0.muscache.com/im/pictures/24c2d7ed-bf13-4050-aa3c-8dffd24b07e5.jpg?im_w=720&im_format=avif'
              ],
              type: ListingType.apartment,
              amenities:
                  Amenities.fromJSON({'wireless_internet': true, 'bbq': true}))
          .toJson()),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_LISTING,
      tags: [])),
  Listing.fromNostrEvent(NostrEvent.fromPartialData(
      keyPairs: MockKeys.hoster,
      content: json.encode(ListingContent(
              description: """
A luxurious villa with stunning ocean views. Perfect for a lavish vacation. Close to the beach and local attractions.
The space
Spacious villa with a private pool, fully equipped kitchen, and elegant living areas. Ideal for a luxurious stay.
Guest access
Guests have access to the entire villa and private pool.
Other things to note
The villa is not suitable for children under 12.
""",
              price: [
                Price(
                    amount: Amount(value: 0.005, currency: Currency.BTC),
                    frequency: Frequency.daily)
              ], // 0.005 per day
              minStay: Duration(days: 3), // 3 days min stay
              checkIn: TimeOfDay(hour: 16, minute: 0),
              checkOut: TimeOfDay(hour: 11, minute: 0),
              location: '101 Ocean Drive, Beach City',
              quantity: 1,
              images: [
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/2eecc731-6e8e-49c4-963a-2c9284c11900.jpeg?im_w=1200&im_format=avif',
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/3319ee8d-7f5f-4976-a936-cc74a7feb0c9.jpeg?im_w=720&im_format=avif',
                'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/ab1a5cdf-698f-4670-9088-1f2d08065f36.jpeg?im_w=720&im_format=avif',
                'https://a0.muscache.com/im/pictures/24c2d7ed-bf13-4050-aa3c-8dffd24b07e5.jpg?im_w=720&im_format=avif'
              ],
              type: ListingType.villa,
              amenities:
                  Amenities.fromJSON({'wireless_internet': true, 'bbq': true}))
          .toJson()),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_LISTING,
      tags: [])),
  Listing.fromNostrEvent(NostrEvent.fromPartialData(
      keyPairs: MockKeys.hoster,
      content: json.encode(ListingContent(
              description: """
A rustic old cabin in the heart of the High Weald. Wonderful outdoor living. Beautiful gardens in Area of Outstanding Natural Beauty in the High Weald. Lovely walks from the door and on Ashdown Forest. Tunbridge Wells and Glyndebourne nearby, 1 hour to London by train, station 1 mile away. Gym, 100MBps Wi-Fi, work space, outdoor living, very private, valley view to Harrisons Rocks.
The space
Canadian log cabin with wonderful views out over garden and across valley. Light, airy, modern, warm, spacious, cozy. Very well equipped kitchen. Lovely outdoor spaces for eating and relaxing.
Guest access
You have the whole house to yourself.
Other things to note
Children are welcome, however the garden's have some unavoidable natural hazards - small rock cliffs, ponds, steep banks. The deep pond is fenced off and is not easily accessible to children. If you come with children they need to be supervised for their outside.

The house contains old furniture and rugs and the contents need to be treated with respect by young and old alike.
""",
              price: [
                Price(
                    amount: Amount(value: 0.0015, currency: Currency.BTC),
                    frequency: Frequency.weekly)
              ], // 0.01 per week
              minStay: Duration(days: 1), // 1 day min stay
              checkIn: TimeOfDay(hour: 10, minute: 0),
              checkOut: TimeOfDay(hour: 9, minute: 0),
              location: 'The Spa Hotel, Tunbridge Wells',
              quantity: 1,
              images: [
                'https://a0.muscache.com/im/pictures/hosting/Hosting-969005556773045175/original/c5f9c3ca-3288-43fa-bca4-4eb68982f64b.jpeg?im_w=1200&im_format=avif',
                'https://a0.muscache.com/im/pictures/hosting/Hosting-U3RheVN1cHBseUxpc3Rpbmc6OTY5MDA1NTU2NzczMDQ1MTc1/original/8ddca066-7ed4-4676-94d9-b15b503ce105.jpeg?im_w=720&im_format=avif',
                'https://a0.muscache.com/im/pictures/hosting/Hosting-U3RheVN1cHBseUxpc3Rpbmc6OTY5MDA1NTU2NzczMDQ1MTc1/original/8c48449e-da3e-4e54-a04e-aad055f4223c.jpeg?im_w=720&im_format=avif',
                'https://a0.muscache.com/im/pictures/hosting/Hosting-U3RheVN1cHBseUxpc3Rpbmc6OTY5MDA1NTU2NzczMDQ1MTc1/original/3a4bd781-df98-48ee-b644-a22096e2a77e.jpeg?im_w=720&im_format=avif'
              ],
              type: ListingType.hotel,
              amenities:
                  Amenities.fromJSON({'wireless_internet': true, 'bbq': true}))
          .toJson()),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_LISTING,
      tags: []))
].toList();
