@Tags(['unit'])
library;

import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/dm_relays/dm_relays.dart';
import 'package:hostr_sdk/usecase/messaging/messaging.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart' show Accounts, Ndk;
import 'package:test/test.dart';

class _FakeAccounts extends Fake implements Accounts {
  @override
  String? getPublicKey() => MockKeys.guest.publicKey;
}

class _FakeNdk extends Fake implements Ndk {
  @override
  Accounts get accounts => _FakeAccounts();
}

class _FakeRequests extends Fake implements Requests {}

class _FakeDmRelays extends Fake implements DmRelays {}

void main() {
  late Messaging messaging;

  setUp(() {
    messaging = Messaging(
      _FakeNdk(),
      _FakeRequests(),
      _FakeDmRelays(),
      CustomLogger(),
    );
  });

  test('getRumour creates kind 14 text DM rumors', () async {
    final rumor = await messaging.getRumour(
      'hello',
      [
        [kConversationTag, 'trade-1'],
      ],
      [MockKeys.hoster.publicKey],
    );

    expect(rumor.kind, kNostrKindDM);
    expect(rumor.content, 'hello');
    expect(rumor.tags, contains(equals([kConversationTag, 'trade-1'])));
    expect(rumor.tags, contains(equals(['p', MockKeys.hoster.publicKey])));
    expect(
      rumor.tags.where((tag) => tag.isNotEmpty && tag.first == 'alt'),
      isEmpty,
    );
  });

  test('getJsonRumour creates kind 1327 JSON message rumors', () async {
    final factory = EntityFactory(defaultSigner: MockKeys.guest);
    final child = await factory.order(
      listing: factory.listing(signer: MockKeys.hoster),
    );

    final rumor = await messaging.getJsonRumour(
      child.toString(),
      [
        [kConversationTag, 'trade-1'],
      ],
      [MockKeys.hoster.publicKey],
      altText: 'Order Proposal',
    );

    expect(rumor.kind, kNostrKindJsonMessage);
    expect(Message.parseChild(rumor), isA<Order>());
    expect(rumor.tags, contains(equals([kConversationTag, 'trade-1'])));
    expect(rumor.tags, contains(equals(['alt', 'Order Proposal'])));
    expect(rumor.tags, contains(equals(['p', MockKeys.hoster.publicKey])));
  });

  test('getJsonRumour preserves caller-provided alt text', () async {
    final rumor = await messaging.getJsonRumour(
      '{"kind":32122}',
      [
        [kConversationTag, 'trade-1'],
        ['alt', 'Custom Label'],
      ],
      [MockKeys.hoster.publicKey],
      altText: 'Order Proposal',
    );

    expect(rumor.kind, kNostrKindJsonMessage);
    expect(rumor.tags.where((tag) => tag.isNotEmpty && tag.first == 'alt'), [
      ['alt', 'Custom Label'],
    ]);
  });
}
