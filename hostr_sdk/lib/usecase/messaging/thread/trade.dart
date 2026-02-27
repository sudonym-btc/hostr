import 'dart:async';

import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/messaging/thread/actions/reservation.dart';
import 'package:hostr_sdk/usecase/messaging/thread/actions/trade_action_resolver.dart';
import 'package:hostr_sdk/usecase/messaging/thread/payment_proof_orchestrator.dart';
import 'package:hostr_sdk/usecase/messaging/thread/thread.dart';
import 'package:hostr_sdk/usecase/messaging/thread/trade_context.dart';
import 'package:hostr_sdk/usecase/messaging/thread/trade_state.dart';
import 'package:hostr_sdk/usecase/messaging/thread/trade_subscriptions.dart';
import 'package:hostr_sdk/usecase/metadata/metadata.dart';
import 'package:hostr_sdk/usecase/reservations/reservations.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';

@injectable
class ThreadTrade {
  final Thread thread;
  final CustomLogger logger;

  final Auth auth;
  final Listings listings;
  final MetadataUseCase metadata;

  final TradeSubscriptions subscriptions;

  /// Resolved once, before subscriptions start. Null until context is loaded.
  final BehaviorSubject<TradeContext?> context$ = BehaviorSubject.seeded(null);

  /// Derived stream of available actions. Emits whenever any of the input
  /// streams change. Empty until the runtime is started.
  Stream<TradeResolution> get actions$ => _actions$ ?? const Stream.empty();

  Stream<TradeResolution>? _actions$;

  /// Trigger to force re-evaluation of actions (e.g. after addedParticipants
  /// changes without a corresponding stream event).
  final BehaviorSubject<void> _refreshTrigger = BehaviorSubject.seeded(null);

  ThreadPaymentProofOrchestrator? _paymentProofOrchestrator;
  final BehaviorSubject<TradeState> state;

  final List<StreamSubscription> _runtimeSubscriptions = [];
  StreamSubscription<Message>? _messageSubscription;
  Future<void>? _inFlightEnsureRuntime;

  ThreadTrade({
    @factoryParam required this.thread,
    required this.logger,
    required this.auth,
    required this.listings,
    required this.metadata,
  }) : state = BehaviorSubject<TradeState>.seeded(
         TradeState.initial(
           tradeId: thread.state.value.lastReservationRequest.getDtag()!,
           start: thread.state.value.lastReservationRequest.parsedContent.start,
           end: thread.state.value.lastReservationRequest.parsedContent.end,
           amount:
               thread.state.value.lastReservationRequest.parsedContent.amount,
         ),
       ),
       subscriptions = getIt<TradeSubscriptions>(param1: thread);

  Future<KeyPair> activeKeyPair() async {
    final ctx =
        context$.value ??
        await context$.where((e) => e != null).first as TradeContext;
    return ctx.listing.pubKey == auth.getActiveKey().publicKey
        ? auth.getActiveKey()
        : saltedKey(
            key: auth.getActiveKey().privateKey!,
            salt: state.value.tradeId,
          );
  }

  String getListingAnchor() {
    return thread.state.value.lastReservationRequest.parsedTags.listingAnchor;
  }

  Future<void> start() async {
    if (state.isClosed) return;

    state.add(state.value.copyWith(active: true));

    _messageSubscription ??= thread.messages.stream.listen((_) {
      unawaited(_ensureRuntime());
    });

    await _ensureRuntime();
  }

  Future<void> _ensureRuntime() {
    if (_inFlightEnsureRuntime != null) {
      return _inFlightEnsureRuntime!;
    }

    _inFlightEnsureRuntime = _doEnsureRuntime();
    return _inFlightEnsureRuntime!.whenComplete(() {
      _inFlightEnsureRuntime = null;
    });
  }

  bool _runtimeStarted = false;

