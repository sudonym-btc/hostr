import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';

import '../../util/coinlib_gift_wrap.dart';
import '../../util/main.dart';
import '../auth/auth.dart';
import '../can_verify.dart';
import '../crud.usecase.dart';
import '../listings/listings.dart';
import '../messaging/messaging.dart';
import '../relays/relays.dart';
import 'reservation_participant_authorization_resolver.dart';
import 'reservation_participant_tags.dart';

class Commitment {
  final String hash;

  Commitment({required this.hash});
}

/// Dependencies resolved for a single review verification.
class ReservationDeps {
  final Listing? listing;

  const ReservationDeps({this.listing});
}

@Singleton()
class Reservations extends CrudUseCase<Reservation>
    implements CanVerify<Reservation, ReservationDeps> {
  final Messaging _messaging;
  final Auth _auth;
  final Listings _listings;
  final Relays _relays;
  late final ReservationParticipantAuthorizationResolver
  _participantAuthorizationResolver =
      ReservationParticipantAuthorizationResolver(logger: logger);
  Messaging get messaging => _messaging;
  Auth get auth => _auth;
  Listings get listings => _listings;
  StreamWithStatus<Reservation>? _myReservations;
  StreamSubscription<Reservation>? _myReservationsSubscription;
  Reservations({
    required super.requests,
    required super.logger,
    required Messaging messaging,
    required Auth auth,
    required Listings listings,
    required Relays relays,
  }) : _messaging = messaging,
       _auth = auth,
       _listings = listings,
       _relays = relays,
       super(kind: Reservation.kinds[0]);

  int _nextReplacementCreatedAt(Reservation existing) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now <= existing.createdAt ? existing.createdAt + 1 : now;
  }

  @override
  Future<void> beforeUpsert(Reservation event) async {
    MarketplaceOrder.fromEvent(event).ensureCanBroadcast();
  }

  Future<Reservation> _signReservation({
    required Reservation reservation,
    required KeyPair signerKeyPair,
  }) async {
    final activeNdkPubkey = requests.ndk.accounts.getPublicKey();
    if (activeNdkPubkey == signerKeyPair.publicKey) {
      return Reservation.fromNostrEvent(
        await requests.ndk.accounts.sign(reservation),
      );
    }

    final privateKey = signerKeyPair.privateKey;
    if (privateKey == null || privateKey.isEmpty) {
      throw StateError(
        'No signer available for reservation pubkey ${signerKeyPair.publicKey}',
      );
    }

    return reservation.signAs(signerKeyPair, Reservation.fromNostrEvent);
  }

  EventSigner? _transitionSignerFor(KeyPair? signerKeyPair) {
    final keyPair = signerKeyPair;
    if (keyPair == null) return null;
    final privateKey = keyPair.privateKey;
    if (privateKey == null || privateKey.isEmpty) return null;
    return Bip340EventSigner(
      privateKey: privateKey,
      publicKey: keyPair.publicKey,
    );
  }

  MarketplaceOrderStage _marketplaceStage(ReservationStage stage) {
    return MarketplaceOrderStage.values.firstWhere(
      (value) => value.name == stage.name,
    );
  }

  MarketplaceOrderTransitionType _marketplaceTransitionType(
    ReservationTransitionType type,
  ) {
    return MarketplaceOrderTransitionType.values.firstWhere(
      (value) => value.name == type.name,
    );
  }

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
    return findByTag(kListingRefTag, listingAnchor).then((reservations) {
      logger.d('Found ${reservations.length} reservations');
      return reservations;
    });
  }

  String _tradeIdFor(Reservation reservation) {
    return reservation.getDtag() ?? reservation.id;
  }

  Future<String> _signParticipantAuthorization({
    required String listingAnchor,
    required KeyPair identityKeyPair,
    required ReservationParticipantAuthorizationDraft draft,
  }) async {
    if (draft.identityPubkey != identityKeyPair.publicKey) {
      throw StateError(
        'Participant authorization identity must match the signer key',
      );
    }

    final authorization = TradeKeyAuthorization.create(
      identityPubkey: draft.identityPubkey,
      listingAnchor: listingAnchor,
      tradeId: draft.tradeId,
      participantPubkey: draft.participantPubkey,
      role: draft.role,
    );
    final activeNdkPubkey = requests.ndk.accounts.getPublicKey();
    final signedAuthorization = activeNdkPubkey == identityKeyPair.publicKey
        ? TradeKeyAuthorization.fromNostrEvent(
            await requests.ndk.accounts.sign(authorization),
          )
        : authorization.signAs(
            identityKeyPair,
            TradeKeyAuthorization.fromNostrEvent,
          );
    return ReservationParticipantAuthorizationPayload.fromAuthorizationEvent(
      signedAuthorization,
    ).encode();
  }

  Iterable<Reservation> _threadReservationCandidates({
    required String tradeId,
    Reservation? fallback,
  }) sync* {
    final seen = <String>{};

    if (fallback != null) {
      if (seen.add(fallback.id)) yield fallback;
    }
    for (final thread in messaging.threads.findByConversationTag(tradeId)) {
      for (final reservation in thread.state.value.reservationRequests) {
        if (seen.add(reservation.id)) yield reservation;
      }
      for (final reservation
          in thread.state.value.events.whereType<Reservation>()) {
        if (seen.add(reservation.id)) yield reservation;
      }
    }
  }

  Future<ParticipationProof> createParticipationProofForReview({
    required Reservation reservation,
    required String role,
    required KeyPair recipientKeyPair,
    required KeyPair identityKeyPair,
  }) {
    return _participantAuthorizationResolver.createReviewProof(
      reservation: reservation,
      role: role,
      recipientKeyPair: recipientKeyPair,
      identityPubkey: identityKeyPair.publicKey,
    );
  }

  Map<String, List<Reservation>> groupByCommitment(
    List<Reservation> reservations,
    Listing listing,
  ) {
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

  static Reservation? seniorReservations(List<Reservation> reservations) {
    return Reservation.getSeniorReservation(reservations: reservations);
  }

  static List<Reservation> filterCancelled(List<Reservation> reservations) {
    return reservations.where((e) => !e.cancelled).toList();
  }

  /// Converts a flat list of reservations into [ReservationGroup] objects
  /// grouped by trade id (`d` tag).
  ///
  /// Each group's role-based getters (sellerReservation, buyerReservation,
  /// escrowReservation) are computed from the flat list automatically.
  static Map<String, ReservationGroup> toOrderGroups({
    required List<Reservation> reservations,
  }) {
    final groups = groupMarketplaceOrders(
      orders: reservations.map(MarketplaceOrder.fromEvent),
    );

    return groups.map(
      (groupId, group) => MapEntry(
        groupId,
        ReservationGroup(
          reservations: group.orders.map(Reservation.fromNostrEvent).toList(),
          confirmedCommitted: group.confirmedCommitted,
        ),
      ),
    );
  }

  /// Queries all reservations for [listing] and returns them grouped as
  /// [ReservationGroup] by trade id (`d` tag).
  Future<Map<String, ReservationGroup>> queryOrderGroups({
    required Listing listing,
  }) async {
    final orders = await requests.ndk.marketplace.orders
        .queryByListing(listingAnchor: listing.anchor!)
        .future;
    final reservations = orders.map(Reservation.fromNostrEvent).toList();
    return toOrderGroups(reservations: reservations);
  }

  Map<String, ReservationGroup> groupByThread(List<Reservation> reservations) {
    final Map<String, List<Reservation>> grouped = {};

    for (final reservation in reservations) {
      final tradeId = reservation.getDtag();
      if (tradeId == null || tradeId.isEmpty) continue;
      final participants = rawReservationParticipantSet(reservation);
      final thread = messaging.threads.findTradeThread(
        tradeId: tradeId,
        participants: participants,
      );
      if (thread == null) continue;

      final groupId = rawReservationGroupId(reservation);
      grouped.putIfAbsent(groupId, () => []);
      grouped[groupId]!.removeWhere((r) => r.pubKey == reservation.pubKey);
      grouped[groupId]!.add(reservation);
    }

    return grouped.map(
      (groupId, list) =>
          MapEntry(groupId, ReservationGroup(reservations: list)),
    );
  }

  StreamWithStatus<Reservation> subscribeToMyReservations() {
    if (_myReservations != null) {
      return _myReservations!;
    }

    final response = StreamWithStatus<Reservation>();
    response.addStatus(StreamStatusLive());

    _myReservations = response;

    final reservationsStream = messaging.threads.events$.replayStream
        .whereType<Message>()
        .map((message) => message.child)
        .whereType<Reservation>()
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

    unawaited(_myReservationsSubscription?.cancel());
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
    final sellerHint = await _relays.relayHintFor(
      auth.activeKeyPair!.publicKey,
    );
    final buyerHint = await _relays.relayHintFor(saltedPubkey);
    final reservation = Reservation.create(
      pubKey: auth.activeKeyPair!.publicKey,
      dTag: request.getDtag()!,
      listingAnchor: request.parsedTags.listingAnchor,
      pTags: [
        PTag.seller(auth.activeKeyPair!.publicKey, relayHint: sellerHint),
        PTag.buyer(saltedPubkey, relayHint: buyerHint),
      ],
      start: request.start,
      end: request.end,
      stage: ReservationStage.commit,
      quantity: request.quantity,
      amount: request.amount,
      recipient: request.recipient,
    );
    logger.d('Accepting reservation request: $request');
    return _upsertWithTransition(
      reservation: reservation,
      transitionType: ReservationTransitionType.commit,
      fromStage: ReservationStage.negotiate,
      toStage: ReservationStage.commit,
      signerKeyPair: auth.activeKeyPair,
      commitTermsHash: request.commitHash(),
    );
  }

  Future<Reservation> createSelfSigned({
    required KeyPair activeKeyPair,
    required Reservation negotiateReservation,
    required PaymentProof proof,
  }) async {
    final tradeId = negotiateReservation.getDtag();
    final listingAnchor = negotiateReservation.parsedTags.listingAnchor;

    final sellerPk = getPubKeyFromAnchor(listingAnchor);
    final escrowPk = proof.escrowProof?.escrowService.escrowPubkey;
    final participantPlan = await buildReservationParticipantTagPlan(
      tradeId: tradeId!,
      reservationAuthorKey: activeKeyPair,
      participants: [
        ReservationParticipant.real(role: 'seller', pubkey: sellerPk),
        ReservationParticipant(
          role: 'buyer',
          participantPubkey: activeKeyPair.publicKey,
          identityPubkey: auth.getActiveKey().publicKey,
        ),
        if (escrowPk != null)
          ReservationParticipant.real(role: 'escrow', pubkey: escrowPk),
      ],
      relayHintFor: _relays.relayHintFor,
      signAuthorization: (draft) async {
        final reused = await _participantAuthorizationResolver
            .findReusableAuthorization(
              draft: draft,
              recipientKeyPair: activeKeyPair,
              candidates: _threadReservationCandidates(
                tradeId: tradeId,
                fallback: negotiateReservation,
              ),
            );
        if (reused != null) return reused;
        return _signParticipantAuthorization(
          listingAnchor: listingAnchor,
          identityKeyPair: auth.getActiveKey(),
          draft: draft,
        );
      },
      encryptAuthorization:
          ({
            required plaintext,
            required senderPrivateKey,
            required recipientPubkey,
          }) =>
              coinlibEncryptNip44(plaintext, senderPrivateKey, recipientPubkey),
    );

    final reservation = Reservation.create(
      pubKey: activeKeyPair.publicKey,
      dTag: tradeId,
      listingAnchor: listingAnchor,
      start: negotiateReservation.start,
      end: negotiateReservation.end,
      stage: ReservationStage.commit,
      quantity: negotiateReservation.quantity,
      amount: negotiateReservation.amount,
      recipient: negotiateReservation.recipient,
      proof: proof,
      commitAuthorization: negotiateReservation.commitAuthorization,
      extraTags: participantPlan.tags,
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
      signerKeyPair: activeKeyPair,
      commitTermsHash: signedReservation.commitHash(),
    );
    logger.d('Created self-signed reservation: $signedReservation');
    return signedReservation;
  }

  /// Builds [PTag]s with relay hints for all participants in a
  /// [ReservationGroup]. Used by [cancel] and [confirm].
  Future<List<PTag>> _pTagsForGroup(ReservationGroup group) async {
    return [
      PTag.seller(
        group.sellerPubkey,
        relayHint: await _relays.relayHintFor(group.sellerPubkey),
      ),
      if (group.buyerPubkey != null)
        PTag.buyer(
          group.buyerPubkey!,
          relayHint: await _relays.relayHintFor(group.buyerPubkey!),
        ),
      if (group.escrowPubkey != null)
        PTag.escrow(
          group.escrowPubkey!,
          relayHint: await _relays.relayHintFor(group.escrowPubkey!),
        ),
    ];
  }

  // @todo: move to reservationGroup?
  // @todo: cancel / confirm reservation methods should use the same logic. Escrow must confirm when acknowledging transaction correct, host can confirm when they manually approve a transaction
  // cancel and confirm just change the stage of the reservation, so they should share logic
  Future<Reservation> cancel(
    ReservationGroup reservationGroup,
    KeyPair keyPair,
  ) async {
    if (reservationGroup.cancelled) {
      throw Exception('ReservationGroup is already cancelled');
    }
    final myReservation = reservationGroup.reservations
        .where((r) => r.pubKey == keyPair.publicKey)
        .firstOrNull;
    final pTags = await _pTagsForGroup(reservationGroup);
    final blank = Reservation.create(
      pubKey: keyPair.publicKey,
      dTag: reservationGroup.tradeId,
      listingAnchor: reservationGroup.listingAnchor,
      stage: ReservationStage.cancel,
      pTags: pTags,
      start: reservationGroup.start,
      end: reservationGroup.end,
    );
    final unsigned = myReservation == null
        ? blank
        : myReservation.copy(
            createdAt: _nextReplacementCreatedAt(myReservation),
            id: null,
            content: myReservation.parsedContent.copyWith(
              stage: ReservationStage.cancel,
            ),

            pubKey: keyPair.publicKey,
          );
    final updated = await _signReservation(
      reservation: unsigned,
      signerKeyPair: keyPair,
    );
    logger.d('Cancelling reservation: $updated');
    await _upsertWithTransition(
      reservation: updated,
      transitionType: ReservationTransitionType.cancel,
      fromStage: myReservation?.stage ?? ReservationStage.negotiate,
      toStage: ReservationStage.cancel,
      signerKeyPair: keyPair,
      commitTermsHash: updated.commitHash(),
    );
    return updated;
  }

  /// Confirms a committed reservation, signalling that payment proof has been
  /// validated.
  ///
  /// Mirrors [cancel]: the caller re-publishes their copy of the reservation
  /// in the [ReservationStage.commit] stage and emits a
  /// [ReservationTransitionType.confirm] transition.
  ///
  /// Typically invoked by the escrow daemon after verifying the on-chain /
  /// lightning settlement. Host or buyer can also call this to manually
  /// acknowledge a transaction.
  ///
  /// The set of `p` tags is preserved from [reservationGroup] so all
  /// participants remain in scope.
  Future<Reservation> confirm(
    ReservationGroup reservationGroup,
    KeyPair keyPair,
  ) async {
    if (reservationGroup.cancelled) {
      throw Exception('ReservationGroup is already cancelled — cannot confirm');
    }
    if (reservationGroup.stage != ReservationStage.commit) {
      throw Exception('ReservationGroup is not yet committed — cannot confirm');
    }
    final myReservation = reservationGroup.reservations
        .where((r) => r.pubKey == keyPair.publicKey)
        .firstOrNull;
    final pTags = await _pTagsForGroup(reservationGroup);
    final blank = Reservation.create(
      pubKey: keyPair.publicKey,
      dTag: reservationGroup.tradeId,
      listingAnchor: reservationGroup.listingAnchor,
      stage: ReservationStage.commit,
      pTags: pTags,
    );
    final unsigned = myReservation == null
        ? blank
        : myReservation.copy(
            createdAt: _nextReplacementCreatedAt(myReservation),
            id: null,
            content: myReservation.parsedContent.copyWith(
              stage: ReservationStage.commit,
            ),
            pubKey: keyPair.publicKey,
          );
    final updated = await _signReservation(
      reservation: unsigned,
      signerKeyPair: keyPair,
    );
    logger.d('Confirming reservation: $updated');
    await _upsertWithTransition(
      reservation: updated,
      transitionType: ReservationTransitionType.confirm,
      fromStage: ReservationStage.commit,
      toStage: ReservationStage.commit,
      signerKeyPair: keyPair,
      commitTermsHash: updated.commitHash(),
    );
    return updated;
  }

  /// Broadcasts [reservation] and atomically records its lifecycle transition.
  ///
  /// All public mutation methods that advance a reservation through its
  /// lifecycle ([accept], [createSelfSigned], [cancel], [createBlocked]) MUST
  /// use this instead of calling [upsert] + transition recording separately,
  /// enforcing the invariant that no reservation is broadcast without a
  /// transition record.
  Future<List<RelayBroadcastResponse>> _upsertWithTransition({
    required Reservation reservation,
    required ReservationTransitionType transitionType,
    required ReservationStage fromStage,
    required ReservationStage toStage,
    KeyPair? signerKeyPair,
    String? commitTermsHash,
    String? reason,
  }) async {
    final result = await upsert(reservation);
    await requests.ndk.marketplace.orderTransitions.record(
      order: MarketplaceOrder.fromEvent(reservation),
      transitionType: _marketplaceTransitionType(transitionType),
      fromStage: _marketplaceStage(fromStage),
      toStage: _marketplaceStage(toStage),
      customSigner: _transitionSignerFor(signerKeyPair),
      commitTermsHash: commitTermsHash,
      reason: reason,
    );
    return result.responses;
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
    final sellerHint = await _relays.relayHintFor(
      auth.activeKeyPair!.publicKey,
    );
    final reservation = Reservation.create(
      pubKey: auth.activeKeyPair!.publicKey,
      dTag: nonce,
      listingAnchor: listingAnchor,
      pTags: [
        PTag.seller(auth.activeKeyPair!.publicKey, relayHint: sellerHint),
      ],
      stage: ReservationStage.commit,
      start: start,
      end: end,
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

  /// Subscribes to all reservations for [listing] and emits only those whose
  /// tradeId has NOT been cancelled.
  ///
  /// Events are collected within a [debounce] window; after the window closes
  /// the full buffer is scanned: any tradeId with a [ReservationStage.cancel]
  /// entry is dropped in its entirety, and the surviving reservations are
  /// emitted as [Valid] items.
  StreamWithStatus<Validation<Reservation>> subscribeUncancelledReservations({
    required Listing listing,
    Duration debounce = const Duration(milliseconds: 500),
  }) {
    final response = StreamWithStatus<Validation<Reservation>>();
    final anchor = listing.anchor;
    if (anchor == null) {
      response.addStatus(StreamStatusLive());
      return response;
    }

    final raw = subscribe(
      Filter(
        tags: {
          kListingRefTag: [anchor],
        },
      ),
      name: 'uncancelled-$anchor',
    );

    // tradeId → list of all seen reservations for that tradeId.
    final Map<String, List<Reservation>> buffer = {};
    // tradeIds that have already been emitted (or are cancelled).
    final Set<String> handled = {};
    Timer? timer;

    void flush() {
      for (final entry in buffer.entries) {
        final tradeId = entry.key;
        if (handled.contains(tradeId)) continue;
        final reservations = entry.value;
        if (reservations.any((r) => r.stage == ReservationStage.cancel)) {
          handled.add(tradeId);
          continue;
        }
        final latest = reservations.reduce(
          (a, b) => a.createdAt >= b.createdAt ? a : b,
        );
        response.add(Valid(latest));
        handled.add(tradeId);
      }
    }

    response.addSubscription(
      raw.replayStream.listen((reservation) {
        final tradeId = reservation.getDtag() ?? reservation.id;
        buffer.putIfAbsent(tradeId, () => []).add(reservation);
        if (debounce == Duration.zero) {
          timer?.cancel();
          Timer.run(flush);
        } else {
          timer?.cancel();
          timer = Timer(debounce, flush);
        }
      }, onError: response.addError),
    );
    response.addSubscription(raw.status.listen(response.addStatus));

    return response;
  }

  /// Soft cleanup for logout: cancel the subscription and null out the
  /// stream so [subscribeToMyReservations] creates a fresh one on next
  /// login.
  Future<void> reset() async {
    await _myReservationsSubscription?.cancel();
    _myReservationsSubscription = null;
    _myReservations = null;
  }

  /// Permanent teardown — closes the stream. Only call when the Hostr
  /// instance itself is being disposed.
  Future<void> dispose() async {
    await _myReservations?.close();
    _myReservations = null;
    await _myReservationsSubscription?.cancel();
    _myReservationsSubscription = null;
  }

  @override
  StreamWithStatus<Validation<Reservation>> queryVerified({
    Filter? filter,
    Duration debounce = const Duration(milliseconds: 50),
    bool closeSourceOnClose = true,
    String? name,
  }) {
    // TODO: implement queryVerified
    throw UnimplementedError();
  }

  @override
  Future<ReservationDeps> resolve(Reservation item) async {
    return ReservationDeps(
      listing: await listings.getOneByAnchor(item.parsedTags.listingAnchor),
    );
  }

  @override
  StreamWithStatus<Validation<Reservation>> subscribeVerified({
    Filter? filter,
    Duration debounce = const Duration(milliseconds: 50),
    bool closeSourceOnClose = true,
    String? name,
  }) {
    // TODO: implement subscribeVerified
    throw UnimplementedError();
  }

  @override
  // TODO: implement verificationStreamName
  String get verificationStreamName => throw UnimplementedError();

  @override
  Validation<Reservation> verify(Reservation item, ReservationDeps deps) {
    // TODO: implement verify
    throw UnimplementedError();
  }
}
