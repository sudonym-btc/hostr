@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/usecase/blossom/blossom.dart';
import 'package:hostr_sdk/usecase/escrow_methods/escrows_methods.dart';
import 'package:hostr_sdk/usecase/evm/evm.dart';
import 'package:hostr_sdk/usecase/identity_claims/identity_claims.dart';
import 'package:hostr_sdk/usecase/metadata/metadata.dart';
import 'package:hostr_sdk/usecase/relays/relays.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Ndk;
import 'package:test/test.dart';

class _FakeNdk extends Fake implements Ndk {}

class _FakeRelays extends Fake implements Relays {}

class _FakeEscrowMethods extends Fake implements EscrowMethods {}

class _FakeBlossomUseCase extends Fake implements BlossomUseCase {}

class _FakeEvm extends Fake implements Evm {}

class _FakeIdentityClaimsUseCase extends Fake implements IdentityClaimsUseCase {}

class _FakeHostrConfig extends Fake implements HostrConfig {}

class _FakeRequests extends Fake implements Requests {}

class _TestMetadataUseCase extends MetadataUseCase {
  int loadCount = 0;
  final List<({String pubkey, bool forceRefresh})> calls = [];
  Completer<ProfileMetadata?> completer = Completer<ProfileMetadata?>();

  _TestMetadataUseCase()
    : super(
        ndk: _FakeNdk(),
        relays: _FakeRelays(),
        escrowMethods: _FakeEscrowMethods(),
        blossom: _FakeBlossomUseCase(),
        evm: _FakeEvm(),
        identityClaims: _FakeIdentityClaimsUseCase(),
        config: _FakeHostrConfig(),
        requests: _FakeRequests(),
        logger: CustomLogger(),
      );

  @override
  Future<ProfileMetadata?> loadMetadataFromSources(
    String pubkey, {
    required bool forceRefresh,
  }) {
    loadCount++;
    calls.add((pubkey: pubkey, forceRefresh: forceRefresh));
    return completer.future;
  }
}

void main() {
  group('MetadataUseCase.loadMetadata', () {
    test(
      'shares concurrent loads for the same pubkey and refresh mode',
      () async {
        final metadata = _TestMetadataUseCase();

        final first = metadata.loadMetadata(' pubkey ');
        final second = metadata.loadMetadata('pubkey');

        expect(identical(first, second), isTrue);
        expect(metadata.loadCount, 1);
        expect(metadata.calls.single, (pubkey: 'pubkey', forceRefresh: false));

        metadata.completer.complete(null);
        await expectLater(
          Future.wait([first, second]),
          completion([null, null]),
        );
      },
    );

    test('clears an errored in-flight load so callers can retry', () async {
      final metadata = _TestMetadataUseCase();

      final failed = metadata.loadMetadata('pubkey');
      metadata.completer.completeError(StateError('boom'));

      await expectLater(failed, throwsA(isA<StateError>()));
      expect(metadata.loadCount, 1);

      metadata.completer = Completer<ProfileMetadata?>();
      final retry = metadata.loadMetadata('pubkey');

      expect(metadata.loadCount, 2);
      metadata.completer.complete(null);
      await expectLater(retry, completion(isNull));
    });

    test('lets regular callers share an in-flight force refresh', () async {
      final metadata = _TestMetadataUseCase();

      final force = metadata.loadMetadata('pubkey', forceRefresh: true);
      final regular = metadata.loadMetadata('pubkey');

      expect(identical(force, regular), isTrue);
      expect(metadata.loadCount, 1);
      expect(metadata.calls.single, (pubkey: 'pubkey', forceRefresh: true));

      metadata.completer.complete(null);
      await expectLater(
        Future.wait([force, regular]),
        completion([null, null]),
      );
    });

    test(
      'keeps force refresh separate from an existing regular load',
      () async {
        final metadata = _TestMetadataUseCase();

        final regular = metadata.loadMetadata('pubkey');
        final force = metadata.loadMetadata('pubkey', forceRefresh: true);

        expect(identical(regular, force), isFalse);
        expect(metadata.loadCount, 2);
        expect(metadata.calls, [
          (pubkey: 'pubkey', forceRefresh: false),
          (pubkey: 'pubkey', forceRefresh: true),
        ]);

        metadata.completer.complete(null);
        await expectLater(
          Future.wait([regular, force]),
          completion([null, null]),
        );
      },
    );
  });
}
