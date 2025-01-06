import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr/data/sources/nostr/nostr_provider/mock.nostr_provider.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';

import '../util/mock_dependency.dart';

NostrKeyPairs localKeyPair = Nostr.instance.keysService.generateKeyPair();
NostrKeyPairs signerKeypair = Nostr.instance.keysService.generateKeyPair();

class MockedNostProvider extends MockNostProvider {
  MockedNostProvider() : super() {
    events
        .where((event) => event.pubkey == localKeyPair.public)
        .listen((event) {
      switch (jsonDecode(event.content!)["command"]) {
        case "describe":
          getIt<NostrProvider>()
              .sendEventToRelaysAsync(NostrEvent.fromPartialData(
                  kind: NOSTR_KIND_CONNECT,
                  keyPairs: signerKeypair,
                  content: JsonEncoder().convert({
                    'result': ['describe', 'connect', 'disconnect', 'delegate']
                  })));
          break;
        case "delegate":
          getIt<NostrProvider>()
              .sendEventToRelaysAsync(NostrEvent.fromPartialData(
                  kind: NOSTR_KIND_CONNECT,
                  keyPairs: signerKeypair,
                  content: JsonEncoder().convert({
                    'from': DateTime.now(),
                    'to': DateTime.now().add(Duration(days: 1)),
                    'cond': '',
                    'sig': ''
                  })));
          break;
      }
    });
  }
}

class MockRequestDelegation extends RequestDelegation {
  @override
  requestDelegation(NostrKeyPairs keyPair) {
    Stream<DelegationProgress> stream = super.requestDelegation(keyPair);
    // Mock signer sending ACK message with its own pubkey
    stream.listen((event) {
      if (event is LaunchedUrl) {
        getIt<NostrProvider>()
            .sendEventToRelaysAsync(NostrEvent.fromPartialData(
          kind: NOSTR_KIND_CONNECT,
          keyPairs: signerKeypair,
          content: 'ACK',
        ));
      }
    });
    return stream;
  }
}

void main() {
  setUp(() {
    // Reset the GetIt instance to its initial state before each test
    GetIt.I.reset();

    // Re-configure services for testing
    configureInjection(Env.test);
  });

  group('requestDelegation', () {
    setUp(() {
      getIt<SecureStorage>().set('keys', [localKeyPair.private]);

      mockDependency(MockNostProvider());
      mockDependency(MockRequestDelegation());
    });
    test('happy path', () {
      expect(
          RequestDelegation().requestDelegation(localKeyPair),
          emitsInOrder([
            isA<LaunchedUrl>(),
            isA<ReceivedAckMsg>(),
            isA<SendDescribeRequest>(),
            isA<ReceivedDescribeResponse>(),
            isA<SendDelegateRequest>(),
            isA<ReceivedDelegateResponse>(),
          ]));
    });
  });
}
