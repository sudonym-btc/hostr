import 'package:faker/faker.dart' hide Currency;
import 'package:models/main.dart';

import 'main.dart';

const List<({double latitude, double longitude})> _landSeedPoints = [
  (latitude: 40.7128, longitude: -74.0060), // New York
  (latitude: 34.0522, longitude: -118.2437), // Los Angeles
  (latitude: 19.4326, longitude: -99.1332), // Mexico City
  (latitude: -23.5505, longitude: -46.6333), // São Paulo
  (latitude: -34.6037, longitude: -58.3816), // Buenos Aires
  (latitude: 51.5074, longitude: -0.1278), // London
  (latitude: 48.8566, longitude: 2.3522), // Paris
  (latitude: 52.5200, longitude: 13.4050), // Berlin
  (latitude: 41.9028, longitude: 12.4964), // Rome
  (latitude: 30.0444, longitude: 31.2357), // Cairo
  (latitude: 6.5244, longitude: 3.3792), // Lagos
  (latitude: -1.2921, longitude: 36.8219), // Nairobi
  (latitude: 25.2048, longitude: 55.2708), // Dubai
  (latitude: 28.6139, longitude: 77.2090), // Delhi
  (latitude: 13.7563, longitude: 100.5018), // Bangkok
  (latitude: 1.3521, longitude: 103.8198), // Singapore
  (latitude: 35.6895, longitude: 139.6917), // Tokyo
  (latitude: 37.5665, longitude: 126.9780), // Seoul
  (latitude: 31.2304, longitude: 121.4737), // Shanghai
  (latitude: -33.8688, longitude: 151.2093), // Sydney
  (latitude: -37.8136, longitude: 144.9631), // Melbourne
  (latitude: -36.8485, longitude: 174.7633), // Auckland
];

double _unitRandom(Faker faker) =>
    faker.randomGenerator.integer(1000000) / 1000000;

({double latitude, double longitude}) _landPointForIndex(
  Faker faker,
  int index,
) {
  final base = _landSeedPoints[index % _landSeedPoints.length];
  final latJitter = (_unitRandom(faker) - 0.5) * 0.5;
  final lonJitter = (_unitRandom(faker) - 0.5) * 0.5;

  final latitude = (base.latitude + latJitter).clamp(-85.0, 85.0).toDouble();
  var longitude = base.longitude + lonJitter;
  if (longitude > 180) longitude -= 360;
  if (longitude < -180) longitude += 360;

  return (latitude: latitude, longitude: longitude);
}

final h3TagsLondon = H3Engine.bundled()
    .hierarchy
    .hierarchyForPoint(latitude: 51.5074, longitude: -0.1278);

final tagsLondon = List<List<String>>.generate(
    h3TagsLondon.length, (i) => ['g', h3TagsLondon[i]]);

final h3TagsMexicoCity = H3Engine.bundled()
    .hierarchy
    .hierarchyForPoint(latitude: 19.4326, longitude: -99.1332);

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
      tags: [
        ...tagsMexicoCity,
        ['d', '1'],
      ]).signAs(MockKeys.hoster, Listing.fromNostrEvent),
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
      tags: [
        ...tagsLondon,
        ['d', '2'],
      ]).signAs(MockKeys.hoster, Listing.fromNostrEvent),
].toList();

final FAKED_LISTINGS = List.generate(100, (count) {
  final faker = Faker(seed: count);
  final key = mockKeys[count];
  final point = _landPointForIndex(faker, count);
  final latitude = point.latitude;
  final longitude = point.longitude;
  final h3Tags = H3Engine.bundled()
      .hierarchy
      .hierarchyForPoint(latitude: latitude, longitude: longitude);

  final tags =
      List<List<String>>.generate(h3Tags.length, (i) => ['g', h3Tags[i]]);
  tags.add(['d', count.toString()]);
  return Listing(
          pubKey: key.publicKey,
          content: ListingContent(
              title: faker.lorem.sentence(),
              description: faker.lorem.sentences(3).join('\n\n'),
              price: [
                Price(
                    amount: Amount(
                        value: BigInt.from(
                            faker.randomGenerator.integer(1000000, min: 10000)),
                        currency: Currency.BTC),
                    frequency: Frequency.daily)
              ], // 0.002 per day
              minStay: Duration(days: 2), // 2 days min stay
              checkIn: TimeOfDay(hour: 14, minute: 0),
              checkOut: TimeOfDay(hour: 11, minute: 0),
              location: faker.address.streetAddress() +
                  ', ' +
                  faker.address.city() +
                  ', ' +
                  faker.address.country(),
              quantity: 1,
              images: [
                faker.image.loremPicsum(width: 1920, height: 1080),
                faker.image.loremPicsum(width: 1920, height: 1080),
                faker.image.loremPicsum(width: 1920, height: 1080)
              ],
              type: ListingType.hostel,
              amenities:
                  Amenities.fromJSON({'wireless_internet': true, 'bbq': true}),
              requiresEscrow: true),
          createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
          tags: tags)
      .signAs(key, Listing.fromNostrEvent);
});
