import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../util/main.dart';
import '../auth/auth.dart';
import '../crud.usecase.dart';
import '../messaging/messaging.dart';

class Commitment {
  final String hash;

  Commitment({required this.hash});
}

@Singleton()
class Reservations extends CrudUseCase<Reservation> {
  final Messaging messaging;
  final Auth auth;
  StreamWithStatus<Reservation>? _myReservations;
  StreamSubscription<Reservation>? _myReservationsSubscription;
  Reservations({
    required super.requests,
    required super.logger,
    required this.messaging,
    required this.auth,
  }) : super(kind: Reservation.kinds[0]);

  Future<List<Reservation>> getListingReservations({
    required String listingAnchor,
  }) {
    logger.d('Fetching reservations for listing: $listingAnchor');
    return list(
      Filter(
        kinds: Reservation.kinds,
        tags: {
          kListingRefTag: [listingAnchor],
        },
      ),
    ).then((reservations) {
      logger.d('Found ${reservations.length} reservations');
      return reservations;
    });
  }

  groupByCommitment(List<Reservation> reservations, Listing listing) {
    final Map<String, List<Reservation>> grouped = {};
    for (final reservation in reservations) {
      final commitmentHash = reservation.parsedTags.commitmentHash;
      grouped.putIfAbsent(commitmentHash, () => []).add(reservation);
    }
    // Remove non-host reservation if a host reservation exists for same commitment hash
    for (final entry in grouped.entries) {
      final commitmentHash = entry.key;
      final group = entry.value;
      final hostReservations = group
          .where((reservation) => reservation.pubKey == listing.pubKey)
          .toList();
      if (hostReservations.isNotEmpty) {
        grouped[commitmentHash] = hostReservations;
      }
    }
    return grouped;
  }

  ValidatedStreamWithStatus<Reservation> subscribeValidatedForListing({
    required Listing listing,
    Duration debounce = const Duration(milliseconds: 350),
  }) {
    final source = subscribe(
      Filter(
        tags: {
          kListingRefTag: [listing.anchor!],
        },
      ),
    );

    return validateStream(
      source: source,
      debounce: debounce,
      closeSourceOnClose: true,
      validator: (snapshot) =>
          _validateListingSnapshot(listing: listing, reservations: snapshot),
    );
  }

  ValidatedStreamWithStatus<Reservation> subscribeUncancelledReservations({
    required Listing listing,
    Duration debounce = const Duration(milliseconds: 350),
  }) {
    final source = subscribe(
      Filter(
        tags: {
          kListingRefTag: [listing.anchor!],
        },
      ),
    );

    return validateStream(
      source: source,
      debounce: debounce,
      closeSourceOnClose: true,
      validator: (snapshot) {
        final trimmed = _trimCommitmentsWithCancellation(snapshot);
        return _validateListingSnapshot(
          listing: listing,
          reservations: trimmed,
        );
      },
    );
  }

  List<Reservation> _trimCommitmentsWithCancellation(
    List<Reservation> reservations,
  ) {
    final cancelledCommitments = reservations
        .where((reservation) => reservation.parsedContent.cancelled)
        .map((reservation) => reservation.parsedTags.commitmentHash)
        .toSet();

    if (cancelledCommitments.isEmpty) {
      return reservations;
    }

    return reservations
        .where(
          (reservation) => !cancelledCommitments.contains(
            reservation.parsedTags.commitmentHash,
          ),
        )
        .toList();
  }

