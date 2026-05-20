import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';

import '../../util/custom_logger.dart';
import '../../util/stream_status.dart';
import '../auth/auth.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../identity_claims/identity_claims.dart';
import '../listings/listings.dart';
import '../messaging/escrow_trade_thread_resolver.dart';
import '../messaging/thread/state.dart';
import '../messaging/thread/thread.dart';
import '../messaging/threads.dart';
import '../metadata/metadata.dart';
import '../order_groups/order_group_participant_resolver.dart';
import '../order_groups/order_groups.dart';
import '../order_requests/order_requests.dart';
import '../orders/orders.dart';
import '../trade_account_allocator/trade_account_allocator.dart';
import '../user_subscriptions/user_subscriptions.dart';
import 'actions/payment.dart';
import 'actions/order.dart';
import 'actions/order_request.dart';
import 'actions/review.dart';
import 'actions/trade_action_resolver.dart';
import 'trade_state.dart';

/// Role of the local user in a trade.
enum TradeRole { host, guest }

class TradeContext {
  final String tradeId;
  final List<String> participants;
  final String conversationId;

  TradeContext({required this.tradeId, required Iterable<String> participants})
    : participants = Threads.normalizeParticipants(participants),
      conversationId = Threads.conversationId(tradeId, participants);

  String get participantKey => participants.join('\u0000');

  bool matchesParticipants(Iterable<String> other) =>
      Threads.normalizeParticipants(other).join('\u0000') == participantKey;

  bool matchesParticipantSet(
    Iterable<String> other, {
    String? optionalEscrowPubkey,
  }) {
    if (matchesParticipants(other)) return true;

    final expected = participants.toSet();
    final candidate = other.where((pubkey) => pubkey.isNotEmpty).toSet();
    if (!candidate.containsAll(expected)) return false;

    final extraParticipants = candidate.difference(expected);
    return extraParticipants.isEmpty ||
        (optionalEscrowPubkey != null &&
            optionalEscrowPubkey.isNotEmpty &&
            extraParticipants.every(
              (pubkey) => pubkey == optionalEscrowPubkey,
            ));
  }
}

