import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

import '../models/listing.dart';
import 'keypairs.dart';

NostrKeyPairs keyPairs = NostrKeyPairs.generate();

var MOCK_LISTINGS = [
  NostrEvent.fromPartialData(
      keyPairs: MockKeys.hoster,
      content: JsonEncoder().convert({
        'description': """
A light, warm, and modern space for a gathering. Wonderful outdoor living. Beautiful gardens in Area of Outstanding Natural Beauty in the High Weald . Lovely walks from the door and on Ashdown Forest. Tunbridge Wells and Glyndebourne nearby, 1 hour to London by train, station 1 mile away. Gym, 100MBps Wi-Fi, work space, outdoor living, very private, valley view to Harrisons Rocks.
The space
Canadian log cabin with wonderful views out over garden and across valley. Light, airy, modern, warm, spacious, cosy. Very well equipped kitchen. Lovely outdoor spaces for eating and relaxing.
Guest access
You have the whole house to yourself.
Other things to note
Children are welcome, however the garden's have some unavoidable natural hazards - small rock cliffs, ponds, steep banks. The deep pond is fenced off and is not easily accessible to children. If you come with children they need to be supervised for their outside.

The house contains old furniture and rugs and the contents need to be treated with respect by young and old alike.
""",
        'currency': 'USD',
        'amountPerDay': 20,
        'minStay': 1,
        'checkIn': 11,
        'checkOut': 14,
        'location': '25 Baslow Road, Eastbourne',
        'quantity': 1,
        'images': [
          'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/2eecc731-6e8e-49c4-963a-2c9284c11900.jpeg?im_w=1200&im_format=avif',
          'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/3319ee8d-7f5f-4976-a936-cc74a7feb0c9.jpeg?im_w=720&im_format=avif',
          'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/ab1a5cdf-698f-4670-9088-1f2d08065f36.jpeg?im_w=720&im_format=avif',
          'https://a0.muscache.com/im/pictures/24c2d7ed-bf13-4050-aa3c-8dffd24b07e5.jpg?im_w=720&im_format=avif'
        ],
        'type': 'Apartment',
        'amenities': {'jacuzzi': true, 'bbq': true, 'wireless_internet': true},
        'private': 'false',
      }),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_LISTING,
      tags: [])
].map(Listing.fromNostrEvent).toList();
