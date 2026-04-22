import 'dart:convert';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('profile metadata imeta', () {
    test('parses picture imeta from kind 0 tags', () {
      final event = _profileEvent(
        pubKey: 'pubkey',
        picture: 'https://blossom.example/profile.webp',
        tags: const [
          [
            'imeta',
            'url https://blossom.example/profile.webp',
            'm image/webp',
            'x optimized',
            'ox original',
            'size 64000',
            'dim 512x512',
            'blurhash LQG[l~s:00t6R+ofWBt7%Ma#aeRj',
          ],
        ],
      );

      final profile = ProfileMetadata.fromNostrEvent(event);

      expect(profile.imageMetas, hasLength(1));
      expect(profile.pictureIMeta?.url, 'https://blossom.example/profile.webp');
      expect(profile.pictureIMeta?.sha256, 'optimized');
      expect(profile.pictureIMeta?.originalSha256, 'original');
    });

    test('withImageMetas replaces stale imeta tags', () {
      final profile = ProfileMetadata.fromNostrEvent(
        _profileEvent(
          pubKey: 'pubkey',
          picture: 'https://blossom.example/new.webp',
          tags: const [
            [
              'imeta',
              'url https://blossom.example/old.webp',
              'x old',
            ],
            ['i', 'evm:address', '0x123'],
          ],
        ),
      );

      final rebuilt = profile.withImageMetas(const [
        IMeta(
          url: 'https://blossom.example/new.webp',
          mime: 'image/webp',
          sha256: 'new',
          originalSha256: 'original',
          size: 120000,
          dimensions: '512x512',
        ),
      ]);

      expect(rebuilt.imageMetas, hasLength(1));
      expect(rebuilt.imageMetas.single.url, 'https://blossom.example/new.webp');
      expect(
        rebuilt.tags.where((tag) => tag.isNotEmpty && tag.first == 'i'),
        hasLength(1),
      );
      expect(
        rebuilt.tags.any(
          (tag) => tag.any(
            (value) => value.contains('https://blossom.example/old.webp'),
          ),
        ),
        false,
      );
    });
  });
}

Nip01Event _profileEvent({
  required String pubKey,
  required String picture,
  required List<List<String>> tags,
}) =>
    Nip01Event(
      pubKey: pubKey,
      kind: kNostrKindProfile,
      content: jsonEncode({
        'name': 'Taylor',
        'picture': picture,
      }),
      tags: tags,
      createdAt: 123,
    );
