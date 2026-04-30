@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/escrow_daemon/escrow_daemon.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

Reservation _reservation() => Reservation.create(
  pubKey: MockKeys.guest.publicKey,
  dTag: 'trade-startup-replay',
  listingAnchor: '32121:${MockKeys.hoster.publicKey}:listing-1',
  pTags: [
    PTag.seller(MockKeys.hoster.publicKey),
    PTag.buyer(MockKeys.guest.publicKey),
    PTag.escrow(MockKeys.escrow.publicKey),
  ],
  stage: ReservationStage.commit,
  start: DateTime.utc(2026, 5, 1),
  end: DateTime.utc(2026, 5, 2),
);

void main() {
  test(
    'reservation listener events replay reservations collected before listener attaches',
    () async {
      final source = StreamWithStatus<Reservation>();
      final reservation = _reservation();

      source.add(reservation);

      await expectLater(
        EscrowDaemon.reservationListenerEvents(source).take(1),
        emits(predicate<Reservation>((event) => event.id == reservation.id)),
      );
    },
  );

  test('missing funded-event verification failures are retried', () {
    expect(
      EscrowDaemon.isRetryableReservationVerificationFailure(
        'Escrow logs do not contain a funding event for trade trade-1 in 0xabc',
      ),
      isTrue,
    );
    expect(
      EscrowDaemon.isRetryableReservationVerificationFailure(
        'Failed to query escrow logs for trade trade-1: timeout',
      ),
      isTrue,
    );
    expect(
      EscrowDaemon.isRetryableReservationVerificationFailure(
        'Onchain escrowed amount (1) is less than expected listing amount (2)',
      ),
      isFalse,
    );
  });

  test('reservation trade id is extracted from d tag', () {
    expect(
      EscrowDaemon.reservationTradeId(_reservation()),
      'trade-startup-replay',
    );
  });

  test('reservation group involvement is based on escrow participant tags', () {
    final withEscrow = ReservationGroup.fromReservation(_reservation());
    final withoutEscrow = ReservationGroup.fromReservation(
      Reservation.create(
        pubKey: MockKeys.guest.publicKey,
        dTag: 'trade-no-escrow',
        listingAnchor: '32121:${MockKeys.hoster.publicKey}:listing-1',
        pTags: [
          PTag.seller(MockKeys.hoster.publicKey),
          PTag.buyer(MockKeys.guest.publicKey),
        ],
        stage: ReservationStage.commit,
      ),
    );

    expect(
      EscrowDaemon.reservationGroupInvolvesEscrow(
        withEscrow,
        MockKeys.escrow.publicKey,
      ),
      isTrue,
    );
    expect(
      EscrowDaemon.reservationGroupInvolvesEscrow(
        withoutEscrow,
        MockKeys.escrow.publicKey,
      ),
      isFalse,
    );
  });
}
