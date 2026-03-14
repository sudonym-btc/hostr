@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/gift_wraps/gift_wraps.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as hostr_requests;
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart'
    show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Ndk, Nip01Event;
import 'package:test/test.dart';

class _FakeNdk extends Fake implements Ndk {}

class _FakeRequests extends Fake implements hostr_requests.Requests {
  final StreamWithStatus<Nip01Event> source = StreamWithStatus<Nip01Event>();
  Filter? lastSubscribeFilter;
  Type? lastSubscribeType;
  Nip01Event? lastBroadcastEvent;

  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
  }) {
    lastSubscribeFilter = filter;
    lastSubscribeType = T;
    return source as StreamWithStatus<T>;
  }

  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) async {
    lastBroadcastEvent = event;
    return const [];
  }
}

void main() {
  late GiftWraps giftWraps;
  late _FakeRequests requests;

  setUp(() {
    requests = _FakeRequests();
    giftWraps = GiftWraps(
      ndk: _FakeNdk(),
      requests: requests,
      logger: CustomLogger(),
    );
  });

  tearDown(() async {
    await requests.source.close();
  });

  test('subscribeParsed adds the giftwrap kind filter', () {
    giftWraps.subscribeParsed(Filter(pTags: ['pubkey']));

    expect(requests.lastSubscribeFilter?.kinds, [kNostrKindGiftWrap]);
    expect(requests.lastSubscribeFilter?.pTags, ['pubkey']);
    expect(requests.lastSubscribeType, Nip01Event);
  });
}