  Future<List<Validation<Reservation>>> _validateListingSnapshot({
    required Listing listing,
    required List<Reservation> reservations,
  }) async {
    final grouped = <String, List<Reservation>>{};
    for (final reservation in reservations) {
      grouped
          .putIfAbsent(reservation.parsedTags.commitmentHash, () => [])
          .add(reservation);
    }

    final results = <Validation<Reservation>>[];
    final latestGuestsNeedingValidation = <String, Reservation>{};

    for (final entry in grouped.entries) {
      final group = [...entry.value]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final hostReservations = group
          .where((reservation) => reservation.pubKey == listing.pubKey)
          .toList();

      if (hostReservations.isNotEmpty) {
        // Host confirmation exists for this commitment hash.
        // Per product rules, skip guest proof validation and mark all valid.
        for (final reservation in group) {
          results.add(Valid(reservation));
        }
        continue;
      }

      final guestReservations = group
          .where((reservation) => reservation.pubKey != listing.pubKey)
          .toList();

      if (guestReservations.isEmpty) {
        for (final reservation in group) {
          results.add(
            Invalid(
              reservation,
              'No host confirmation and no guest reservation found for commitment hash',
            ),
          );
        }
        continue;
      }

      latestGuestsNeedingValidation[entry.key] = guestReservations.last;
    }

    // Batch point for RPC-based proof validation.
    // Today we use Reservation.validate(...), but this can be replaced with
    // batched EVM RPC checks keyed by commitment hash.
    final latestGuestValidation = <String, ValidationResult>{};
    for (final entry in latestGuestsNeedingValidation.entries) {
      latestGuestValidation[entry.key] = Reservation.validate(
        entry.value,
        listing,
      );
    }

    for (final entry in grouped.entries) {
      final commitmentHash = entry.key;
      final group = [...entry.value]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final hostExists = group.any(
        (reservation) => reservation.pubKey == listing.pubKey,
      );
      if (hostExists) {
        continue; // already appended above
      }

      final latestGuest = latestGuestsNeedingValidation[commitmentHash];
      if (latestGuest == null) {
        continue;
      }

      final validation = latestGuestValidation[commitmentHash];
      final reason = _validationReason(validation);

      for (final reservation in group) {
        if (reservation.id == latestGuest.id) {
          if (validation?.isValid == true) {
            results.add(Valid(reservation));
          } else {
            results.add(
              Invalid(reservation, reason ?? 'Reservation proof is invalid'),
            );
          }
        } else {
          results.add(
            Invalid(
              reservation,
              'Superseded by latest guest reservation for commitment hash',
            ),
          );
        }
      }
    }

    return results;
  }

  String? _validationReason(ValidationResult? result) {
    if (result == null || result.isValid) {
      return null;
    }

    for (final field in result.fields.values) {
      if (!field.ok) {
        return field.message;
      }
    }

    return 'Validation failed';
  }

  static Reservation? seniorReservations(
    List<Reservation> reservations,
    Listing listing,
  ) {
    return Reservation.getSeniorReservation(
      reservations: reservations,
      listing: listing,
    );
  }

  static List<Reservation> filterCancelled(List<Reservation> reservations) {
    return reservations.where((e) => !e.parsedContent.cancelled).toList();
  }

  Map<String, ({Reservation? sellerReservation, Reservation? buyerReservation})>
  groupByThread(List<Reservation> reservations) {
    final temp =
        <
          String,
          ({Reservation? sellerReservation, Reservation? buyerReservation})
        >{};

    for (final reservation in reservations) {
      final thread =
          messaging.threads.threads[reservation.parsedTags.commitmentHash];
      if (thread == null) continue;

      final sellerPubKey = getPubKeyFromAnchor(
        thread.state.value.lastReservationRequest.parsedTags.listingAnchor,
      );

      final current =
          temp[reservation.parsedTags.commitmentHash] ??
          (sellerReservation: null, buyerReservation: null);

      if (reservation.pubKey == sellerPubKey) {
        temp[reservation.parsedTags.commitmentHash] = (
          sellerReservation: reservation,
          buyerReservation: current.buyerReservation,
        );
      } else {
        temp[reservation.parsedTags.commitmentHash] = (
          sellerReservation: current.sellerReservation,
          buyerReservation: reservation,
        );
      }
    }
    return temp;
  }

