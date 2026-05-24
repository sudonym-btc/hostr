@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/usecase/blossom/blossom.dart';
import 'package:hostr_sdk/usecase/escrow_methods/escrows_methods.dart';
import 'package:hostr_sdk/usecase/evm/evm.dart';
import 'package:hostr_sdk/usecase/evm/chain/evm_chain.dart';
import 'package:hostr_sdk/usecase/metadata/metadata.dart';
import 'package:hostr_sdk/usecase/relays/relays.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart'
    show
        Filter,
        MemCacheManager,
        Metadata,
        Metadatas,
        Ndk,
        NdkConfig,
        Nip01Event;
import 'package:test/test.dart';

class _FakeNdk extends Fake implements Ndk {}

class _FakeRelays extends Fake implements Relays {}

class _FakeEscrowMethods extends Fake implements EscrowMethods {}

class _FakeBlossomUseCase extends Fake implements BlossomUseCase {}

class _FakeEvm extends Fake implements Evm {}

class _RecordingEvm extends Fake implements Evm {
  int initCalls = 0;

  @override
  Future<void> init() async {
    initCalls++;
  }

  @override
  List<EvmChain> get configuredChains => const [];
}

class _FakeHostrConfig extends Fake implements HostrConfig {}

class _MetadataDiscoveryHostrConfig extends Fake implements HostrConfig {
  @override
  String get hostrRelay => 'wss://relay-a.test';

  @override
  List<String> get bootstrapRelays => const [
    'wss://relay-b.test',
    'wss://relay-c.test',
  ];
}

class _SellerConfigHostrConfig extends Fake implements HostrConfig {
  @override
  String get hostrRelay => '';

  @override
  List<String> get bootstrapEscrowPubkeys => const ['escrow-pubkey'];
}

class _FakeRequests extends Fake implements Requests {}

class _MetadataDiscoveryRequests extends Fake implements Requests {
  _MetadataDiscoveryRequests(this.eventsByRelay);

  final Map<String, List<ProfileMetadata>> eventsByRelay;
  final relayCalls = <List<String>>[];
  final cacheReadValues = <bool>[];

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) {
    relayCalls.add(relays ?? const []);
    cacheReadValues.add(cacheRead);
    final relay = relays == null || relays.length != 1 ? null : relays.single;
    final events = relay == null
        ? const <ProfileMetadata>[]
        : eventsByRelay[relay] ?? const <ProfileMetadata>[];
    return Stream<T>.fromIterable(events.cast<T>());
  }
}

class _RecordingRelays extends Fake implements Relays {
  _RecordingRelays(this.connectedByRelay);

  final Map<String, bool> connectedByRelay;
  final ensureCalls = <String>[];

  @override
  Future<bool> ensureConnected(
    String url, {
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 200),
  }) async {
    ensureCalls.add(url);
    return connectedByRelay[url] ?? false;
  }
}

class _NullMetadatas extends Fake implements Metadatas {
  @override
  Future<Metadata?> loadMetadata(
    String pubKey, {
    bool forceRefresh = false,
    Duration idleTimeout = const Duration(seconds: 5),
  }) async {
    return null;
  }
}

class _MetadataDiscoveryNdk extends Fake implements Ndk {
  final _metadata = _NullMetadatas();
  final _config = NdkConfig(
    eventVerifier: const TrustAllEventVerifier(),
    cache: MemCacheManager(),
  );

  @override
  Metadatas get metadata => _metadata;

  @override
  NdkConfig get config => _config;
}

class _RecordingEscrowMethods extends Fake implements EscrowMethods {
  int ensureCalls = 0;
  List<String>? trustedEscrowPubkeys;
  Set<String>? bytecodeHashes;

  @override
  Future<void> ensureEscrowMethod({
    Set<String> bytecodeHashes = const {},
    List<String> trustedEscrowPubkeys = const [],
    List<AcceptedPaymentForm>? acceptedPaymentForms,
  }) async {
    ensureCalls++;
    this.bytecodeHashes = bytecodeHashes;
    this.trustedEscrowPubkeys = trustedEscrowPubkeys;
  }
}

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
  group('metadataDiscoveryRelays', () {
    test('uses hostr relay when bootstrap relays are empty', () {
      expect(
        metadataDiscoveryRelays(
          hostrRelay: 'wss://relay.hostr.test',
          bootstrapRelays: const [],
        ),
        equals(['wss://relay.hostr.test']),
      );
    });

    test('deduplicates hostr and bootstrap relays while preserving order', () {
      expect(
        metadataDiscoveryRelays(
          hostrRelay: ' wss://relay.hostr.test ',
          bootstrapRelays: const [
            'wss://relay.hostr.test',
            ' wss://relay.other.test ',
            '',
          ],
        ),
        equals(['wss://relay.hostr.test', 'wss://relay.other.test']),
      );
    });
  });

  group('MetadataUseCase.loadMetadata', () {
    test(
      'queries connected discovery relays individually and keeps latest profile',
      () async {
        final relays = _RecordingRelays({
          'wss://relay-a.test': true,
          'wss://relay-b.test': false,
          'wss://relay-c.test': true,
        });
        final requests = _MetadataDiscoveryRequests({
          'wss://relay-a.test': [_profile('pubkey', name: 'Old', createdAt: 1)],
          'wss://relay-c.test': [_profile('pubkey', name: 'New', createdAt: 2)],
        });
        final metadata = MetadataUseCase(
          ndk: _MetadataDiscoveryNdk(),
          relays: relays,
          escrowMethods: _FakeEscrowMethods(),
          blossom: _FakeBlossomUseCase(),
          evm: _FakeEvm(),
          config: _MetadataDiscoveryHostrConfig(),
          requests: requests,
          logger: CustomLogger(),
        );

        final profile = await metadata.loadMetadataFromSources(
          'pubkey',
          forceRefresh: false,
        );

        expect(profile?.metadata.name, 'New');
        expect(relays.ensureCalls, [
          'wss://relay-a.test',
          'wss://relay-b.test',
          'wss://relay-c.test',
        ]);
        expect(requests.relayCalls, [
          ['wss://relay-a.test'],
          ['wss://relay-c.test'],
        ]);
        expect(requests.cacheReadValues, [false, false]);
      },
    );

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

  group('MetadataUseCase.ensureSellerConfig', () {
    test('initializes EVM before ensuring escrow methods', () async {
      final evm = _RecordingEvm();
      final escrowMethods = _RecordingEscrowMethods();
      final metadata = MetadataUseCase(
        ndk: _FakeNdk(),
        relays: _FakeRelays(),
        escrowMethods: escrowMethods,
        blossom: _FakeBlossomUseCase(),
        evm: evm,
        config: _SellerConfigHostrConfig(),
        requests: _FakeRequests(),
        logger: CustomLogger(),
      );

      await metadata.ensureSellerConfig('host-pubkey');

      expect(evm.initCalls, 1);
      expect(escrowMethods.ensureCalls, 1);
      expect(escrowMethods.trustedEscrowPubkeys, ['escrow-pubkey']);
      expect(escrowMethods.bytecodeHashes, isEmpty);
    });
  });
}

ProfileMetadata _profile(
  String pubkey, {
  required String name,
  required int createdAt,
}) {
  return ProfileMetadata.fromNostrEvent(
    Nip01Event(
      pubKey: pubkey,
      createdAt: createdAt,
      kind: Metadata.kKind,
      tags: const [],
      content: '{"name":"$name"}',
      sig: 'sig',
      id: 'id-$pubkey-$createdAt',
    ),
  );
}
