import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';

import '../../../injection.dart';
import '../../../util/custom_logger.dart';
import '../../../util/stream_status.dart';
import '../../../util/validation_stream.dart';
import '../../auth/auth.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../../listings/listings.dart';
import '../../metadata/metadata.dart';
import '../../reservation_pairs/reservation_pairs.dart';
import '../../reservations/reservations.dart';
import '../threads.dart';
import '../user_subscriptions.dart';
import 'actions/payment.dart';
import 'actions/reservation.dart';
import 'actions/reservation_request.dart';
import 'actions/trade_action_resolver.dart';
import 'state.dart';
import 'thread.dart';
import 'trade_state.dart';

/// Role of the local user in a trade.
enum TradeRole { host, guest }

/// A short-lived, reactive view-model for a single trade.
///
/// Instantiated by the UI with a [tradeId] (and optionally a [Thread] for
/// negotiation-stage access to reservation requests). Derives everything
/// reactively from the long-lived [UserSubscriptions] streams.
///
/// Extends [Cubit] so it can be provided directly via `BlocProvider<Trade>`
/// and consumed via `BlocBuilder<Trade, TradeState>`.
@injectable
class Trade extends Cubit<TradeState> {
  final CustomLogger _logger;
  final Auth _auth;
  final Listings _listings;
  final MetadataUseCase _metadata;
  final UserSubscriptions _userSubscriptions;
  final ReservationPairs _reservationPairs;
  final Threads _threads;

  /// Resolved lazily in [start()] from the [Threads] map.
  /// Available when opened from a thread context (negotiation-stage access).
  Thread? thread;

  /// The trade ID (d-tag of the reservation).
  final String tradeId;

  /// Listing anchor — provided as a hint for immediate fetching.
  final String listingAnchor;

  /// Host pubkey derived from listing anchor.
  final String hostPubKey;

  /// Our role in this trade.
  final TradeRole role;

  String salt;

  // ── Filtered streams (from UserSubscriptions) ──────────────────────

  final StreamWithStatus<Validation<ReservationPairStatus>> reservationPair$;
  final StreamWithStatus<PaymentEvent> payments$;
  final StreamWithStatus<ReservationTransition> transitions$;

  final BehaviorSubject<bool> subscriptionsLive$ = BehaviorSubject.seeded(
    false,
  );

  /// Listing-level reservation stream — only started during negotiation.
  StreamWithStatus<Validation<ReservationPairStatus>>? allListingReservations$;

  // ── Internal bookkeeping ───────────────────────────────────────────

  final List<StreamSubscription> _subscriptions = [];
  StreamSubscription? _combineSubscription;
  Listing? _listing;
  ProfileMetadata? _hostProfile;
  bool _bootstrapped = false;

  Trade({
    @factoryParam required this.tradeId,
    @factoryParam required this.listingAnchor,
    required CustomLogger logger,
    required Auth auth,
    required Listings listings,
    required MetadataUseCase metadata,
    required UserSubscriptions userSubscriptions,
    required ReservationPairs reservationPairs,
    required Threads threads,
  }) : _logger = logger.namespace('trade'),
       _auth = auth,
       _listings = listings,
       _metadata = metadata,
       _userSubscriptions = userSubscriptions,
       _reservationPairs = reservationPairs,
       _threads = threads,
       thread = threads.threads[tradeId],
       hostPubKey = getPubKeyFromAnchor(listingAnchor),
       salt =
           threads.threads[tradeId]?.messages.list.value
               .where((msg) => msg.child is Reservation)
               .map((msg) => msg.child as Reservation)
               .where((res) => res.salt != null)
               .firstOrNull
               ?.salt ??
           '',
       role =
           getPubKeyFromAnchor(listingAnchor) == auth.getActiveKey().publicKey
           ? TradeRole.host
           : TradeRole.guest,
       // Set up filtered streams from UserSubscriptions.
       reservationPair$ = userSubscriptions.allMyReservationPairs$.where(
         (item) => item.event.tradeId == tradeId,
         closeInner: false,
       ),