  StreamWithStatus<Reservation> subscribeToMyReservations() {
    if (_myReservations != null) {
      return _myReservations!;
    }

    final response = StreamWithStatus<Reservation>();
    response.addStatus(StreamStatusLive());

    _myReservations = response;

    final reservationsStream = messaging.threads.subscription!.replay
        .where((message) => message.child is ReservationRequest)
        .map((message) => message.child as ReservationRequest)
        .asyncMap((reservationRequest) async {
          logger.d(
            'Processing reservation request: $reservationRequest, ${reservationRequest.getFirstTag('a')}',
          );
          final reservations = await getListingReservations(
            listingAnchor: reservationRequest.parsedTags.listingAnchor,
          );
          logger.d('Found reservations: $reservations');
          return reservations.firstWhere(
            (reservation) =>
                reservation.parsedTags.commitmentHash ==
                ParticipationProof.computeCommitmentHash(
                  auth.activeKeyPair!.publicKey,
                  reservationRequest.parsedContent.salt,
                ),
            orElse: () => throw Exception('Reservation not found'),
          );
        })
        .distinct((a, b) => a.id == b.id);

    _myReservationsSubscription?.cancel();
    _myReservationsSubscription = reservationsStream.listen(
      response.add,
      onError: response.addError,
    );

    return response;
  }

  Future<List<RelayBroadcastResponse>> accept(
    String anchor,
    ReservationRequest request,
    String guestPubkey,
    String saltedPubkey,
  ) {
    final reservation = Reservation(
      tags: ReservationTags([
        ['p', saltedPubkey],
        [kListingRefTag, request.parsedTags.listingAnchor],
        [kThreadRefTag, anchor],
        [
          kCommitmentHashTag,
          ParticipationProof.computeCommitmentHash(
            guestPubkey,
            request.parsedContent.salt,
          ),
        ],
      ]),
      content: ReservationContent(
        start: request.parsedContent.start,
        end: request.parsedContent.end,
      ),
      pubKey: auth.activeKeyPair!.publicKey,
    );
    logger.d('Accepting reservation request: $request');
    return upsert(reservation);
  }

  Future<Reservation> createSelfSigned({
    required KeyPair activeKeyPair,
    required ReservationRequest reservationRequest,
    required PaymentProof proof,
  }) async {
    String commitment = ParticipationProof.computeCommitmentHash(
      auth.activeKeyPair!.publicKey,
      reservationRequest.parsedContent.salt,
    );

    Reservation reservation = Reservation(
      content: ReservationContent(
        start: reservationRequest.parsedContent.start,
        end: reservationRequest.parsedContent.end,
        proof: proof,
      ),
      pubKey: activeKeyPair.publicKey,
      tags: ReservationTags([
        [kListingRefTag, proof.listing.anchor!],
        [kCommitmentHashTag, commitment],
      ]),
    );

    await upsert(reservation.signAs(activeKeyPair, Reservation.fromNostrEvent));
    logger.d('Created self-signed reservation: $reservation');
    return reservation;
  }

  Future<Reservation> cancel(Reservation reservation) async {
    if (reservation.parsedContent.cancelled) {
      throw Exception('Reservation is already cancelled');
    }
    final updated = reservation.copy(
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      id: null,
      content: reservation.parsedContent.copyWith(cancelled: true),
      pubKey: null,
    );
    logger.d('Cancelling reservation: $updated');
    await upsert(updated);
    return updated;
  }

  Future<Reservation> createBlocked({
    required String listingAnchor,
    required DateTime start,
    required DateTime end,
  }) async {
    final reservation = Reservation(
      content: ReservationContent(start: start, end: end),
      pubKey: auth.activeKeyPair!.publicKey,
      tags: ReservationTags([
        [kListingRefTag, listingAnchor],
        [
          kCommitmentHashTag,
          ParticipationProof.computeCommitmentHash(
            auth.activeKeyPair!.publicKey,
            Reservation.getSaltForBlockedReservation(
              start: start,
              end: end,
              hostKey: auth.activeKeyPair!,
            ),
          ),
        ],
      ]),
    );

    await upsert(reservation);
    logger.d('Created blocked reservation: $reservation');
    return reservation;
  }

  void dispose() {
    _myReservations?.close();
    _myReservations = null;
    _myReservationsSubscription?.cancel();
    _myReservationsSubscription = null;
  }
}
