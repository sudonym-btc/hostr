@Tags(['unit'])
library;

import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/reservations/reservations.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../../support/fakes.dart';

final _f = EntityFactory();

Future<Reservation> _reservation({
  required Listing listing,
  required KeyPair signer,
  required String tradeId,
  required DateTime start,
  required DateTime end,
  PaymentProof? proof,
  ReservationStage stage = ReservationStage.negotiate,
  int createdAtOffsetSeconds = 0,
}) => _f.reservation(
  listing: listing,
  dTag: tradeId,
  signerOverride: signer,
  start: start,
  end: end,
  proof: proof,
  stage: stage,
  createdAt:
      DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000 +
      createdAtOffsetSeconds,
);

Listing _fixtureListing() => _f.listing(
  signer: MockKeys.hoster,
  dTag: 'unit-listing',
  title: 'Unit Listing',
  description: 'Fixture',
  images: const [],
  priceSats: 100000,
  location: 'Test',
  type: ListingType.house,
  amenities: Amenities(),
);

void main() {
  group('Listing availability with mock data', () {
    late FakeRelayRequests relay;
    late Reservations usecase;
    late Listing listing;
    late DateTime start;
    late DateTime end;

    setUp(() {
      relay = FakeRelayRequests();
      usecase = Reservations(
        requests: relay,
        logger: CustomLogger(),
        messaging: FakeMessaging(),
        auth: FakeAuth(),
        transitions: FakeTransitions(),
        listings: Listings(requests: relay, logger: CustomLogger()),
      );
      listing = _fixtureListing();
      start = DateTime(2026, 2, 1);
      end = DateTime(2026, 2, 3);
    });

    tearDown(() async {
      await relay.close();
    });

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

        final keep = await _reservation(
          listing: listing,
          signer: MockKeys.hoster,
          tradeId: keepCommitment,
          start: start,
          end: end,
          proof: null,
        );

        final droppedOriginal = await _reservation(
          listing: listing,
          signer: MockKeys.guest,
          tradeId: dropCommitment,
          start: start,
          end: end,
          proof: null,
        );

        final droppedCancelled = await _reservation(
          listing: listing,
          signer: MockKeys.hoster,
          tradeId: dropCommitment,
          start: start,
          end: end,
          stage: ReservationStage.cancel,
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
        final snapshot = validated.items;

        final survivingCommitments = snapshot
            .map((v) => v.event.getDtag())
            .toSet();

        expect(survivingCommitments.contains(keepCommitment), isTrue);
        expect(survivingCommitments.contains(dropCommitment), isFalse);

        await validated.close();
      },
    );
  });
}