       payments$ = userSubscriptions.paymentEvents$.where(
         (event) => event.tradeId == tradeId,
         closeInner: false,
       ),

       transitions$ = userSubscriptions.allTransitions$.stream.where(
         (t) => t.parsedTags.tradeId == tradeId,
         closeInner: false,
       ),

       super(const TradeInitialising()) {
    // Update subscriptionsLive$ based on the status of the combined streams.
    _subscriptions.add(
      Rx.combineLatest3(
        reservationPair$.status,
        payments$.status,
        transitions$.status,
        (a, b, c) => [a, b, c],
      ).listen((statuses) {
        final allLive = statuses.every((s) => s is StreamStatusLive);
        if (allLive && !(subscriptionsLive$.value)) {
          subscriptionsLive$.sink.add(true);
        }
      }),
    );
  }

  Future<String?> resolveGuestPubkey() async {
    String? salt = (await thread!.state.value.reservationRequests.last).salt;
    String? tweakedPubkey =
        (await thread!.state.value.reservationRequests.last).recipient;
    print('Pair for trade $tradeId: $salt');
    if (salt == null || tweakedPubkey == null) {
      throw StateError(
        'Cannot resolve guest pubkey: missing salt($salt) or tweakedPubkey($tweakedPubkey)',
      );
    }

    return unsaltPublicKey(saltedPublicKey: tweakedPubkey, salt: salt);
  }

  // ── Lifecycle ──────────────────────────────────────────────────────

  /// Bootstrap the trade: fetch listing + profile, set up filtered streams,
  /// then wire the reactive combine pipeline.
  Future<void> start() async {
    if (_bootstrapped || isClosed) return;
    _bootstrapped = true;

    // Fetch listing.
    final fetchedListing = await _listings.getOneByAnchor(listingAnchor);
    if (fetchedListing == null) {
      _logger.w('Cannot start trade $tradeId: listing unavailable');
      if (!isClosed) emit(TradeError('Listing unavailable'));
      return;
    }
    _listing = fetchedListing;

    // Fetch host profile (optional — UI can handle null gracefully).
    _hostProfile = await _metadata.loadMetadata(hostPubKey);

    // Wire the reactive pipeline.
    _wirePipeline();
  }

  /// The core reactive pipeline. Combines all relevant streams and emits
  /// [TradeReady] with the resolved stage and actions on every change.
  void _wirePipeline() {
    final listing = _listing!;
    final hostProfile = _hostProfile;

    // Start the listing-level reservation subscription (needed for overlap
    // check during negotiation). It's always running so the combine has a
    // stable input; the cost is one extra Nostr subscription.
    allListingReservations$ = _reservationPairs.subscribeVerified(
      listingAnchor: listingAnchor,
      forceValidatePredicate: (pair) {
        final pairTradeId =
            pair.sellerReservation?.getDtag() ??
            pair.buyerReservation?.getDtag();
        return pairTradeId == tradeId;
      },
    );

    // Build the list of streams to combine. If we have a thread, include
    // its state (for reservation requests in negotiation). Otherwise use
    // a single-value stream.
    final threadState$ = thread != null
        ? thread!.state.stream.startWith(thread!.state.value)
        : Stream<ThreadState?>.value(null);

    _combineSubscription =
        Rx.combineLatest8(
          reservationPair$.list,
          reservationPair$.status,
          payments$.list,
          payments$.status,
          transitions$.list,
          allListingReservations$!.list,
          allListingReservations$!.status,
          threadState$,
          (
            List<Validation<ReservationPairStatus>> ownRes,
            StreamStatus ownResStatus,
            List<PaymentEvent> payments,
            StreamStatus paymentsStatus,
            List<ReservationTransition> transitions,
            List<Validation<ReservationPairStatus>> allListingRes,
            StreamStatus allListingResStatus,
            ThreadState? threadState,
          ) {
            return _resolve(
              listing: listing,
              hostProfile: hostProfile,
              ownReservations: ownRes,
              ownReservationsStatus: ownResStatus,
              payments: payments,
              paymentsStatus: paymentsStatus,
              transitions: transitions,
              allListingReservations: allListingRes,
              threadState: threadState,
            );
          },
        ).listen(
          (resolvedState) {
            if (!isClosed) emit(resolvedState);
          },
          onError: (Object error) {
            _logger.e('Trade $tradeId stream error: $error');
            if (!isClosed) emit(TradeError(error.toString()));
          },
        );
  }

