import 'package:models/stubs/main.dart';

import 'reservation_builders.dart';

final List<ReservationScenario> MOCK_RESERVATION_SCENARIOS = [
  () {
    final listing = MOCK_LISTINGS.first;
    final request = buildReservationRequestForScenario(
      listing: listing,
      sender: MockKeys.guest,
      dTag: 'reservation-host-confirmed',
    );
    final reservation = buildReservationForScenario(
      listing: listing,
      request: request,
      signer: MockKeys.hoster,
      dTag: 'host-confirmed',
    );

    return ReservationScenario(
      id: 'host-confirmed',
      description: 'Host-published reservation is valid',
      listing: listing,
      request: request,
      reservation: reservation,
      isValid: true,
    );
  }(),
  () {
    final listing = MOCK_LISTINGS.first;
    final request = buildReservationRequestForScenario(
      listing: listing,
      sender: MockKeys.guest,
      dTag: 'reservation-self-no-proof',
    );
    final reservation = buildReservationForScenario(
      listing: listing,
      request: request,
      signer: MockKeys.guest,
      dTag: 'self-no-proof',
    );

    return ReservationScenario(
      id: 'self-no-proof',
      description: 'Guest self-published reservation without proof',
      listing: listing,
      request: request,
      reservation: reservation,
      isValid: false,
      expectedError:
          'Must include a payment proof if self-publishing reservation event',
    );
  }(),
  () {
    final listing = MOCK_LISTINGS.first;
    final request = buildReservationRequestForScenario(
      listing: listing,
      sender: MockKeys.guest,
      dTag: 'reservation-self-requires-escrow',
    );
    final proof = buildSelfSignedProof(listing: listing);
    final reservation = buildReservationForScenario(
      listing: listing,
      request: request,
      signer: MockKeys.guest,
      dTag: 'self-requires-escrow',
      proof: proof,
    );

    return ReservationScenario(
      id: 'self-requires-escrow',
      description: 'Guest self-signed proof but listing requires escrow',
      listing: listing,
      request: request,
      reservation: reservation,
      isValid: false,
      expectedError: 'Listing requires escrow for guest reservations',
    );
  }(),
];
