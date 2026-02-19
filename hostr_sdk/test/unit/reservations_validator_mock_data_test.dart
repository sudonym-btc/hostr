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
  group('Reservations validator with mock data', () {
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
      'zap proof: marks invalid when receipt details are insufficient',
      () async {
        final commitment = ParticipationProof.computeCommitmentHash(
          MockKeys.guest.publicKey,
          'salt-zap-insufficient',
        );

        final reservation = _reservation(
          listing: listing,
          signer: MockKeys.guest,
          commitmentHash: commitment,
          start: start,
          end: end,
          proof: _zapProofFromStubReceipt(listing: listing),
        );

        final validated = usecase.subscribeValidatedForListing(
          listing: listing,
          debounce: Duration.zero,
        );

        relay.emitStatus(StreamStatusLive());
        relay.emit(reservation);

        await Future<void>.delayed(const Duration(milliseconds: 200));
        final snapshot = validated.list.value;
        expect(snapshot.single, isA<Invalid<Reservation>>());
        expect((snapshot.single as Invalid<Reservation>).reason, isNotEmpty);

        await validated.close();
      },
    );

    test(
      'zap proof: validates when amount and recipient are correct',
      () async {},
      skip:
          'Sketch pending: needs deterministic, parser-compatible fully valid zap receipt fixture',
    );

    test(
      'host confirmation in same commitment hash bypasses self-signed validation',
      () async {
        final commitment = ParticipationProof.computeCommitmentHash(
          MockKeys.guest.publicKey,
          'salt-host-wins',
        );

        // Intentionally invalid self-signed reservation (missing proof).
        final guestReservation = _reservation(
          listing: listing,
          signer: MockKeys.guest,
          commitmentHash: commitment,
          start: start,
          end: end,
          proof: null,
          createdAtOffsetSeconds: 1,
        );

        final hostReservation = _reservation(
          listing: listing,
          signer: MockKeys.hoster,
          commitmentHash: commitment,
          start: start,
          end: end,
          proof: null,
          createdAtOffsetSeconds: 2,
        );

        final validated = usecase.subscribeValidatedForListing(
          listing: listing,
          debounce: Duration.zero,
        );

        relay.emitStatus(StreamStatusLive());
        relay.emit(guestReservation);
        relay.emit(hostReservation);

        final snapshot = await validated.stream.firstWhere(
          (s) => s.length >= 2 && s.every((v) => v is Valid<Reservation>),
        );

        expect(snapshot.length, 2);
        expect(snapshot.every((v) => v is Valid<Reservation>), isTrue);

        await validated.close();
      },
    );

    test(
      'cancelled commitment hash is skipped by subscribeUncancelledReservations',
      () async {
        final keepCommitment = ParticipationProof.computeCommitmentHash(
          MockKeys.guest.publicKey,
          'salt-keep',
        );
        final dropCommitment = ParticipationProof.computeCommitmentHash(
          MockKeys.guest.publicKey,
          'salt-drop',
        );

        final keep = _reservation(
          listing: listing,
          signer: MockKeys.hoster,
          commitmentHash: keepCommitment,
          start: start,
          end: end,
          proof: null,
        );

        final droppedOriginal = _reservation(
          listing: listing,
          signer: MockKeys.guest,
          commitmentHash: dropCommitment,
          start: start,
          end: end,
          proof: null,
        );

        final droppedCancelled = _reservation(
          listing: listing,
          signer: MockKeys.hoster,
          commitmentHash: dropCommitment,
          start: start,
          end: end,
          cancelled: true,
        );

        final validated = usecase.subscribeUncancelledReservations(
          listing: listing,
          debounce: Duration.zero,
        );

        relay.emitStatus(StreamStatusLive());
        relay.emit(keep);
        relay.emit(droppedOriginal);
        relay.emit(droppedCancelled);

        await Future<void>.delayed(const Duration(milliseconds: 200));
        final snapshot = validated.list.value;

        final survivingCommitments = snapshot
            .map((v) => v.event.parsedTags.commitmentHash)
            .toSet();

        expect(survivingCommitments.contains(keepCommitment), isTrue);
        expect(survivingCommitments.contains(dropCommitment), isFalse);

        await validated.close();
      },
    );

    test(
      'escrow proof: fails when tx amount is too low',
      () async {
        // Sketch only: requires Reservation.validate escrow branch to consume
        // a pluggable RPC validator and return field-level failures.
        final rpc = _FakeEscrowRpc({
          '0xlow': (amount: BigInt.from(1), to: '0xescrow', ok: true),
        });
        expect(rpc.txByHash['0xlow']!.amount, BigInt.from(1));
      },
      skip:
          'Escrow proof validation is TODO in models/lib/nostr/reservation.dart',
    );

    test(
      'escrow proof: fails when host trusted-escrow signature missing/invalid',
      () async {},
      skip:
          'Escrow proof validation is TODO in models/lib/nostr/reservation.dart',
    );

    test(
      'escrow proof: fails when arbiter address mismatches trusted escrow',
      () async {},
      skip:
          'Escrow proof validation is TODO in models/lib/nostr/reservation.dart',
    );

    test(
      'escrow proof: fails when tx receipt status is failed',
      () async {},
      skip:
          'Escrow proof validation is TODO in models/lib/nostr/reservation.dart',
    );
  });
}