  /// Pure resolution logic. Derives the stage, actions, and availability
  /// from the current stream snapshots.
  TradeReady _resolve({
    required Listing listing,
    required ProfileMetadata? hostProfile,
    required List<Validation<ReservationPairStatus>> ownReservations,
    required StreamStatus ownReservationsStatus,
    required List<PaymentEvent> payments,
    required StreamStatus paymentsStatus,
    required List<ReservationTransition> transitions,
    required List<Validation<ReservationPairStatus>> allListingReservations,
    required ThreadState? threadState,
  }) {
    // Derive last reservation request from thread (if available).
    final reservationRequests = threadState?.reservationRequests ?? const [];
    final lastRequest = reservationRequests.isNotEmpty
        ? reservationRequests.last
        : null;

    final start = lastRequest?.start ?? DateTime.now();
    final end = lastRequest?.end ?? DateTime.now();
    final amount = lastRequest?.amount;
    final ourPubkey = _auth.getActiveKey().publicKey;
    final participantPubkeys = [
      ...?threadState?.participantPubkeys,
      ...?thread?.addedParticipants,
    ];

    // Compute overlap lock from listing-level reservations.
    final validAllListingPairs = allListingReservations
        .whereType<Valid<ReservationPairStatus>>()
        .map((v) => v.event)
        .where((p) => !p.cancelled)
        .toList();
    final overlapLock = resolveOverlapLock(
      ourReservationDTag: tradeId,
      allListingReservationPairs: validAllListingPairs,
      startDate: start,
      endDate: end,
    );

    // Determine stage + resolve actions.
    final bool isNegotiation =
        ownReservationsStatus is StreamStatusLive && ownReservations.isEmpty;

    late final TradeStage stage;
    final resolvedActions = <TradeAction>[];

    if (isNegotiation) {
      stage = NegotiationStage(
        reservationRequests: reservationRequests,
        overlapLock: overlapLock,
      );

      // Negotiation actions: pay / counter / accept.
      if (threadState != null) {
        resolvedActions.addAll(
          ReservationRequestActions.resolve(
            reservationRequests,
            listing,
            ourPubkey,
            role,
          ),
        );
      }
    } else {
      // Extract the reservation pair for commit stage.
      final validPair = ownReservations
          .whereType<Valid<ReservationPairStatus>>()
          .map((v) => v.event)
          .where((p) => !p.cancelled)
          .firstOrNull;
      final anyPair = ownReservations
          .whereType<Valid<ReservationPairStatus>>()
          .map((v) => v.event)
          .firstOrNull;

      stage = CommitStage(
        reservationPair: validPair ?? anyPair ?? ReservationPairStatus(),
        payments: payments,
        transitions: transitions,
      );

      // Commit actions: cancel, refund, claim, messageEscrow.
      final allTradeReservations = ownReservations
          .whereType<Valid<ReservationPairStatus>>()
          .expand((v) => [v.event.sellerReservation, v.event.buyerReservation])
          .whereType<Reservation>()
          .toList();

      final validTradeReservations = ownReservations
          .whereType<Valid<ReservationPairStatus>>()
          .where((v) => !v.event.cancelled)
          .expand((v) => [v.event.sellerReservation, v.event.buyerReservation])
          .whereType<Reservation>()
          .toList();

      resolvedActions.addAll(
        PaymentActions.resolve(payments, paymentsStatus, role),
      );

      resolvedActions.addAll(
        ReservationActions.resolve(
          validTradeReservations,
          ownReservationsStatus,
          participantPubkeys,
          role,
          allReservations: allTradeReservations,
        ),
      );
    }

    // Availability.
    final availability = _resolveAvailability(
      ownReservations: ownReservations,
      overlapLock: overlapLock,
    );

    return TradeReady(
      listing: listing,
      hostProfile: hostProfile,
      hostPubKey: hostPubKey,
      role: role,
      tradeId: tradeId,
      listingAnchor: listingAnchor,
      start: start,
      end: end,
      amount: amount,
      stage: stage,
      actions: resolvedActions,
      availability: availability,
      availabilityReason: switch (availability) {
        TradeAvailability.unavailable => overlapLock.reason,
        _ => null,
      },
      streams: TradeStreams(
        paymentEvents: payments$,
        reservationStream: reservationPair$,
        transitionsStream: transitions$,
        subscriptionsLive: subscriptionsLive$,
      ),
    );
  }

