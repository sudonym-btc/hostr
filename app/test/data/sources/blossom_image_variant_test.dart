import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/data/sources/blossom_image_variant.dart';
import 'package:models/main.dart';

void main() {
  group('BlossomImageVariantResolver', () {
    test('chooses the largest matching variant under the byte target', () {
      final small = _meta(
        url: 'https://blossom.example/image-small.webp',
        sha256: 'small',
        size: 80 * 1024,
      );
      final medium = _meta(
        url: 'https://blossom.example/image-medium.webp',
        sha256: 'medium',
        size: 180 * 1024,
      );
      final large = _meta(
        url: 'https://blossom.example/image-large.webp',
        sha256: 'large',
        size: 260 * 1024,
      );

      final result = BlossomImageVariantResolver.resolve(
        imageRef: medium.url,
        imageMetas: [small, medium, large],
        hint: const BlossomImageVariantHint(maxBytes: 200 * 1024),
      );

      expect(result.ref, medium.url);
      expect(result.isOriginal, false);
    });

    test('falls back to the smallest oversized variant when none fit', () {
      final medium = _meta(
        url: 'https://blossom.example/image-medium.webp',
        sha256: 'medium',
        size: 220 * 1024,
      );
      final large = _meta(
        url: 'https://blossom.example/image-large.webp',
        sha256: 'large',
        size: 420 * 1024,
      );

      final result = BlossomImageVariantResolver.resolve(
        imageRef: medium.url,
        imageMetas: [medium, large],
        hint: const BlossomImageVariantHint(maxBytes: 200 * 1024),
      );

      expect(result.ref, medium.url);
    });

    test('chooses the largest variant inside requested dimensions', () {
      final thumbnail = _meta(
        url: 'https://blossom.example/image-thumb.webp',
        sha256: 'thumb',
        dimensions: '640x360',
      );
      final card = _meta(
        url: 'https://blossom.example/image-card.webp',
        sha256: 'card',
        dimensions: '1280x720',
      );
      final full = _meta(
        url: 'https://blossom.example/image-full.webp',
        sha256: 'full',
        dimensions: '1920x1080',
      );

      final result = BlossomImageVariantResolver.resolve(
        imageRef: full.url,
        imageMetas: [thumbnail, card, full],
        hint: const BlossomImageVariantHint(maxWidth: 1280, maxHeight: 720),
      );

      expect(result.ref, card.url);
    });

    test('does not choose original hash unless explicitly allowed', () {
      final optimized = _meta(
        url: 'https://blossom.example/image.webp',
        sha256: 'optimized',
        originalSha256: 'original',
        size: 250 * 1024,
      );

      final result = BlossomImageVariantResolver.resolve(
        imageRef: optimized.url,
        imageMetas: [optimized],
        hint: const BlossomImageVariantHint(maxBytes: 200 * 1024),
      );

      expect(result.ref, optimized.url);
      expect(result.isOriginal, false);
    });

    test('uses an original hash ref to find matching optimized variants', () {
      const original = 'original';
      final small = _meta(
        url: 'https://blossom.example/image-small.webp',
        sha256: 'small',
        originalSha256: original,
        size: 120 * 1024,
      );
      final large = _meta(
        url: 'https://blossom.example/image-large.webp',
        sha256: 'large',
        originalSha256: original,
        size: 360 * 1024,
      );

      final result = BlossomImageVariantResolver.resolve(
        imageRef: original,
        imageMetas: [small, large],
        hint: const BlossomImageVariantHint(maxBytes: 200 * 1024),
      );

      expect(result.ref, small.url);
      expect(result.isOriginal, false);
    });
  });
}

IMeta _meta({
  required String url,
  String? sha256,
  String originalSha256 = 'original',
  int? size,
  String? dimensions,
}) => IMeta(
  url: url,
  sha256: sha256,
  originalSha256: originalSha256,
  size: size,
  dimensions: dimensions,
);
