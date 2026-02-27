@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/messaging/messaging.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as hostr_requests;
import 'package:hostr_sdk/usecase/reservation_transitions/reservation_transitions.dart';
import 'package:hostr_sdk/usecase/reservations/reservations.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart'
    show Filter, Nip01Event, Nip01EventModel, Nip01Utils;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

class _FakeMessaging extends Fake implements Messaging {}

class _FakeAuth extends Fake implements Auth {}

class _FakeTransitions extends Fake implements ReservationTransitions {}

/// In-memory fake relay source for reservation subscriptions.
class _FakeRelayRequests extends Fake implements hostr_requests.Requests {
  final StreamWithStatus<Reservation> _source = StreamWithStatus<Reservation>();

  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
  }) {
    return _source as StreamWithStatus<T>;
  }

  void emit(Reservation event) => _source.add(event);

  void emitStatus(StreamStatus status) => _source.addStatus(status);

  Future<void> close() => _source.close();
}

/// Placeholder fake RPC client shape for escrow validation scenarios.
class _FakeEscrowRpc {
  final Map<String, ({BigInt amount, String to, bool ok})> txByHash;

  _FakeEscrowRpc(this.txByHash);
}

Reservation _reservation({
  required Listing listing,
  required KeyPair signer,
  required String tradeId,
  required DateTime start,
  required DateTime end,
  PaymentProof? proof,
  bool cancelled = false,
  int createdAtOffsetSeconds = 0,
}) {
  return Reservation(
    pubKey: signer.publicKey,
    createdAt:
        DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000 +
        createdAtOffsetSeconds,
    tags: ReservationTags([
      [kListingRefTag, listing.anchor!],
      ['d', tradeId],
    ]),
    content: ReservationContent(
      start: start,
      end: end,
      proof: proof,
      cancelled: cancelled,
    ),
  ).signAs(signer, Reservation.fromNostrEvent);
}

Listing _fixtureListing() {
  return Listing(
    pubKey: MockKeys.hoster.publicKey,
    tags: EventTags([
      ['d', 'unit-listing'],
    ]),
    content: ListingContent(
      title: 'Unit Listing',
      description: 'Fixture',
      price: [
        Price(
          amount: Amount(currency: Currency.BTC, value: BigInt.from(100000)),
          frequency: Frequency.daily,
        ),
      ],
      allowBarter: false,
      minStay: const Duration(days: 1),
      checkIn: TimeOfDay(hour: 15, minute: 0),
      checkOut: TimeOfDay(hour: 11, minute: 0),
      location: 'Test',
      quantity: 1,
      type: ListingType.house,
      images: const [],
      amenities: Amenities(),
      requiresEscrow: false,
    ),
  ).signAs(MockKeys.hoster, Listing.fromNostrEvent);
}

Nip01Event _fixtureHostProfile() {
  return Nip01Utils.signWithPrivateKey(
    event: Nip01Event(
      kind: kNostrKindProfile,
      pubKey: MockKeys.hoster.publicKey,
      tags: const [],
      content: '{"name":"host","lud16":"host@hostr.development"}',
    ),
    privateKey: MockKeys.hoster.privateKey!,
  );
}

Nip01Event _fixtureZapReceipt() {
  return Nip01Utils.signWithPrivateKey(
    event: Nip01Event(
      kind: kNostrKindZapReceipt,
      pubKey: MockKeys.hoster.publicKey,
      tags: [
        ['p', MockKeys.hoster.publicKey],
        ['bolt11', 'lnbc1000n1punit'],
        [
          'description',
          '{"tags":[["amount","1000"],["lnurl","host@hostr.development"]]}',
        ],
      ],
      content: '',
    ),
    privateKey: MockKeys.hoster.privateKey!,
  );
}

PaymentProof _zapProofFromStubReceipt({required Listing listing}) {
  return PaymentProof(
    hoster: _fixtureHostProfile(),
    listing: listing,
    zapProof: ZapProof(
      receipt: Nip01EventModel.fromEntity(_fixtureZapReceipt()),
    ),
    escrowProof: null,
  );
}

void main() {
  group('Listing availability with mock data', () {
    late _FakeRelayRequests relay;
    late Reservations usecase;
    late Listing listing;
    late DateTime start;
    late DateTime end;

    setUp(() {
      relay = _FakeRelayRequests();
      usecase = Reservations(
        requests: relay,
        logger: CustomLogger(),
        messaging: _FakeMessaging(),
        auth: _FakeAuth(),
        transitions: _FakeTransitions(),
      );
      listing = _fixtureListing();
      start = DateTime(2026, 2, 1);
      end = DateTime(2026, 2, 3);
    });

    tearDown(() async {
      await relay.close();
    });

    test(
      'zap proof: validates when amount and recipient are correct',
      () async {},
      skip:
          'Sketch pending: needs deterministic, parser-compatible fully valid zap receipt fixture',
    );
  });
}
