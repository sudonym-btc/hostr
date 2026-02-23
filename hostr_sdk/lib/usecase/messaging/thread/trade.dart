import 'dart:async';

import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/messaging/thread/actions/trade_action_resolver.dart';
import 'package:hostr_sdk/usecase/messaging/thread/payment_proof_orchestrator.dart';
import 'package:hostr_sdk/usecase/messaging/thread/thread.dart';
import 'package:hostr_sdk/usecase/messaging/thread/trade_state.dart';
import 'package:hostr_sdk/usecase/messaging/thread/trade_subscriptions.dart';
import 'package:hostr_sdk/usecase/metadata/metadata.dart';
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
  late final ThreadPaymentProofOrchestrator _paymentProofOrchestrator;
  final BehaviorSubject<TradeState> state;

  final List<StreamSubscription> _runtimeSubscriptions = [];
  StreamSubscription<Message>? _messageSubscription;
  Future<void>? _inFlightEnsureRuntime;

  Completer<Listing?>? _listingCompleter;
  Completer<ProfileMetadata?>? _listingProfileCompleter;

  ThreadTrade({
    @factoryParam required this.thread,
    required this.logger,
    required this.auth,
    required this.listings,
    required this.metadata,
  }) : state = BehaviorSubject<TradeState>.seeded(
         TradeState.initial(
           tradeId: thread.anchor,
           salt: thread.state.value.lastReservationRequest.parsedContent.salt,
           start: thread.state.value.lastReservationRequest.parsedContent.start,
           end: thread.state.value.lastReservationRequest.parsedContent.end,
           amount:
               thread.state.value.lastReservationRequest.parsedContent.amount,
         ),
       ),
       subscriptions = getIt<TradeSubscriptions>(param1: thread) {
    _paymentProofOrchestrator = getIt<ThreadPaymentProofOrchestrator>(
      param1: this,
      param2: subscriptions,
    );
  }
  Future<KeyPair> activeKeyPair() async {
    final listing = (await getListing())!;
    return listing.pubKey == auth.getActiveKey().publicKey
        ? auth.getActiveKey()
        : saltedKey(
            key: auth.getActiveKey().privateKey!,
            salt: state.value.salt,
          );
  }

  Future<void> load() async {
    await Future.wait([getListing(), getListingProfile()]);
  }

  Future<Listing?> getListing() {
    if (_listingCompleter != null) {
      return _listingCompleter!.future;
    }

    _listingCompleter = Completer<Listing?>();
    listings
        .getOneByAnchor(getListingAnchor())
        .then((listing) {
          state.add(state.value.copyWith(listing: listing));
          return _listingCompleter!.complete(listing);
        })
        .catchError(_listingCompleter!.completeError);
    return _listingCompleter!.future;
  }

  Future<ProfileMetadata?> getListingProfile() {
    if (_listingProfileCompleter != null) {
      return _listingProfileCompleter!.future;
    }

    _listingProfileCompleter = Completer<ProfileMetadata?>();
    getListing()
        .then((listing) async {
          if (listing == null) return null;
          return metadata.loadMetadata(listing.pubKey);
        })
        .then((listingProfile) {
          state.add(state.value.copyWith(listingProfile: listingProfile));
          return _listingProfileCompleter!.complete(listingProfile);
        })
        .catchError(_listingProfileCompleter!.completeError);
    return _listingProfileCompleter!.future;
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

    await subscriptions.start();
    unawaited(_paymentProofOrchestrator.start());

    // Recalculate actions whenever anything changes
    _emitState();
    _runtimeSubscriptions.add(
      Rx.merge([
        subscriptions.paymentEvents!.stream.map((event) => null),
        subscriptions.paymentEvents!.status.map((event) => null),
        subscriptions.reservationStream!.stream.map((event) => null),
        subscriptions.reservationStream!.status.map((event) => null),
        subscriptions.allReservationsStream!.stream.map((event) => null),
        subscriptions.allReservationsStream!.status.map((event) => null),
      ]).listen((_) {
        _emitState();
      }),
    );
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

    _emitState();
  }

  /// Returns the Nostr pubkey of the escrow service used in this trade,
  /// or null if no escrow proof is present.
  String? getEscrowPubkey() {
    final reservations =
        subscriptions.reservationStream?.list.value ?? const [];
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
    return null;
  }

  /// Re-runs the action resolver and emits updated state.
  void refreshActions() => _emitState();

  Future<void> execute(TradeAction action) async {
    if (!state.value.availableActions.contains(action)) {
      throw StateError('Action not available for this trade: $action');
    }

    switch (action) {
      case TradeAction.cancel:
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

  void _emitState() {
    if (state.isClosed) return;

    if (state.value.listing == null ||
        subscriptions.allReservationsStream == null ||
        subscriptions.reservationStream == null ||
        subscriptions.paymentEvents == null) {
      state.add(
        state.value.copyWith(runtimeReady: false, availableActions: const []),
      );
      return;
    }

    final actions = TradeActionResolver.resolve(
      threadState: thread.state.value,
      tradeState: state.value,
      subscriptions: subscriptions,
      ourPubkey: auth.getActiveKey().publicKey,
      addedParticipants: thread.addedParticipants,
    );

    state.add(
      state.value.copyWith(
        runtimeReady: true,
        isBlocked: actions.isBlocked,
        blockedReason: actions.blockedReason,
        availableActions: actions.actions,
      ),
    );
  }

  Future<void> close() async {
    await deactivate();
    await state.close();
  }
}
