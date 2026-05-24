@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/escrow_methods/escrows_methods.dart';
import 'package:hostr_sdk/usecase/evm/evm.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01Event;
import 'package:test/test.dart';

class _FakeAuth extends Fake implements Auth {}

class _FakeEvm extends Fake implements Evm {}

class _FakeRequests extends Fake implements Requests {
  final StreamController<EscrowMethod> controller =
      StreamController<EscrowMethod>();

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
}

void main() {
  test(
    'loadEvmAddress reads the address from the escrow method event',
    () async {
      final requests = _FakeRequests();
      final useCase = EscrowMethods(
        requests: requests,
        logger: CustomLogger(),
        auth: _FakeAuth(),
        evm: _FakeEvm(),
      );
      final method = EscrowMethod.fromNostrEvent(
        Nip01Event(
          pubKey: MockKeys.hoster.publicKey,
          kind: kNostrKindEscrowMethod,
          tags: const [
            ['i', 'evm:address:0x0000000000000000000000000000000000000001'],
          ],
          content: '',
        ),
      );

      final loadedFuture = useCase.loadEvmAddress(MockKeys.hoster.publicKey);
      requests.controller.add(method);

      final loaded = await loadedFuture.timeout(
        const Duration(milliseconds: 100),
      );

      expect(loaded, method.evmAddress);
      await requests.controller.close();
    },
  );
}
