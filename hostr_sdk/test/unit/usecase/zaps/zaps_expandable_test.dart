@Tags(['unit'])
library;

import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/datasources/app_database.dart';
import 'package:hostr_sdk/usecase/evm/config/evm_config.dart';
import 'package:hostr_sdk/usecase/nwc/nwc.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/usecase/zaps/zaps.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/ndk.dart' hide Nwc, Requests, Zaps;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

void main() {
  test('expandable zap receipts expand one relay subscription', () async {
    final db = AppDatabase(sqlite3.sqlite3.openInMemory());
    addTearDown(db.db.close);

    final requests = _CapturingRequests();
    final zaps = Zaps(
      nwc: _FakeNwc(),
      ndk: _FakeNdk(),
      config: HostrConfig(
        bootstrapRelays: const ['wss://zap.relay'],
        bootstrapBlossom: const [],
        hostrRelay: 'wss://hostr.relay',
        evmConfig: const EvmConfig(),
        appDatabase: db,
      ),
      requests: requests,
      logger: CustomLogger(),
    );
    final filters = StreamWithStatus<Filter>();
    final subscription = zaps.createExpandableZapReceipts(
      name: 'ZapReceipts-sub',
      debounceDuration: Duration.zero,
    );

    await zaps.startExpandableZapReceipts(subscription, filters);
    filters.add(Filter(pTags: const ['seller-a'], eTags: const ['trade-1']));
    filters.addStatus(StreamStatusLive());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(requests.queryFilters, hasLength(1));
    expect(requests.liveFilters, hasLength(1));
    expect(requests.queryRelays.single, const ['wss://zap.relay']);
    expect(requests.liveRelays.single, const ['wss://zap.relay']);
    expect(requests.queryFilters.single.kinds, const [ZapReceipt.kKind]);
    expect(requests.queryFilters.single.pTags, const ['seller-a']);
    expect(requests.queryFilters.single.eTags, const ['trade-1']);

    filters.add(
      Filter(
        pTags: const ['seller-a', 'seller-b'],
        eTags: const ['trade-1', 'trade-2'],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(requests.queryFilters, hasLength(2));
    expect(requests.liveFilters, hasLength(2));
    expect(requests.queryFilters.last.kinds, const [ZapReceipt.kKind]);
    expect(requests.queryFilters.last.pTags, const ['seller-a', 'seller-b']);
    expect(requests.queryFilters.last.eTags, const ['trade-1', 'trade-2']);

    await subscription.close();
    await filters.close();
  });
}

class _FakeNwc extends Fake implements Nwc {}

class _FakeNdk extends Fake implements Ndk {}

class _CapturingRequests extends Fake implements Requests {
  final List<Filter> queryFilters = [];
  final List<List<String>?> queryRelays = [];
  final List<Filter> liveFilters = [];
  final List<List<String>?> liveRelays = [];

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) {
    queryFilters.add(filter);
    queryRelays.add(relays);
    return Stream<T>.empty();
  }

  @override
  LiveSubscriptionHandle liveSubscription<T extends Nip01Event>({
    required Filter filter,
    required void Function(T event) onData,
    void Function(Object error, StackTrace? stackTrace)? onError,
    required String name,
    List<String>? relays,
  }) {
    liveFilters.add(filter);
    liveRelays.add(relays);
    return LiveSubscriptionHandle(() async {}, name);
  }
}