  Future<void> _doEnsureRuntime() async {
    if (_runtimeStarted) return;
    _runtimeStarted = true;

    // 1. Resolve context (listing + profile + role) before anything else.
    final listing = await listings.getOneByAnchor(getListingAnchor());
    if (listing == null) {
      logger.w(
        'Cannot start runtime for trade ${state.value.tradeId}: listing unavailable',
      );
      _runtimeStarted = false;
      return;
    }
    final profile = await metadata.loadMetadata(listing.pubKey);
    if (profile == null) {
      logger.w(
        'Cannot start runtime for trade ${state.value.tradeId}: profile unavailable',
      );
      _runtimeStarted = false;
      return;
    }
    final context = TradeContext(
      listing: listing,
      profile: profile,
      role: getRole(
        hostPubkey: listing.pubKey,
        ourPubkey: auth.getActiveKey().publicKey,
      ),
    );
    context$.add(context);

    // 2. Start subscriptions with the resolved context.
    await subscriptions.start(context);

    // 3. Wire orchestrator.
    _paymentProofOrchestrator = getIt<ThreadPaymentProofOrchestrator>(
      param1: this,
    );
    unawaited(_paymentProofOrchestrator!.start(context));

    // 4. Build the derived actions stream from concrete stream emissions.
    // allReservationsStream.stream and reservationStream.stream both emit
    // List<Validation<...>> snapshots (ValidatedStreamWithStatus).
    // paymentEvents.list emits List<PaymentEvent> snapshots.
    _actions$ = Rx.combineLatest6(
      subscriptions.allReservationsStream!.stream,
      subscriptions.reservationStream!.stream,
      subscriptions.reservationStream!.status,
      subscriptions.paymentEvents!.list,
      subscriptions.paymentEvents!.status,
      _refreshTrigger,
      (allRes, ownRes, ownStatus, payments, paymentsStatus, _) =>
          TradeActionResolver.resolve(
            threadState: thread.state.value,
            context: context,
            tradeId: state.value.tradeId,
            start: state.value.start,
            end: state.value.end,
            amount: state.value.amount,
            ourPubkey: auth.getActiveKey().publicKey,
            allReservations: allRes,
            ownReservations: ownRes,
            ownReservationsStatus: ownStatus,
            payments: payments,
            paymentsStatus: paymentsStatus,
            addedParticipants: thread.addedParticipants,
          ),
    ).shareValue();

    // Re-evaluate actions when thread messages change (participantPubkeys,
    // reservationRequests, addedParticipants all live on the thread).
    _runtimeSubscriptions.add(
      thread.state.stream.listen((_) => _refreshTrigger.add(null)),
    );

    state.add(state.value.copyWith(runtimeReady: true));
  }

  Future<void> deactivate() async {
    if (state.isClosed) return;

    state.add(state.value.copyWith(active: false));

    await _messageSubscription?.cancel();
    _messageSubscription = null;

    for (final sub in _runtimeSubscriptions) {
      await sub.cancel();
    }
    _runtimeSubscriptions.clear();

    await subscriptions.stop();
    _runtimeStarted = false;
    _actions$ = null;

    state.add(state.value.copyWith(runtimeReady: false));
  }

  /// Returns the Nostr pubkey of the escrow service used in this trade,
  /// or null if no escrow proof is present.
  String? getEscrowPubkey() {
    final pairs = subscriptions.reservationStream?.list.value ?? const [];
    for (final validation in pairs) {
      final pair = validation.event;
      final reservations = [
        pair.sellerReservation,
        pair.buyerReservation,
      ].whereType<Reservation>();
      for (final reservation in reservations) {
        final pubkey = reservation
            .parsedContent
            .proof
            ?.escrowProof
            ?.escrowService
            .parsedContent
            .pubkey;
        if (pubkey != null) return pubkey;
      }
    }
    return null;
  }

  /// Forces a re-evaluation of [actions$]. Call this after mutating
  /// [thread.addedParticipants] (e.g. after adding the escrow participant).
  void refreshActions() => _refreshTrigger.add(null);

  Future<void> execute(TradeAction action) async {
    final current = await actions$.first;
    if (!current.actions.contains(action)) {
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
        // Handled by the UI via addParticipant + refreshActions.
        return;
    }
  }

  Future<void> close() async {
    await deactivate();
    await state.close();
    await context$.close();
    await _refreshTrigger.close();
  }
}