/// A short-lived, reactive view-model for a single trade.
///
/// Instantiated by the UI with a [tradeId] (and optionally a [Thread] for
/// negotiation-stage access to order requests). Derives everything
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
  final IdentityClaimsUseCase _identityClaims;
  final UserSubscriptions _userSubscriptions;
  final OrderGroups _orderGroups;
  final Threads _threads;
  final TradeAccountAllocator _tradeAccountAllocator;
  final OrderRequests _orderRequests;
  final Orders _orders;

  /// Resolved lazily in [start()] from the [Threads] map.
  /// Available when opened from a thread context (negotiation-stage access).
  Thread? thread;

  /// The trade ID (d-tag of the order).
  String get tradeId => context.tradeId;

  final TradeContext context;

  String get listingAnchor {
    final anchor = _listingAnchor;
    if (anchor == null || anchor.isEmpty) {
      throw StateError('Listing anchor has not been resolved for $tradeId');
    }
    return anchor;
  }

  List<String> get participants => context.participants;
  String get conversationId => context.conversationId;

  /// Seller pubkey derived from listing anchor.
  late final String sellerPubkey;

  /// Our role in this trade.
  late final TradeRole role;

  // ── Filtered streams (from UserSubscriptions) ──────────────────────

  late final StreamWithStatus<ResolvedValidatedOrderGroupParticipants>
  resolvedOrderGroup$;
  late final StreamWithStatus<Validation<OrderGroup>> orderGroup$;
  final StreamWithStatus<PaymentEvent> payments$;
  final StreamWithStatus<OrderTransition> transitions$;
  final StreamWithStatus<Review> myReviews$;

  final BehaviorSubject<bool> subscriptionsLive$ = BehaviorSubject.seeded(
    false,
  );

  /// Listing-level order stream — only started during negotiation.
  StreamWithStatus<Validation<OrderGroup>>? allListingOrders$;

  // ── Internal bookkeeping ───────────────────────────────────────────

  final List<StreamSubscription> _subscriptions = [];
  StreamSubscription? _combineSubscription;
  // accumulateByKey children — stored so they can be closed in close().
  StreamWithStatus<List<Validation<OrderGroup>>>? _ownOrdersList$;
  StreamWithStatus<List<Validation<OrderGroup>>>? _allListingOrdersList$;
  Listing? _listing;
  String? _listingAnchor;
  ProfileMetadata? _hostProfile;
  String? _sellerEvmAddress;
  bool _bootstrapped = false;

  Trade({
    @factoryParam required this.context,
    required CustomLogger logger,
    required Auth auth,
    required Listings listings,
    required MetadataUseCase metadata,
    required IdentityClaimsUseCase identityClaims,
    required UserSubscriptions userSubscriptions,
    required OrderGroups orderGroups,
    required Threads threads,
    required TradeAccountAllocator tradeAccountAllocator,
    required OrderRequests orderRequests,
    required Orders orders,
  }) : _logger = logger.scope('trade'),
       _auth = auth,
       _listings = listings,
       _metadata = metadata,
       _identityClaims = identityClaims,
       _userSubscriptions = userSubscriptions,
       _orderGroups = orderGroups,
       _threads = threads,
       _tradeAccountAllocator = tradeAccountAllocator,
       _orderRequests = orderRequests,
       _orders = orders,
       thread = threads.findTradeThread(
         tradeId: context.tradeId,
         participants: context.participants,
       ),
       payments$ = userSubscriptions.paymentEvents$.where(
         (event) => event.tradeId == context.tradeId,
       ),
       transitions$ = userSubscriptions.allTransitions$.stream.where(
         (t) => t.parsedTags.tradeId == context.tradeId,
       ),
       myReviews$ = userSubscriptions.myReviews$,
       super(const TradeInitialising()) {
    resolvedOrderGroup$ = userSubscriptions.allMyResolvedOrderGroups$.where(
      _matchesResolvedOrderGroup,
    );
    orderGroup$ = resolvedOrderGroup$.map((item) => item.validation);
    _subscriptions.add(
      Rx.combineLatest3(
        orderGroup$.status,
        payments$.status,
        transitions$.status,
        (a, b, c) => [a, b, c],
      ).listen((statuses) {
        logger.d(
          'OrderGroup status: ${orderGroup$.status.value}, '
          'Payments status: ${payments$.status.value}, '
          'Transitions status: ${transitions$.status.value}; '
          'OrderGroup seller: ${orderGroup$.items.lastOrNull?.event.sellerOrder}, '
          'OrderGroup buyer: ${orderGroup$.items.lastOrNull?.event.buyerOrder}, '
          'OrderGroup escrow: ${orderGroup$.items.lastOrNull?.event.escrowOrder}, ',
        );
        final allLive = statuses.every((s) => s is StreamStatusLive);
        if (allLive && !(subscriptionsLive$.value)) {
          subscriptionsLive$.sink.add(true);
        }
      }),
    );
  }

  bool _matchesResolvedOrderGroup(
    ResolvedValidatedOrderGroupParticipants item,
  ) {
    if (item.group.tradeId != context.tradeId) return false;
    final escrowPubkey = item.group.escrowPubkey;
    if (item.participants.rawGroupId == context.conversationId) {
      return true;
    }
    if (item.participants.resolvedGroupId == context.conversationId) {
      return true;
    }
    if (context.matchesParticipantSet(
      item.participants.rawParticipantSet,
      optionalEscrowPubkey: escrowPubkey,
    )) {
      return true;
    }
    if (context.matchesParticipantSet(
      item.participants.resolvedParticipantSet,
      optionalEscrowPubkey: escrowPubkey,
    )) {
      return true;
    }
    if (_matchesLocalParticipantAlias(item)) return true;
    return false;
  }

  bool _matchesLocalParticipantAlias(
    ResolvedValidatedOrderGroupParticipants item,
  ) {
    final activePubkey = _auth.activePubkey ?? _auth.getActiveKey().publicKey;
    if (activePubkey.isEmpty || !context.participants.contains(activePubkey)) {
      return false;
    }

    final buyerPubkey = item.participants.rawParticipantPubkeyForRole('buyer');
    if (buyerPubkey == null ||
        buyerPubkey.isEmpty ||
        buyerPubkey == activePubkey ||
        !item.participants.hasParticipantProofFor(buyerPubkey)) {
      return false;
    }

    final adjusted = item.participants.resolvedParticipantSet.toSet();
    if (!adjusted.remove(buyerPubkey)) return false;
    adjusted.add(activePubkey);

    final expected = context.participants.toSet();
    if (!adjusted.containsAll(expected)) return false;

    final extraParticipants = adjusted.difference(expected);
    final escrowPubkey = item.group.escrowPubkey;
    return extraParticipants.isEmpty ||
        (escrowPubkey != null &&
            extraParticipants.every((pubkey) => pubkey == escrowPubkey));
  }

  Future<String?> resolveGuestPubkey() =>
      _logger.span('resolveGuestPubkey', () async {
        for (final item in resolvedOrderGroup$.items.reversed) {
          final resolved = item.participants.resolvedParticipantPubkeyForRole(
            'buyer',
          );
          if (resolved != null && resolved.isNotEmpty) return resolved;
        }

        final request = thread?.state.value.orderRequests.lastOrNull;
        if (request == null) return null;
        return request.parsedTags.getTagValueByMarker('p', 'buyer') ??
            request.recipient;
      });

  Future<void> start() => _logger.span('start', () async {
    if (_bootstrapped || isClosed) return;
    _bootstrapped = true;
    _userSubscriptions.trackTradeId(tradeId);
    thread ??= _findThreadForTrade();

    final resolvedListingAnchor = await _resolveListingAnchor();
    if (resolvedListingAnchor == null || resolvedListingAnchor.isEmpty) {
      _logger.w('Cannot start trade $tradeId: listing anchor unavailable');
      if (!isClosed) emit(TradeError('Listing unavailable'));
      return;
    }
    _listingAnchor = resolvedListingAnchor;
    sellerPubkey = getPubKeyFromAnchor(resolvedListingAnchor);
    role = sellerPubkey == _auth.getActiveKey().publicKey
        ? TradeRole.host
        : TradeRole.guest;

    final fetchedListing = await _listings.getOneByAnchor(listingAnchor);
    if (fetchedListing == null) {
      _logger.w('Cannot start trade $tradeId: listing unavailable');
      if (!isClosed) emit(TradeError('Listing unavailable'));
      return;
    }
    _listing = fetchedListing;

    _hostProfile = await _metadata.loadMetadata(sellerPubkey);
    _sellerEvmAddress = await _identityClaims.loadEvmAddress(sellerPubkey);

    _wirePipeline();
  });

  Future<String?> _resolveListingAnchor() async {
    thread ??= _findThreadForTrade();
    final fromThread = _listingAnchorFromThread(thread);
    if (fromThread != null) return fromThread;

    final immediate = _listingAnchorFromLoadedItems();
    if (immediate != null) return immediate;

    final anchorStreams = <Stream<String>>[];
    final currentThread = thread;
    if (currentThread != null) {
      anchorStreams.add(
        currentThread.state.stream
            .map(_listingAnchorFromThreadState)
            .whereType<String>()
            .where((anchor) => anchor.isNotEmpty),
      );
    }

    final groupMatch = orderGroup$.replayStream
        .map((validation) {
          try {
            return validation.event.listingAnchor;
          } catch (_) {
            return '';
          }
        })
        .where((anchor) => anchor.isNotEmpty);
    anchorStreams.add(groupMatch);

    final orderMatch = _userSubscriptions.allMyOrders$.stream.replayStream
        .where(_matchesOrder)
        .map((order) => order.parsedTags.listingAnchor)
        .where((anchor) => anchor.isNotEmpty);
    anchorStreams.add(orderMatch);

    try {
      return await Rx.merge(anchorStreams).first;
    } on StateError {
      return null;
    }
  }

  String? _listingAnchorFromThread(Thread? thread) {
    return _listingAnchorFromThreadState(thread?.state.value);
  }

  String? _listingAnchorFromThreadState(ThreadState? state) {
    return state?.orderRequests
        .map((request) => request.parsedTags.listingAnchor)
        .where((anchor) => anchor.isNotEmpty)
        .firstOrNull;
  }

  String? _listingAnchorFromLoadedItems() {
    for (final validation in orderGroup$.items) {
      try {
        final anchor = validation.event.listingAnchor;
        if (anchor.isNotEmpty) return anchor;
      } catch (_) {
        // Keep looking; incomplete groups may not have a listing anchor yet.
      }
    }

    return _userSubscriptions.allMyOrders$.stream.items
        .where(_matchesOrder)
        .map((order) => order.parsedTags.listingAnchor)
        .where((anchor) => anchor.isNotEmpty)
        .firstOrNull;
  }

  bool _matchesOrder(Order order) {
    if (order.getDtag() != tradeId) return false;
    return true;
  }

  void _wirePipeline() => _logger.spanSync('_wirePipeline', () {
    final listing = _listing!;
    final hostProfile = _hostProfile;
    final sellerEvmAddress = _sellerEvmAddress;

    allListingOrders$ = _orderGroups.queryVerified(
      listingAnchor: listingAnchor,
      forceValidatePredicate: (group) => group.tradeId == tradeId,
    );

    final threadState$ = thread != null
        ? thread!.state.stream.startWith(thread!.state.value)
        : Stream<ThreadState?>.value(null);

    _combineSubscription =
        Rx.combineLatest7(
          (_ownOrdersList$ = orderGroup$.accumulateByKey(
            (g) => g.event.groupId,
          )).replayStream,
          payments$.itemsStream,
          transitions$.itemsStream,
          (_allListingOrdersList$ = allListingOrders$!.accumulateByKey(
            (g) => g.event.groupId,
          )).replayStream,
          allListingOrders$!.status,
          threadState$,
          myReviews$.itemsStream,
          (
            List<Validation<OrderGroup>> ownOrders,
            List<PaymentEvent> payments,
            List<OrderTransition> transitions,
            List<Validation<OrderGroup>> allListingOrders,
            StreamStatus allListingOrdersStatus,
            ThreadState? threadState,
            List<Review> myReviews,
          ) {
            final listingReviews = myReviews
                .where(
                  (review) => review.parsedTags.listingAnchor == listingAnchor,
                )
                .toList();
            return _resolve(
              listing: listing,
              hostProfile: hostProfile,
              sellerEvmAddress: sellerEvmAddress,
              ownOrders: ownOrders,
              ownOrdersStatus: orderGroup$.status.value,
              payments: payments,
              paymentsStatus: payments$.status.value,
              transitions: transitions,
              allListingOrders: allListingOrders,
              allListingOrdersStatus: allListingOrdersStatus,
              threadState: threadState,
              myReviews: listingReviews,
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
  });

  /// from the current stream snapshots.
  TradeReady _resolve({
    required Listing listing,
    required ProfileMetadata? hostProfile,
    required String? sellerEvmAddress,
    required List<Validation<OrderGroup>> ownOrders,
    required StreamStatus ownOrdersStatus,
    required List<PaymentEvent> payments,
    required StreamStatus paymentsStatus,
    required List<OrderTransition> transitions,
    required List<Validation<OrderGroup>> allListingOrders,
    required StreamStatus allListingOrdersStatus,
    required ThreadState? threadState,
    List<Review> myReviews = const [],
  }) => _logger.spanSync('_resolve', () {
    thread =
        _threads.findTradeThread(
          tradeId: tradeId,
          participants: participants,
        ) ??
        _findThreadForTrade();

    // Derive last order request from thread (if available).
    final orderRequests = threadState?.orderRequests ?? const [];
    final lastRequest = orderRequests.isNotEmpty ? orderRequests.last : null;

    // Trade dates should remain available even when the order request
    // did not travel via DMs (or the thread cannot be resolved).
    final validOrderGroup = ownOrders
        .whereType<Valid<OrderGroup>>()
        .map((v) => v.event)
        .where((g) => !g.cancelled)
        .firstOrNull;
    final anyOrderGroup = ownOrders
        .whereType<Valid<OrderGroup>>()
        .map((v) => v.event)
        .firstOrNull;
    final orderGroupForSummary = validOrderGroup ?? anyOrderGroup;

    final start = lastRequest?.start ?? orderGroupForSummary?.start;
    final end = lastRequest?.end ?? orderGroupForSummary?.end;
    final amount =
        lastRequest?.amount ?? orderGroupForSummary?.buyerOrder?.amount;
    final ourPubkey = _resolveNegotiationPubkey(orderRequests);
    final latestRequestCancelled = lastRequest?.stage == OrderStage.cancel;

    // Compute overlap lock from listing-level orders.
    final validAllListingPairs = allListingOrders
        .whereType<Valid<OrderGroup>>()
        .map((v) => v.event)
        .where((p) => !p.cancelled)
        .toList();
    final allListingOrdersLoaded =
        allListingOrdersStatus is StreamStatusQueryComplete ||
        allListingOrdersStatus is StreamStatusLive;
    final overlapLock = allListingOrdersLoaded
        ? resolveOverlapLock(
            ourOrderDTag: tradeId,
            allListingOrderGroups: validAllListingPairs,
            startDate: start,
            endDate: end,
          )
        : (isLoading: true, isBlocked: false, reason: null);
    final hasPayment = payments.isNotEmpty;

    // Determine stage + resolve actions.
    final bool isNegotiation =
        ownOrdersStatus is StreamStatusLive && ownOrders.isEmpty;

    late final TradeStage stage;
    final resolvedActions = <TradeAction>[];

    if (isNegotiation) {
      final policy = OrderRequestActions.resolvePolicy(
        orderRequests,
        listing,
        ourPubkey,
        role,
      );
      stage = NegotiationStage(
        orderRequests: orderRequests,
        overlapLock: overlapLock,
        policy: policy,
      );

      // Negotiation actions: pay / counter / accept.
      if (threadState != null && !hasPayment && !latestRequestCancelled) {
        resolvedActions.addAll(
          OrderRequestActions.resolve(orderRequests, listing, ourPubkey, role),
        );
      }
    } else {
      // Extract the order pair for commit stage.
      final validGroup = ownOrders
          .whereType<Valid<OrderGroup>>()
          .map((v) => v.event)
          .where((p) => !p.cancelled)
          .firstOrNull;
      final anyValidGroup = ownOrders
          .whereType<Valid<OrderGroup>>()
          .map((v) => v.event)
          .firstOrNull;
      final anyObservedGroup = ownOrders
          .map((validation) => validation.event)
          .firstOrNull;
      final commitOrderGroup =
          validGroup ?? anyValidGroup ?? anyObservedGroup ?? OrderGroup();

      stage = CommitStage(
        orderGroup: commitOrderGroup,
        payments: payments,
        transitions: transitions,
      );

      // Commit actions: cancel, refund, claim, messageEscrow.
      final allTradeOrders = ownOrders
          .expand((validation) => validation.event.orders)
          .toList();

      final validTradeOrders = ownOrders
          .whereType<Valid<OrderGroup>>()
          .where((v) => !v.event.cancelled)
          .expand((v) => v.event.orders)
          .toList();

      resolvedActions.addAll(
        PaymentActions.resolve(payments, paymentsStatus, role),
      );

      resolvedActions.addAll(
        OrderActions.resolve(
          validTradeOrders,
          ownOrdersStatus,
          role,
          allOrders: allTradeOrders,
        ),
      );

      resolvedActions.addAll(
        ReviewActions.resolve(
          orderGroup: validGroup ?? anyValidGroup ?? OrderGroup(),
          orderStreamStatus: ownOrdersStatus,
          payments: payments,
          role: role,
          myReviews: myReviews,
        ),
      );
    }

    // Availability.
    final availability = _resolveAvailability(
      ownOrders: ownOrders,
      overlapLock: overlapLock,
      negotiationCancelled: isNegotiation && latestRequestCancelled,
    );

    return TradeReady(
      listing: listing,
      sellerProfile: hostProfile,
      sellerEvmAddress: sellerEvmAddress,
      sellerPubkey: sellerPubkey,
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
        orderStream: orderGroup$,
        transitionsStream: transitions$,
        subscriptionsLive: subscriptionsLive$,
      ),
    );
  });

  Thread? _findThreadForTrade() {
    final exact = _threads.findTradeThread(
      tradeId: tradeId,
      participants: participants,
    );
    if (exact != null) return exact;

    final matches = _threads.findByConversationTag(tradeId);
    if (matches.length == 1) return matches.single;
    for (final thread in matches) {
      if (thread.state.value.orderRequests.any(
        (request) => request.getDtag() == tradeId,
      )) {
        return thread;
      }
    }
    return null;
  }

  static TradeAvailability _resolveAvailability({
    required List<Validation<OrderGroup>> ownOrders,
    required OverlapLock overlapLock,
    bool negotiationCancelled = false,
  }) {
    if (negotiationCancelled) {
      return TradeAvailability.cancelled;
    }
    if (ownOrders.any((v) => v is Invalid)) {
      return TradeAvailability.invalidOrder;
    }
    if (ownOrders.whereType<Valid<OrderGroup>>().any(
      (v) => v.event.cancelled,
    )) {
      return TradeAvailability.cancelled;
    }
    if (overlapLock.isLoading) return TradeAvailability.loading;
    if (overlapLock.isBlocked) return TradeAvailability.unavailable;
    return TradeAvailability.available;
  }

  // ── Public API ─────────────────────────────────────────────────────

  /// Current order pair status list (for action execution).
  List<Validation<OrderGroup>> get currentOrderGroups =>
      _bootstrapped ? orderGroup$.items : const [];

  Future<KeyPair> activeKeyPair() => _logger.span('activeKeyPair', () async {
    if (role == TradeRole.host) {
      return _auth.getActiveKey();
    }

    final accountIndex = await _tradeAccountAllocator
        .findTradeAccountIndexByTradeId(tradeId);
    return _auth.hd.getTradeKeyPair(accountIndex: accountIndex);
  });

  Future<Thread> resolveEscrowThread({
    Duration timeout = const Duration(seconds: 12),
  }) {
    return EscrowTradeThreadResolver(
      auth: _auth,
      orders: _orders,
      userSubscriptions: _userSubscriptions,
      threads: _threads,
      tradeAccountAllocator: _tradeAccountAllocator,
      logger: _logger,
    ).resolve(tradeId: tradeId, timeout: timeout);
  }

  String _resolveNegotiationPubkey(List<Order> orderRequests) {
    if (role == TradeRole.host) {
      return _auth.getActiveKey().publicKey;
    }

    return _firstGuestNegotiationPubkey(orderRequests) ??
        orderRequests.lastOrNull?.recipient ??
        _auth.getActiveKey().publicKey;
  }

  String? _firstGuestNegotiationPubkey(List<Order> orderRequests) {
    for (final request in orderRequests.reversed) {
      if (request.pubKey != sellerPubkey) {
        return request.pubKey;
      }
    }
    return null;
  }

  Future<void> counter(DenominatedAmount amount) =>
      _logger.span('counter', () async {
        final current = state;
        if (current is! TradeReady || current.stage is! NegotiationStage) {
          throw StateError('Trade is not in negotiation stage');
        }

        final negotiationStage = current.stage as NegotiationStage;
        final policy = negotiationStage.policy;
        final lastRequest = negotiationStage.orderRequests.lastOrNull;
        if (lastRequest == null) {
          throw StateError('No order request available to counter');
        }
        if (!policy.canCounter) {
          throw StateError('Counter offer is not available for this trade');
        }

        final min = policy.counterMin;
        final max = policy.counterMax;
        if (min != null &&
            amount.denomination == min.denomination &&
            amount.value < min.value) {
          throw StateError('Counter amount is below the allowed minimum');
        }
        if (max != null &&
            amount.denomination == max.denomination &&
            amount.value > max.value) {
          throw StateError('Counter amount is above the allowed maximum');
        }

        final event = await _orderRequests.createCounterOffer(
          listing: current.listing,
          previousRequest: lastRequest,
          amount: amount,
          signerKeyPair: await activeKeyPair(),
        );

        await thread!.replyEventAndWait(event);
      });

  Future<void> acceptLatestOffer() =>
      _logger.span('acceptLatestOffer', () async {
        final current = state;
        if (current is! TradeReady || current.stage is! NegotiationStage) {
          throw StateError('Trade is not in negotiation stage');
        }
        if (role != TradeRole.host) {
          throw StateError('Only the host can accept order requests');
        }

        final negotiationStage = current.stage as NegotiationStage;
        final lastRequest = negotiationStage.orderRequests.lastOrNull;
        if (lastRequest == null) {
          throw StateError('No order request available to accept');
        }
        if (!current.actions.contains(TradeAction.accept)) {
          throw StateError('Accept action is not available for this trade');
        }

        final acceptedAmount = lastRequest.amount;
        if (acceptedAmount == null) {
          throw StateError('Cannot accept a order request without amount');
        }

        final event = await _orderRequests.createCounterOffer(
          listing: current.listing,
          previousRequest: lastRequest,
          amount: acceptedAmount,
          signerKeyPair: await activeKeyPair(),
        );

        await thread!.replyEventAndWait(event);
      });

  Future<void> cancelNegotiation() =>
      _logger.span('cancelNegotiation', () async {
        final current = state;
        if (current is! TradeReady || current.stage is! NegotiationStage) {
          throw StateError('Trade is not in negotiation stage');
        }

        final negotiationStage = current.stage as NegotiationStage;
        final lastRequest = negotiationStage.orderRequests.lastOrNull;
        if (lastRequest == null) {
          throw StateError('No order request available to cancel');
        }
        if (lastRequest.stage == OrderStage.cancel) {
          throw StateError('Order request is already cancelled');
        }
        if (!current.actions.contains(TradeAction.cancel)) {
          throw StateError('Cancel action is not available for this trade');
        }
        if (thread == null) {
          throw StateError('Cannot cancel negotiation without a thread');
        }

        final event = await _orderRequests.createCancellation(
          previousRequest: lastRequest,
          signerKeyPair: await activeKeyPair(),
        );

        await thread!.replyEventAndWait(event);
      });

  /// Returns the Nostr pubkey of the escrow service used in this trade.
  String? getEscrowPubkey() => _logger.spanSync('getEscrowPubkey', () {
    final current = state;
    if (current is TradeReady && current.stage is CommitStage) {
      final group = (current.stage as CommitStage).orderGroup;
      final pubkey = group.escrowPubkey;
      if (pubkey != null && pubkey.isNotEmpty) return pubkey;
    }

    final groups = orderGroup$.items;
    for (final validation in groups) {
      final group = validation.event;
      final pubkey = group.escrowPubkey;
      if (pubkey != null) return pubkey;
    }
    return null;
  });

  Future<void> execute(TradeAction action) => _logger.span('execute', () async {
    final current = state;
    if (current is! TradeReady || !current.actions.contains(action)) {
      throw StateError('Action not available for this trade: $action');
    }

    switch (action) {
      case TradeAction.cancel:
        if (current.stage is NegotiationStage) {
          await cancelNegotiation();
          return;
        }
        await OrderActions(trade: this, orders: _orders).cancel();
        return;
      case TradeAction.claim:
        throw UnimplementedError('Trade claim is not implemented yet.');
      case TradeAction.refund:
        throw UnimplementedError('Trade refund/redeem is not implemented yet.');
      case TradeAction.accept:
        await acceptLatestOffer();
        return;
      case TradeAction.counter:
      case TradeAction.pay:
      case TradeAction.review:
        throw UnsupportedError(
          'Action not supported by trade executor: $action',
        );
      case TradeAction.messageEscrow:
        return;
    }
  });

  // ── Dispose ────────────────────────────────────────────────────────

  @override
  Future<void> close() => _logger.span('close', () async {
    await _combineSubscription?.cancel();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    if (_bootstrapped) {
      await _ownOrdersList$?.close();
      await _allListingOrdersList$?.close();
      await allListingOrders$?.close();
      await orderGroup$.close();
      await payments$.close();
      await transitions$.close();
    }
    await super.close();
  });
}
