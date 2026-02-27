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
import '../reservation_transitions/reservation_transitions.dart';

class Commitment {
  final String hash;

  Commitment({required this.hash});
}

@Singleton()
class Reservations extends CrudUseCase<Reservation> {
  final Messaging messaging;
  final Auth auth;
  final ReservationTransitions transitions;
  StreamWithStatus<Reservation>? _myReservations;
  StreamSubscription<Reservation>? _myReservationsSubscription;
  Reservations({
    required super.requests,
    required super.logger,
    required this.messaging,
    required this.auth,
    required this.transitions,
  }) : super(kind: Reservation.kinds[0]);

  /// Query all reservations for a given trade id (d-tag).
  Future<List<Reservation>> getByTradeId(String tradeId) {
    logger.d('Fetching reservations for tradeId: $tradeId');
    return list(
      Filter(kinds: Reservation.kinds, dTags: [tradeId]),
      name: 'byTradeId-$tradeId',
    );
  }

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

  String _tradeIdFor(Reservation reservation) {
    return reservation.getDtag() ?? reservation.id;
  }

  groupByCommitment(List<Reservation> reservations, Listing listing) {
    final Map<String, List<Reservation>> grouped = {};
    for (final reservation in reservations) {
      final tradeId = _tradeIdFor(reservation);
      grouped.putIfAbsent(tradeId, () => []).add(reservation);
    }
    // Remove non-host reservation if a host reservation exists for same trade.
    for (final entry in grouped.entries) {
      final tradeId = entry.key;
      final group = entry.value;
      final hostReservations = group
          .where((reservation) => reservation.pubKey == listing.pubKey)
          .toList();
      if (hostReservations.isNotEmpty) {
        grouped[tradeId] = hostReservations;
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
        .map((reservation) => _tradeIdFor(reservation))
        .toSet();

    if (cancelledCommitments.isEmpty) {
      return reservations;
    }

    return reservations
        .where(
          (reservation) =>
              !cancelledCommitments.contains(_tradeIdFor(reservation)),
        )
        .toList();
  }

  Future<List<Validation<Reservation>>> _validateListingSnapshot({
    required Listing listing,
    required List<Reservation> reservations,
  }) async {
    final grouped = <String, List<Reservation>>{};
    for (final reservation in reservations) {
      grouped.putIfAbsent(_tradeIdFor(reservation), () => []).add(reservation);
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
              'No host confirmation and no guest reservation found for trade',
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
              'Superseded by latest guest reservation for trade',
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

  /// Converts a flat list of reservations into [ReservationPairStatus] objects
  /// grouped by trade id (`d` tag).
  ///
  /// The [listing] is used to determine which reservations belong to the
  /// seller (listing owner) vs the buyer.
  static Map<String, ReservationPairStatus> toReservationPairs({
    required List<Reservation> reservations,
    required Listing listing,
  }) {
    final Map<
      String,
      ({Reservation? sellerReservation, Reservation? buyerReservation})
    >
    pairs = {};

    for (final reservation in reservations) {
      final hash = reservation.getDtag() ?? reservation.id;
      final current =
          pairs[hash] ?? (sellerReservation: null, buyerReservation: null);

      if (reservation.pubKey == listing.pubKey) {
        pairs[hash] = (
          sellerReservation: reservation,
          buyerReservation: current.buyerReservation,
        );
      } else {
        pairs[hash] = (
          sellerReservation: current.sellerReservation,
          buyerReservation: reservation,
        );
      }
    }

    return pairs.map(
      (hash, pair) => MapEntry(
        hash,
        ReservationPairStatus(
          sellerReservation: pair.sellerReservation,
          buyerReservation: pair.buyerReservation,
        ),
      ),
    );
  }

  /// Queries all reservations for [listing] and returns them grouped as
  /// [ReservationPairStatus] by trade id (`d` tag).
  Future<Map<String, ReservationPairStatus>> queryReservationPairs({
    required Listing listing,
  }) async {
    final reservations = await getListingReservations(
      listingAnchor: listing.anchor!,
    );
    return toReservationPairs(reservations: reservations, listing: listing);
  }

  Map<String, ({Reservation? sellerReservation, Reservation? buyerReservation})>
  groupByThread(List<Reservation> reservations) {
    final temp =
        <
          String,
          ({Reservation? sellerReservation, Reservation? buyerReservation})
        >{};

    for (final reservation in reservations) {
      final tradeId = reservation.getDtag();
      if (tradeId == null || tradeId.isEmpty) continue;
      final thread = messaging.threads.threads[tradeId];
      if (thread == null) continue;

      final sellerPubKey = getPubKeyFromAnchor(
        thread.state.value.lastReservationRequest.parsedTags.listingAnchor,
      );

      final current =
          temp[tradeId] ?? (sellerReservation: null, buyerReservation: null);

      if (reservation.pubKey == sellerPubKey) {
        temp[tradeId] = (
          sellerReservation: reservation,
          buyerReservation: current.buyerReservation,
        );
      } else {
        temp[tradeId] = (
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
        .where(
          (message) =>
              message.child is Reservation &&
              (message.child as Reservation).parsedContent.isNegotiation,
        )
        .map((message) => message.child as Reservation)
        .asyncMap((negotiateReservation) async {
          logger.d(
            'Processing negotiate reservation: $negotiateReservation, ${negotiateReservation.getFirstTag('a')}',
          );
          final reservations = await getListingReservations(
            listingAnchor: negotiateReservation.parsedTags.listingAnchor,
          );
          logger.d('Found reservations: $reservations');
          return reservations.firstWhere(
            (reservation) =>
                reservation.getDtag() == negotiateReservation.getDtag(),
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
    Reservation request,
    String guestPubkey,
    String saltedPubkey,
  ) async {
    final reservation = Reservation(
      tags: ReservationTags([
        ['p', saltedPubkey],
        ['d', request.getDtag()!],
        [kListingRefTag, request.parsedTags.listingAnchor],
        [kThreadRefTag, anchor],
      ]),
      content: ReservationContent(
        start: request.parsedContent.start,
        end: request.parsedContent.end,
        stage: ReservationStage.commit,
        quantity: request.parsedContent.quantity,
        amount: request.parsedContent.amount,
        recipient: request.parsedContent.recipient,
      ),
      pubKey: auth.activeKeyPair!.publicKey,
    );
    logger.d('Accepting reservation request: $request');
    return _upsertWithTransition(
      reservation: reservation,
      transitionType: ReservationTransitionType.sellerAck,
      fromStage: ReservationStage.negotiate,
      toStage: ReservationStage.commit,
      commitTermsHash: request.parsedContent.commitHash(),
    );
  }

  Future<Reservation> createSelfSigned({
    required KeyPair activeKeyPair,
    required Reservation negotiateReservation,
    required PaymentProof proof,
  }) async {
    final tradeId = negotiateReservation.getDtag();
    final threadAnchor = negotiateReservation.getFirstTag(kThreadRefTag);

    final reservation = Reservation(
      content: ReservationContent(
        start: negotiateReservation.parsedContent.start,
        end: negotiateReservation.parsedContent.end,
        stage: ReservationStage.commit,
        quantity: negotiateReservation.parsedContent.quantity,
        amount: negotiateReservation.parsedContent.amount,
        recipient: negotiateReservation.parsedContent.recipient,
        proof: proof,
      ),
      pubKey: activeKeyPair.publicKey,
      tags: ReservationTags([
        [kListingRefTag, proof.listing.anchor!],
        ['d', tradeId!],
        if (threadAnchor != null) [kThreadRefTag, threadAnchor],
      ]),
    );

    final signedReservation = reservation.signAs(
      activeKeyPair,
      Reservation.fromNostrEvent,
    );
    await _upsertWithTransition(
      reservation: signedReservation,
      transitionType: ReservationTransitionType.commit,
      fromStage: ReservationStage.negotiate,
      toStage: ReservationStage.commit,
      commitTermsHash: signedReservation.parsedContent.commitHash(),
    );
    logger.d('Created self-signed reservation: $signedReservation');
    return signedReservation;
  }

  Future<Reservation> cancel(Reservation reservation, KeyPair keyPair) async {
    if (reservation.parsedContent.cancelled) {
      throw Exception('Reservation is already cancelled');
    }
    final updated = reservation
        .copy(
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          id: null,
          content: reservation.parsedContent.copyWith(
            cancelled: true,
            stage: ReservationStage.cancel,
          ),
          pubKey: null,
        )
        .signAs(keyPair, Reservation.fromNostrEvent);
    logger.d('Cancelling reservation: $updated');
    await _upsertWithTransition(
      reservation: updated,
      transitionType: ReservationTransitionType.cancel,
      fromStage: reservation.parsedContent.stage,
      toStage: ReservationStage.cancel,
      commitTermsHash: reservation.parsedContent.commitHash(),
    );
    return updated;
  }

  /// Broadcasts [reservation] and atomically records its lifecycle transition.
  ///
  /// All public mutation methods that advance a reservation through its
  /// lifecycle ([accept], [createSelfSigned], [cancel], [createBlocked]) MUST
  /// use this instead of calling [upsert] + [transitions.record] separately,
  /// enforcing the invariant that no reservation is broadcast without a
  /// transition record.
  Future<List<RelayBroadcastResponse>> _upsertWithTransition({
    required Reservation reservation,
    required ReservationTransitionType transitionType,
    required ReservationStage fromStage,
    required ReservationStage toStage,
    String? commitTermsHash,
    String? reason,
  }) async {
    final result = await upsert(reservation);
    await transitions.record(
      reservation: reservation,
      transitionType: transitionType,
      fromStage: fromStage,
      toStage: toStage,
      commitTermsHash: commitTermsHash,
      reason: reason,
    );
    return result;
  }

  Future<Reservation> createBlocked({
    required String listingAnchor,
    required DateTime start,
    required DateTime end,
  }) async {
    final nonce = Reservation.getNonceForBlockedReservation(
      start: start,
      end: end,
      hostKey: auth.activeKeyPair!,
    );
    final reservation = Reservation(
      content: ReservationContent(start: start, end: end),
      pubKey: auth.activeKeyPair!.publicKey,
      tags: ReservationTags([
        [kListingRefTag, listingAnchor],
        ['d', nonce],
      ]),
    );

    await _upsertWithTransition(
      reservation: reservation,
      transitionType: ReservationTransitionType.commit,
      fromStage: ReservationStage.negotiate,
      toStage: ReservationStage.commit,
    );
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
