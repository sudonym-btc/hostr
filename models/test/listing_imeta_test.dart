import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

Listing _listing({
  List<String> images = const [],
  List<IMeta> imageMetas = const [],
}) {
  return Listing.create(
    pubKey: MockKeys.hoster.publicKey,
    dTag: 'listing-imeta',
    title: 'Media Listing',
    description: 'Fixture',
    images: images,
    imageMetas: imageMetas,
    price: [
      Price(
        amount: DenominatedAmount(
          value: BigInt.from(100000),
          denomination: 'BTC',
          decimals: 8,
        ),
        frequency: Frequency.daily,
      ),
    ],
    location: 'Test',
    type: ListingType.house,
    specifications: Specifications(),
  );
}

void main() {
  group('listing image imeta', () {
    test('emits image and imeta tags for rich media hints', () {
      const meta = IMeta(
        url: 'https://blossom.example/optimised.webp',
        mime: 'image/webp',
        sha256: 'optimised-hash',
        originalSha256: 'original-hash',
        size: 240000,
        dimensions: '1920x1080',
        blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
        alt: 'Photo of the listing',
      );

      final listing = _listing(
        images: [meta.url],
        imageMetas: const [meta],
      );

      expect(listing.images, [meta.url]);
      expect(
        listing.tags,
        contains(equals(['image', meta.url, '1920x1080'])),
      );
      expect(
        listing.tags,
        contains(
          equals(
            const [
              'imeta',
              'url https://blossom.example/optimised.webp',
              'm image/webp',
              'x optimised-hash',
              'ox original-hash',
              'size 240000',
              'dim 1920x1080',
              'blurhash LEHV6nWB2yk8pyo0adR*.7kCMdnj',
              'alt Photo of the listing',
            ],
          ),
        ),
      );
    });

    test('parses imeta tags from existing listing events', () {
      final listing = _listing(
        images: const ['https://blossom.example/optimised.webp'],
        imageMetas: const [
          IMeta(
            url: 'https://blossom.example/optimised.webp',
            sha256: 'optimised-hash',
            originalSha256: 'original-hash',
            blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
          ),
        ],
      );

      final meta = listing.imageMetas.single;

      expect(meta.url, 'https://blossom.example/optimised.webp');
      expect(meta.sha256, 'optimised-hash');
      expect(meta.originalSha256, 'original-hash');
      expect(meta.blurhash, 'LEHV6nWB2yk8pyo0adR*.7kCMdnj');
    });

    test('rebuild keeps imeta only for retained images', () {
      final listing = _listing(
        images: const [
          'https://blossom.example/one.webp',
          'https://blossom.example/two.webp',
        ],
        imageMetas: const [
          IMeta(url: 'https://blossom.example/one.webp', sha256: 'one'),
          IMeta(url: 'https://blossom.example/two.webp', sha256: 'two'),
        ],
      );

      final rebuilt = listing.rebuild(
        images: const ['https://blossom.example/two.webp'],
      );

      expect(rebuilt.images, const ['https://blossom.example/two.webp']);
      expect(rebuilt.imageMetas.map((meta) => meta.sha256), const ['two']);
      expect(
        rebuilt.tags.where((tag) => tag.isNotEmpty && tag.first == 'imeta'),
        hasLength(1),
      );
    });
  });
}
