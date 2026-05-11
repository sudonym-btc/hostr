@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/metadata/metadata.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as hostr_requests;
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Nip01Event;
import 'package:test/test.dart';

void main() {
  group('Listings', () {
    test('ensures seller config before publishing a listing', () async {
      final calls = <String>[];
      final metadata = _FakeMetadata(calls);
      final requests = _FakeRequests(calls);
      final listings = Listings(
        requests: requests,
        logger: CustomLogger(),
        metadata: metadata,
      );
      final listing = _listing('host-pubkey');

      final result = await listings.upsert(listing);

      expect(result.responses, hasLength(1));
      expect(result.event.pubKey, listing.pubKey);
      expect(metadata.ensureCalls, ['host-pubkey']);
      expect(requests.broadcastedEvents, hasLength(1));
      expect(requests.broadcastedEvents.single.pubKey, listing.pubKey);
      expect(calls, ['ensureSellerConfig:host-pubkey', 'broadcast']);
    });

    test(
      'does not publish the listing when seller config setup fails',
      () async {
        final calls = <String>[];
        final failure = StateError('seller config unavailable');
        final metadata = _FakeMetadata(calls)..failure = failure;
        final requests = _FakeRequests(calls);
        final listings = Listings(
          requests: requests,
          logger: CustomLogger(),
          metadata: metadata,
        );

        await expectLater(
          listings.upsert(_listing('host-pubkey')),
          throwsA(same(failure)),
        );

        expect(metadata.ensureCalls, ['host-pubkey']);
        expect(requests.broadcastedEvents, isEmpty);
        expect(calls, ['ensureSellerConfig:host-pubkey']);
      },
    );

    test(
      'lists marketplace listings from the relay, not stale cache',
      () async {
        final calls = <String>[];
        final metadata = _FakeMetadata(calls);
        final requests = _FakeRequests(calls);
        final listings = Listings(
          requests: requests,
          logger: CustomLogger(),
          metadata: metadata,
        );

        await listings.list(Filter(limit: 5), name: 'test');

        expect(requests.queries, hasLength(1));
        expect(requests.queries.single.cacheRead, isFalse);
        expect(requests.queries.single.name, 'Listing-list-test');
        expect(requests.queries.single.filter.kinds, Listing.kinds);
        expect(requests.queries.single.filter.tags?['#t'], ['accommodation']);
      },
    );
  });
}

class _FakeMetadata extends Fake implements MetadataUseCase {
  final List<String> calls;
  final List<String> ensureCalls = [];
  Object? failure;

  _FakeMetadata(this.calls);

  @override
  Future<void> ensureSellerConfig(String pubkey) async {
    calls.add('ensureSellerConfig:$pubkey');
    ensureCalls.add(pubkey);
    final error = failure;
    if (error != null) throw error;
  }
}

class _FakeRequests extends Fake implements hostr_requests.Requests {
  final List<String> calls;
  final List<Nip01Event> broadcastedEvents = [];
  final List<_QueryCall> queries = [];

  _FakeRequests(this.calls);

  @override
  Future<hostr_requests.BroadcastResult> broadcastEvent({
    required Nip01Event event,
    List<String>? relays,
    hostr_requests.NostrEventSigner? signer,
  }) async {
    calls.add('broadcast');
    final eventToBroadcast = event.sig == null && signer != null
        ? await signer(event)
        : event;
    broadcastedEvents.add(eventToBroadcast);
    return hostr_requests.BroadcastResult(
      event: eventToBroadcast,
      responses: [
        RelayBroadcastResponse(
          relayUrl: 'wss://relay.hostr.test',
          okReceived: true,
          broadcastSuccessful: true,
        ),
      ],
    );
  }

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) {
    queries.add(_QueryCall(filter: filter, name: name, cacheRead: cacheRead));
    return const Stream.empty();
  }
}

class _QueryCall {
  const _QueryCall({
    required this.filter,
    required this.name,
    required this.cacheRead,
  });

  final Filter filter;
  final String? name;
  final bool cacheRead;
}

Listing _listing(String pubkey) {
  return Listing(
    pubKey: pubkey,
    createdAt: 1,
    tags: ListingTags(const [
      ['d', 'listing'],
      ['title', 'Test listing'],
    ]),
    content: 'Listing',
    sig: 'sig',
    id: 'listing-$pubkey',
  );
}
