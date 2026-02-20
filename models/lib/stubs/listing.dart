import 'package:models/main.dart';

import 'main.dart';

List<String> _safeH3TagsForPoint({
    required double latitude,
    required double longitude,
}) {
    try {
        return H3Engine.bundled()
                .hierarchy
                .hierarchyForPoint(latitude: latitude, longitude: longitude);
    } catch (_) {
        return const <String>[];
    }
}

final h3TagsLondon =
        _safeH3TagsForPoint(latitude: 51.5074, longitude: -0.1278);

final tagsLondon = List<List<String>>.generate(
    h3TagsLondon.length, (i) => ['g', h3TagsLondon[i]]);

final h3TagsMexicoCity =
    _safeH3TagsForPoint(latitude: 19.4326, longitude: -99.1332);

final tagsMexicoCity = List<List<String>>.generate(
    h3TagsMexicoCity.length, (i) => ['g', h3TagsMexicoCity[i]]);

var MOCK_LISTINGS = [
  Listing(
      pubKey: MockKeys.hoster.publicKey,
      content: ListingContent(
          title: 'Cozy Cabin in the Woods',
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
                amount:
                    Amount(value: BigInt.from(200000), currency: Currency.BTC),
                frequency: Frequency.daily)
          ], // 0.002 per day
          minStay: Duration(days: 2), // 2 days min stay
          checkIn: TimeOfDay(hour: 14, minute: 0),
          checkOut: TimeOfDay(hour: 11, minute: 0),
          location:
              'Torre Alta 510, Calle el Guayabo, San Salvador, El Salvador', // @todo should be encrypted with the key of owner
          quantity: 1,
          images: [
            'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/2eecc731-6e8e-49c4-963a-2c9284c11900.jpeg?im_w=1200&im_format=avif',
            'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/3319ee8d-7f5f-4976-a936-cc74a7feb0c9.jpeg?im_w=720&im_format=avif',
            'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/ab1a5cdf-698f-4670-9088-1f2d08065f36.jpeg?im_w=720&im_format=avif',
            'https://a0.muscache.com/im/pictures/24c2d7ed-bf13-4050-aa3c-8dffd24b07e5.jpg?im_w=720&im_format=avif'
          ],
          type: ListingType.hostel,
          amenities:
              Amenities.fromJSON({'wireless_internet': true, 'bbq': true}),
          requiresEscrow: true),
      createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
      tags: EventTags([
        ...tagsMexicoCity,
        ['d', '1'],
      ])).signAs(MockKeys.hoster, Listing.fromNostrEvent),
  Listing(
      pubKey: MockKeys.hoster.publicKey,
      content: ListingContent(
          title: 'Modern City Apartment',
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
                amount:
                    Amount(value: BigInt.from(120000), currency: Currency.BTC),
                frequency: Frequency.daily)
          ], // 0.002 per day
          minStay: Duration(days: 2), // 2 days min stay
          checkIn: TimeOfDay(hour: 14, minute: 0),
          checkOut: TimeOfDay(hour: 11, minute: 0),
          location: '123 City Road, Finsbury, London',
          quantity: 1,
          images: [
            'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/2eecc731-6e8e-49c4-963a-2c9284c11900.jpeg?im_w=1200&im_format=avif',
            'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/3319ee8d-7f5f-4976-a936-cc74a7feb0c9.jpeg?im_w=720&im_format=avif',
            'https://a0.muscache.com/im/pictures/miso/Hosting-618573800623079625/original/ab1a5cdf-698f-4670-9088-1f2d08065f36.jpeg?im_w=720&im_format=avif',
            'https://a0.muscache.com/im/pictures/24c2d7ed-bf13-4050-aa3c-8dffd24b07e5.jpg?im_w=720&im_format=avif'
          ],
          type: ListingType.hostel,
          amenities:
              Amenities.fromJSON({'wireless_internet': true, 'bbq': true}),
          requiresEscrow: true),
      createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
      tags: EventTags([
        ...tagsLondon,
        ['d', '2'],
      ])).signAs(MockKeys.hoster, Listing.fromNostrEvent),
].toList();
