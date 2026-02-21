import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/messaging/messaging.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as hostr_requests;
import 'package:hostr_sdk/usecase/reservations/reservations.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01Event, Nip01EventModel;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

class _FakeMessaging extends Fake implements Messaging {}

class _FakeAuth extends Fake implements Auth {}

/// In-memory fake relay source for reservation subscriptions.
class _FakeRelayRequests extends Fake implements hostr_requests.Requests {
  final StreamWithStatus<Reservation> _source = StreamWithStatus<Reservation>();

  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
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
  required String commitmentHash,
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
      [kCommitmentHashTag, commitmentHash],
    ]),
    content: ReservationContent(
      start: start,
      end: end,
      proof: proof,
      cancelled: cancelled,
    ),
  ).signAs(signer, Reservation.fromNostrEvent);
}

PaymentProof _zapProofFromStubReceipt({required Listing listing}) {
  return PaymentProof(
    hoster: MOCK_PROFILES.first,
    listing: listing,
    zapProof: ZapProof(
      receipt: Nip01EventModel.fromEntity(MOCK_ZAP_RECEIPTS.first),
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
      );
      listing = MOCK_LISTINGS.first;
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
