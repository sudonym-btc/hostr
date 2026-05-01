@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/identity_claims/identity_claims.dart';
import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as hostr_requests;
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Nip01Event;
import 'package:test/test.dart';

void main() {
  group('Listings', () {
    test('ensures EVM identity before publishing a listing', () async {
      final calls = <String>[];
      final identityClaims = _FakeIdentityClaims(calls);
      final requests = _FakeRequests(calls);
      final listings = Listings(
        requests: requests,
        logger: CustomLogger(),
        identityClaims: identityClaims,
      );
      final listing = _listing('host-pubkey');

      final result = await listings.upsert(listing);

      expect(result, hasLength(1));
      expect(identityClaims.ensureCalls, 1);
      expect(requests.broadcastedEvents, hasLength(1));
      expect(requests.broadcastedEvents.single, same(listing));
      expect(calls, ['ensureEvmAddress', 'broadcast']);
    });

    test(
      'does not publish the listing when EVM identity setup fails',
      () async {
        final calls = <String>[];
        final failure = StateError('identity unavailable');
        final identityClaims = _FakeIdentityClaims(calls)..failure = failure;
        final requests = _FakeRequests(calls);
        final listings = Listings(
          requests: requests,
          logger: CustomLogger(),
          identityClaims: identityClaims,
        );

        await expectLater(
          listings.upsert(_listing('host-pubkey')),
          throwsA(same(failure)),
        );

        expect(identityClaims.ensureCalls, 1);
        expect(requests.broadcastedEvents, isEmpty);
        expect(calls, ['ensureEvmAddress']);
      },
    );
  });
}

class _FakeIdentityClaims extends Fake implements IdentityClaimsUseCase {
  final List<String> calls;
  int ensureCalls = 0;
  Object? failure;

  _FakeIdentityClaims(this.calls);

  @override
  Future<IdentityClaims?> ensureEvmAddress() async {
    calls.add('ensureEvmAddress');
    ensureCalls++;
    final error = failure;
    if (error != null) throw error;
    return null;
  }
}

class _FakeRequests extends Fake implements hostr_requests.Requests {
  final List<String> calls;
  final List<Nip01Event> broadcastedEvents = [];

  _FakeRequests(this.calls);

  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) async {
    calls.add('broadcast');
    broadcastedEvents.add(event);
    return [
      RelayBroadcastResponse(
        relayUrl: 'wss://relay.hostr.test',
        okReceived: true,
        broadcastSuccessful: true,
      ),
    ];
  }

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) => const Stream.empty();
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
