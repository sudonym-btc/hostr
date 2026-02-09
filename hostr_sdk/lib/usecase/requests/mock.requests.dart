import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/datasources/main.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/domain_layer/entities/nip_01_utils.dart';
import 'package:ndk/entities.dart' show Nip65, ReadWriteMarker;
import 'package:ndk/ndk.dart' show Nip01Event, Filter;
import 'package:rxdart/rxdart.dart';

import 'requests.dart';

class _Subscription<T extends Nip01Event> {
  final String id;
  final Filter filter;
  final BehaviorSubject<T> controller;

  _Subscription({
    required this.id,
    required this.filter,
    required this.controller,
  });
}

// @Singleton(as: Requests, env: [Env.mock])
class MockRequests extends Requests {
  MockRequests({required super.ndk});

  @override
  mock() async {
    MockBlossomServer blossomServer = MockBlossomServer();
    await blossomServer.start();
    MockRelay mockRelay = MockRelay(
      name: "Mock Relay",
      explicitPort: 5432,
      events: [
        ...await MOCK_EVENTS(),

        /// Preferred relay lists
        Nip01Utils.signWithPrivateKey(
          privateKey: MockKeys.guest.privateKey!,
          event: Nip65(
            pubKey: MockKeys.guest.publicKey,
            relays: {
              getIt<HostrConfig>().bootstrapRelays[0]:
                  ReadWriteMarker.readWrite,
            },
            createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
          ).toEvent(),
        ),
        Nip01Utils.signWithPrivateKey(
          privateKey: MockKeys.hoster.privateKey!,
          event: Nip65(
            pubKey: MockKeys.hoster.publicKey,
            relays: {
              getIt<HostrConfig>().bootstrapRelays[0]:
                  ReadWriteMarker.readWrite,
            },
            createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
          ).toEvent(),
        ),
        Nip01Utils.signWithPrivateKey(
          privateKey: MockKeys.escrow.privateKey!,
          event: Nip65(
            pubKey: MockKeys.escrow.publicKey,
            relays: {
              getIt<HostrConfig>().bootstrapRelays[0]:
                  ReadWriteMarker.readWrite,
            },
            createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
          ).toEvent(),
        ),
      ],
    );
    await mockRelay.startServer();
  }
}