  static TradeAvailability _resolveAvailability({
    required List<Validation<ReservationPairStatus>> ownReservations,
    required ({bool isBlocked, String? reason}) overlapLock,
  }) {
    if (ownReservations.any((v) => v is Invalid)) {
      return TradeAvailability.invalidReservation;
    }
    if (ownReservations.whereType<Valid<ReservationPairStatus>>().any(
      (v) => v.event.cancelled,
    )) {
      return TradeAvailability.cancelled;
    }
    if (overlapLock.isBlocked) return TradeAvailability.unavailable;
    return TradeAvailability.available;
  }

  // ── Public API ─────────────────────────────────────────────────────

  /// Current reservation pair status list (for action execution).
  List<Validation<ReservationPairStatus>> get currentReservationPairs =>
      _bootstrapped ? reservationPair$.list.value : const [];

  Future<KeyPair> activeKeyPair() async {
    return role == TradeRole.host
        ? _auth.getActiveKey()
        : saltedKey(key: _auth.getActiveKey().privateKey!, salt: tradeId);
  }

  /// Returns the Nostr pubkey of the escrow service used in this trade.
  String? getEscrowPubkey() {
    final pairs = reservationPair$.list.value;
    for (final validation in pairs) {
      final pair = validation.event;
      final reservations = [
        pair.sellerReservation,
        pair.buyerReservation,
      ].whereType<Reservation>();
      for (final reservation in reservations) {
        final pubkey =
            reservation.proof?.escrowProof?.escrowService.escrowPubkey;
        if (pubkey != null) return pubkey;
      }
    }
    return null;
  }

  /// Forces a re-emit by re-running the pipeline manually (e.g. after
  /// mutating thread.addedParticipants).
  void refreshActions() {
    // The pipeline will re-emit on the next stream event. For immediate
    // re-evaluation we can trigger it by checking if thread state changed.
    // For now, thread.state listeners handle this automatically.
  }

  Future<void> execute(TradeAction action) async {
    final current = state;
    if (current is! TradeReady || !current.actions.contains(action)) {
      throw StateError('Action not available for this trade: $action');
    }

    switch (action) {
      case TradeAction.cancel:
        await ReservationActions(
          trade: this,
          reservations: getIt<Reservations>(),
        ).cancel();
        return;
      case TradeAction.claim:
        throw UnimplementedError('Trade claim is not implemented yet.');
      case TradeAction.refund:
        throw UnimplementedError('Trade refund/redeem is not implemented yet.');
      case TradeAction.accept:
      case TradeAction.counter:
      case TradeAction.pay:
      case TradeAction.review:
        throw UnsupportedError(
          'Action not supported by trade executor: $action',
        );
      case TradeAction.messageEscrow:
        return;
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────

  @override
  Future<void> close() async {
    await _combineSubscription?.cancel();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    if (_bootstrapped) {
      await allListingReservations$?.close();
      await reservationPair$.close();
      await payments$.close();
      await transitions$.close();
    }
    await super.close();
  }
}
