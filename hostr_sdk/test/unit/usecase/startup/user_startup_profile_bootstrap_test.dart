@Tags(['unit'])
library;

import 'package:hostr_sdk/mocks/usecase_mocks.mocks.dart';
import 'package:hostr_sdk/usecase/startup/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:ndk/entities.dart';
import 'package:test/test.dart';

void main() {
  group('UserStartupProfileBootstrapper', () {
    late MockMetadataUseCase metadata;
    late UserStartupProfileBootstrapper bootstrapper;

    setUp(() {
      metadata = MockMetadataUseCase();
      bootstrapper = UserStartupProfileBootstrapper(metadata: metadata);
    });

    test('uses initial metadata load when found without NIP-65', () async {
      final profile = _profile('pubkey-a');
      when(metadata.loadMetadata('pubkey-a', forceRefresh: false)).thenAnswer(
        (_) async => profile,
      );

      final result = await bootstrapper.run(
        pubkey: 'pubkey-a',
        hasNip65Future: Future.value(false),
      );

      expect(result.metadata, same(profile));
      expect(result.hasNip65, isFalse);
      verify(metadata.loadMetadata('pubkey-a', forceRefresh: false)).called(1);
      verifyNever(metadata.loadMetadata('pubkey-a', forceRefresh: true));
      verify(metadata.ensureUserConfig('pubkey-a')).called(1);
    });

    test('uses initial metadata load when found with NIP-65', () async {
      final profile = _profile('pubkey-aa');
      when(metadata.loadMetadata('pubkey-aa', forceRefresh: false)).thenAnswer(
        (_) async => profile,
      );

      final result = await bootstrapper.run(
        pubkey: 'pubkey-aa',
        hasNip65Future: Future.value(true),
      );

      expect(result.metadata, same(profile));
      expect(result.hasNip65, isTrue);
      verify(metadata.loadMetadata('pubkey-aa', forceRefresh: false)).called(1);
      verifyNever(metadata.loadMetadata('pubkey-aa', forceRefresh: true));
      verify(metadata.ensureUserConfig('pubkey-aa')).called(1);
    });

    test('force refreshes when metadata missing but NIP-65 exists', () async {
      final refreshed = _profile('pubkey-b');
      when(metadata.loadMetadata('pubkey-b', forceRefresh: false)).thenAnswer(
        (_) async => null,
      );
      when(metadata.loadMetadata('pubkey-b', forceRefresh: true)).thenAnswer(
        (_) async => refreshed,
      );

      final result = await bootstrapper.run(
        pubkey: 'pubkey-b',
        hasNip65Future: Future.value(true),
      );

      expect(result.metadata, same(refreshed));
      expect(result.hasNip65, isTrue);
      verify(metadata.loadMetadata('pubkey-b', forceRefresh: false)).called(1);
      verify(metadata.loadMetadata('pubkey-b', forceRefresh: true)).called(1);
      verify(metadata.ensureUserConfig('pubkey-b')).called(1);
    });

    test('does not force refresh when metadata missing and no NIP-65', () async {
      when(metadata.loadMetadata('pubkey-c', forceRefresh: false)).thenAnswer(
        (_) async => null,
      );

      final result = await bootstrapper.run(
        pubkey: 'pubkey-c',
        hasNip65Future: Future.value(false),
      );

      expect(result.metadata, isNull);
      expect(result.hasNip65, isFalse);
      verify(metadata.loadMetadata('pubkey-c', forceRefresh: false)).called(1);
      verifyNever(metadata.loadMetadata('pubkey-c', forceRefresh: true));
      verifyNever(metadata.ensureUserConfig('pubkey-c'));
    });

    test('does not ensure config when refresh still finds no metadata', () async {
      when(metadata.loadMetadata('pubkey-d', forceRefresh: false)).thenAnswer(
        (_) async => null,
      );
      when(metadata.loadMetadata('pubkey-d', forceRefresh: true)).thenAnswer(
        (_) async => null,
      );

      final result = await bootstrapper.run(
        pubkey: 'pubkey-d',
        hasNip65Future: Future.value(true),
      );

      expect(result.metadata, isNull);
      expect(result.hasNip65, isTrue);
      verify(metadata.loadMetadata('pubkey-d', forceRefresh: false)).called(1);
      verify(metadata.loadMetadata('pubkey-d', forceRefresh: true)).called(1);
      verifyNever(metadata.ensureUserConfig('pubkey-d'));
    });
  });
}

ProfileMetadata _profile(String pubkey) {
  return ProfileMetadata.fromNostrEvent(
    Nip01Event(
      pubKey: pubkey,
      createdAt: 1,
      kind: Metadata.kKind,
      tags: const [],
      content: '{"name":"Test"}',
      sig: 'sig',
      id: 'id-$pubkey',
    ),
  );
}
