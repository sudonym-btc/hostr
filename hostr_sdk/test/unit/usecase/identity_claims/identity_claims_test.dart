@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/evm/config/evm_config.dart';
import 'package:hostr_sdk/usecase/identity_claims/identity_claims.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Nip01Event;
import 'package:test/test.dart';

class _FakeAuth extends Fake implements Auth {}

class _FakeRequests extends Fake implements Requests {
  final StreamController<IdentityClaims> controller =
      StreamController<IdentityClaims>();

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) {
    return controller.stream.cast<T>();
  }

  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) {
    throw UnimplementedError();
  }
}

HostrConfig _config() => HostrConfig(
  bootstrapRelays: const [],
  bootstrapBlossom: const [],
  hostrRelay: 'wss://relay.test',
  evmConfig: const EvmConfig(),
  logs: CustomLogger(),
  telemetry: Telemetry.noop(),
);

void main() {
  test(
    'loadClaims returns the first matching claim without waiting for EOSE',
    () async {
      final requests = _FakeRequests();
      final useCase = IdentityClaimsUseCase(
        auth: _FakeAuth(),
        config: _config(),
        requests: requests,
        logger: CustomLogger(),
      );
      final claim = IdentityClaims.build(
        pubKey: MockKeys.hoster.publicKey,
        evmAddress: '0x0000000000000000000000000000000000000001',
      );

      final loadedFuture = useCase.loadClaims(MockKeys.hoster.publicKey);
      requests.controller.add(claim);

      final loaded = await loadedFuture.timeout(
        const Duration(milliseconds: 100),
      );

      expect(loaded?.evmAddress, claim.evmAddress);
      await requests.controller.close();
    },
  );
}
