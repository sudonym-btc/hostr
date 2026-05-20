import 'dart:async';

import 'package:injectable/injectable.dart' hide Order;
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
import '../order_transitions/order_transitions.dart';
import 'order_participant_authorization_resolver.dart';
import 'order_participant_tags.dart';

class Commitment {
  final String hash;

  Commitment({required this.hash});
}

/// Dependencies resolved for a single review verification.
class OrderDeps {
  final Listing? listing;

  const OrderDeps({this.listing});
}

@Singleton()
class Orders extends CrudUseCase<Order> implements CanVerify<Order, OrderDeps> {
  final Messaging _messaging;
  final Auth _auth;
  final OrderTransitions _transitions;
  final Listings _listings;
  final Relays _relays;
  late final OrderParticipantAuthorizationResolver
  _participantAuthorizationResolver = OrderParticipantAuthorizationResolver(
    logger: logger,
  );
  Messaging get messaging => _messaging;
  Auth get auth => _auth;
  OrderTransitions get transitions => _transitions;
  Listings get listings => _listings;
  StreamWithStatus<Order>? _myOrders;
  StreamSubscription<Order>? _myOrdersSubscription;
  Orders({
    required super.requests,
    required super.logger,
    required Messaging messaging,
    required Auth auth,
    required OrderTransitions transitions,
    required Listings listings,
    required Relays relays,
  }) : _messaging = messaging,
       _auth = auth,
       _transitions = transitions,
       _listings = listings,
       _relays = relays,
       super(kind: Order.kinds[0]);

  int _nextReplacementCreatedAt(Order existing) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now <= existing.createdAt ? existing.createdAt + 1 : now;
  }

  @override
  Future<void> beforeUpsert(Order event) async {
    if (event.stage == OrderStage.negotiate) {
      throw StateError(
        'Negotiate-stage orders must be sent as private messages, not broadcast.',
      );
    }
  }

  Future<Order> _signOrder({
    required Order order,
    required KeyPair signerKeyPair,
  }) async {
    final activeNdkPubkey = requests.ndk.accounts.getPublicKey();
    if (activeNdkPubkey == signerKeyPair.publicKey) {
      return Order.fromNostrEvent(await requests.ndk.accounts.sign(order));
    }

    final privateKey = signerKeyPair.privateKey;
    if (privateKey == null || privateKey.isEmpty) {
      throw StateError(
        'No signer available for order pubkey ${signerKeyPair.publicKey}',
      );
    }

    return order.signAs(signerKeyPair, Order.fromNostrEvent);
  }

  /// Query all orders for a given trade id (d-tag).
  Future<List<Order>> getByTradeId(String tradeId) {
    logger.d('Fetching orders for tradeId: $tradeId');
    return list(
      Filter(kinds: Order.kinds, dTags: [tradeId]),
      name: 'byTradeId-$tradeId',
    );
  }

  Future<List<Order>> getListingOrders({required String listingAnchor}) {
    logger.d('Fetching orders for listing: $listingAnchor');
    return findByTag(kListingRefTag, listingAnchor).then((orders) {
      logger.d('Found ${orders.length} orders');
      return orders;
    });
  }

  String _tradeIdFor(Order order) {
    return order.getDtag() ?? order.id;
  }

  Future<String> _signParticipantAuthorization({
    required String listingAnchor,
    required KeyPair identityKeyPair,
    required OrderParticipantAuthorizationDraft draft,
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
    return OrderParticipantAuthorizationPayload.fromAuthorizationEvent(
      signedAuthorization,
    ).encode();
  }

  Iterable<Order> _threadOrderCandidates({
    required String tradeId,
    Order? fallback,
  }) sync* {
    final seen = <String>{};

    if (fallback != null) {
      if (seen.add(fallback.id)) yield fallback;
    }
    for (final thread in messaging.threads.findByConversationTag(tradeId)) {
      for (final order in thread.state.value.orderRequests) {
        if (seen.add(order.id)) yield order;
      }
      for (final order in thread.state.value.events.whereType<Order>()) {
        if (seen.add(order.id)) yield order;
      }
    }
  }

  Future<ParticipationProof> createParticipationProofForReview({
    required Order order,
    required String role,
    required KeyPair recipientKeyPair,
    required KeyPair identityKeyPair,
  }) {
    return _participantAuthorizationResolver.createReviewProof(
      order: order,
      role: role,
      recipientKeyPair: recipientKeyPair,
      identityPubkey: identityKeyPair.publicKey,
    );
  }

  Map<String, List<Order>> groupByCommitment(
    List<Order> orders,
    Listing listing,
  ) {
    final Map<String, List<Order>> grouped = {};
    for (final order in orders) {
      final tradeId = _tradeIdFor(order);
      grouped.putIfAbsent(tradeId, () => []).add(order);
    }
    // Remove non-host order if a host order exists for same trade.
    for (final entry in grouped.entries) {
      final tradeId = entry.key;
      final group = entry.value;
      final hostOrders = group
          .where((order) => order.pubKey == listing.pubKey)
          .toList();
      if (hostOrders.isNotEmpty) {
        grouped[tradeId] = hostOrders;
      }
    }
    return grouped;
  }

  static Order? seniorOrders(List<Order> orders) {
    return Order.getSeniorOrder(orders: orders);
  }

  static List<Order> filterCancelled(List<Order> orders) {
    return orders.where((e) => !e.cancelled).toList();
  }

  /// Converts a flat list of orders into [OrderGroup] objects
  /// grouped by trade id (`d` tag).
  ///
  /// Each group's role-based getters (sellerOrder, buyerOrder,
  /// escrowOrder) are computed from the flat list automatically.
  static Map<String, OrderGroup> toOrderGroups({required List<Order> orders}) {
    final Map<String, List<Order>> grouped = {};

    for (final order in orders) {
      final groupId = rawOrderGroupId(order);
      grouped.putIfAbsent(groupId, () => []);
      // Replace any existing order from the same pubkey
      grouped[groupId]!.removeWhere((r) => r.pubKey == order.pubKey);
      grouped[groupId]!.add(order);
    }

    return grouped.map(
      (groupId, list) => MapEntry(groupId, OrderGroup(orders: list)),
    );
  }

  /// Queries all orders for [listing] and returns them grouped as
  /// [OrderGroup] by trade id (`d` tag).
  Future<Map<String, OrderGroup>> queryOrderGroups({
    required Listing listing,
  }) async {
    final orders = await getListingOrders(listingAnchor: listing.anchor!);
    return toOrderGroups(orders: orders);
  }

  Map<String, OrderGroup> groupByThread(List<Order> orders) {
    final Map<String, List<Order>> grouped = {};

    for (final order in orders) {
      final tradeId = order.getDtag();
      if (tradeId == null || tradeId.isEmpty) continue;
      final participants = rawOrderParticipantSet(order);
      final thread = messaging.threads.findTradeThread(
        tradeId: tradeId,
        participants: participants,
      );
      if (thread == null) continue;

      final groupId = rawOrderGroupId(order);
      grouped.putIfAbsent(groupId, () => []);
      grouped[groupId]!.removeWhere((r) => r.pubKey == order.pubKey);
      grouped[groupId]!.add(order);
    }

    return grouped.map(
      (groupId, list) => MapEntry(groupId, OrderGroup(orders: list)),
    );
  }

  StreamWithStatus<Order> subscribeToMyOrders() {
    if (_myOrders != null) {
      return _myOrders!;
    }

    final response = StreamWithStatus<Order>();
    response.addStatus(StreamStatusLive());

    _myOrders = response;

    final ordersStream = messaging.threads.events$.replayStream
        .whereType<Message>()
        .map((message) => message.child)
        .whereType<Order>()
        .asyncMap((negotiateOrder) async {
          logger.d(
            'Processing negotiate order: $negotiateOrder, ${negotiateOrder.getFirstTag('a')}',
          );
          final orders = await getListingOrders(
            listingAnchor: negotiateOrder.parsedTags.listingAnchor,
          );
          logger.d('Found orders: $orders');
          return orders.firstWhere(
            (order) => order.getDtag() == negotiateOrder.getDtag(),
            orElse: () => throw Exception('Order not found'),
          );
        })
        .distinct((a, b) => a.id == b.id);

    unawaited(_myOrdersSubscription?.cancel());
    _myOrdersSubscription = ordersStream.listen(
      response.add,
      onError: response.addError,
    );

    return response;
  }

  Future<List<RelayBroadcastResponse>> accept(
    String anchor,
    Order request,
    String guestPubkey,
    String saltedPubkey,
  ) async {
    final sellerHint = await _relays.relayHintFor(
      auth.activeKeyPair!.publicKey,
    );
    final buyerHint = await _relays.relayHintFor(saltedPubkey);
    final order = Order.create(
      pubKey: auth.activeKeyPair!.publicKey,
      dTag: request.getDtag()!,
      listingAnchor: request.parsedTags.listingAnchor,
      pTags: [
        PTag.seller(auth.activeKeyPair!.publicKey, relayHint: sellerHint),
        PTag.buyer(saltedPubkey, relayHint: buyerHint),
      ],
      start: request.start,
      end: request.end,
      stage: OrderStage.commit,
      quantity: request.quantity,
      amount: request.amount,
      recipient: request.recipient,
    );
    logger.d('Accepting order request: $request');
    return _upsertWithTransition(
      order: order,
      transitionType: OrderTransitionType.commit,
      fromStage: OrderStage.negotiate,
      toStage: OrderStage.commit,
      signerKeyPair: auth.activeKeyPair,
      commitTermsHash: request.commitHash(),
    );
  }

  Future<Order> createSelfSigned({
    required KeyPair activeKeyPair,
    required Order negotiateOrder,
    required PaymentProof proof,
  }) async {
    final tradeId = negotiateOrder.getDtag();
    final listingAnchor = negotiateOrder.parsedTags.listingAnchor;

    final sellerPk = getPubKeyFromAnchor(listingAnchor);
    final escrowPk = proof.escrowProof?.escrowService.escrowPubkey;
    final participantPlan = await buildOrderParticipantTagPlan(
      tradeId: tradeId!,
      orderAuthorKey: activeKeyPair,
      participants: [
        OrderParticipant.real(role: 'seller', pubkey: sellerPk),
        OrderParticipant(
          role: 'buyer',
          participantPubkey: activeKeyPair.publicKey,
          identityPubkey: auth.getActiveKey().publicKey,
        ),
        if (escrowPk != null)
          OrderParticipant.real(role: 'escrow', pubkey: escrowPk),
      ],
      relayHintFor: _relays.relayHintFor,
      signAuthorization: (draft) async {
        final reused = await _participantAuthorizationResolver
            .findReusableAuthorization(
              draft: draft,
              recipientKeyPair: activeKeyPair,
              candidates: _threadOrderCandidates(
                tradeId: tradeId,
                fallback: negotiateOrder,
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

    final order = Order.create(
      pubKey: activeKeyPair.publicKey,
      dTag: tradeId,
      listingAnchor: listingAnchor,
      start: negotiateOrder.start,
      end: negotiateOrder.end,
      stage: OrderStage.commit,
      quantity: negotiateOrder.quantity,
      amount: negotiateOrder.amount,
      recipient: negotiateOrder.recipient,
      proof: proof,
      commitAuthorization: negotiateOrder.commitAuthorization,
      extraTags: participantPlan.tags,
    );

    final signedOrder = order.signAs(activeKeyPair, Order.fromNostrEvent);
    await _upsertWithTransition(
      order: signedOrder,
      transitionType: OrderTransitionType.commit,
      fromStage: OrderStage.negotiate,
      toStage: OrderStage.commit,
      signerKeyPair: activeKeyPair,
      commitTermsHash: signedOrder.commitHash(),
    );
    logger.d('Created self-signed order: $signedOrder');
    return signedOrder;
  }

  /// Builds [PTag]s with relay hints for all participants in a
  /// [OrderGroup]. Used by [cancel] and [confirm].
  Future<List<PTag>> _pTagsForGroup(OrderGroup group) async {
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

  // @todo: move to orderGroup?
  // @todo: cancel / confirm order methods should use the same logic. Escrow must confirm when acknowledging transaction correct, host can confirm when they manually approve a transaction
  // cancel and confirm just change the stage of the order, so they should share logic
  Future<Order> cancel(OrderGroup orderGroup, KeyPair keyPair) async {
    if (orderGroup.cancelled) {
      throw Exception('OrderGroup is already cancelled');
    }
    final myOrder = orderGroup.orders
        .where((r) => r.pubKey == keyPair.publicKey)
        .firstOrNull;
    final pTags = await _pTagsForGroup(orderGroup);
    final blank = Order.create(
      pubKey: keyPair.publicKey,
      dTag: orderGroup.tradeId,
      listingAnchor: orderGroup.listingAnchor,
      stage: OrderStage.cancel,
      pTags: pTags,
      start: orderGroup.start,
      end: orderGroup.end,
    );
    final unsigned = myOrder == null
        ? blank
        : myOrder.copy(
            createdAt: _nextReplacementCreatedAt(myOrder),
            id: null,
            content: myOrder.parsedContent.copyWith(stage: OrderStage.cancel),

            pubKey: keyPair.publicKey,
          );
    final updated = await _signOrder(order: unsigned, signerKeyPair: keyPair);
    logger.d('Cancelling order: $updated');
    await _upsertWithTransition(
      order: updated,
      transitionType: OrderTransitionType.cancel,
      fromStage: myOrder?.stage ?? OrderStage.negotiate,
      toStage: OrderStage.cancel,
      signerKeyPair: keyPair,
      commitTermsHash: updated.commitHash(),
    );
    return updated;
  }

  /// Confirms a committed order, signalling that payment proof has been
  /// validated.
  ///
  /// Mirrors [cancel]: the caller re-publishes their copy of the order
  /// in the [OrderStage.commit] stage and emits a
  /// [OrderTransitionType.confirm] transition.
  ///
  /// Typically invoked by the escrow daemon after verifying the on-chain /
  /// lightning settlement. Host or buyer can also call this to manually
  /// acknowledge a transaction.
  ///
  /// The set of `p` tags is preserved from [orderGroup] so all
  /// participants remain in scope.
  Future<Order> confirm(OrderGroup orderGroup, KeyPair keyPair) async {
    if (orderGroup.cancelled) {
      throw Exception('OrderGroup is already cancelled — cannot confirm');
    }
    if (orderGroup.stage != OrderStage.commit) {
      throw Exception('OrderGroup is not yet committed — cannot confirm');
    }
    final myOrder = orderGroup.orders
        .where((r) => r.pubKey == keyPair.publicKey)
        .firstOrNull;
    final pTags = await _pTagsForGroup(orderGroup);
    final blank = Order.create(
      pubKey: keyPair.publicKey,
      dTag: orderGroup.tradeId,
      listingAnchor: orderGroup.listingAnchor,
      stage: OrderStage.commit,
      pTags: pTags,
    );
    final unsigned = myOrder == null
        ? blank
        : myOrder.copy(
            createdAt: _nextReplacementCreatedAt(myOrder),
            id: null,
            content: myOrder.parsedContent.copyWith(stage: OrderStage.commit),
            pubKey: keyPair.publicKey,
          );
    final updated = await _signOrder(order: unsigned, signerKeyPair: keyPair);
    logger.d('Confirming order: $updated');
    await _upsertWithTransition(
      order: updated,
      transitionType: OrderTransitionType.confirm,
      fromStage: OrderStage.commit,
      toStage: OrderStage.commit,
      signerKeyPair: keyPair,
      commitTermsHash: updated.commitHash(),
    );
    return updated;
  }

  /// Broadcasts [order] and atomically records its lifecycle transition.
  ///
  /// All public mutation methods that advance a order through its
  /// lifecycle ([accept], [createSelfSigned], [cancel], [createBlocked]) MUST
  /// use this instead of calling [upsert] + [transitions.record] separately,
  /// enforcing the invariant that no order is broadcast without a
  /// transition record.
  Future<List<RelayBroadcastResponse>> _upsertWithTransition({
    required Order order,
    required OrderTransitionType transitionType,
    required OrderStage fromStage,
    required OrderStage toStage,
    KeyPair? signerKeyPair,
    String? commitTermsHash,
    String? reason,
  }) async {
    final result = await upsert(order);
    await transitions.record(
      order: order,
      transitionType: transitionType,
      fromStage: fromStage,
      toStage: toStage,
      signerKeyPair: signerKeyPair,
      commitTermsHash: commitTermsHash,
      reason: reason,
    );
    return result.responses;
  }

  Future<Order> createBlocked({
    required String listingAnchor,
    required DateTime start,
    required DateTime end,
  }) async {
    final nonce = Order.getNonceForBlockedOrder(
      start: start,
      end: end,
      hostKey: auth.activeKeyPair!,
    );
    final sellerHint = await _relays.relayHintFor(
      auth.activeKeyPair!.publicKey,
    );
    final order = Order.create(
      pubKey: auth.activeKeyPair!.publicKey,
      dTag: nonce,
      listingAnchor: listingAnchor,
      pTags: [
        PTag.seller(auth.activeKeyPair!.publicKey, relayHint: sellerHint),
      ],
      stage: OrderStage.commit,
      start: start,
      end: end,
    );

    await _upsertWithTransition(
      order: order,
      transitionType: OrderTransitionType.commit,
      fromStage: OrderStage.negotiate,
      toStage: OrderStage.commit,
    );
    logger.d('Created blocked order: $order');
    return order;
  }

  /// Subscribes to all orders for [listing] and emits only those whose
  /// tradeId has NOT been cancelled.
  ///
  /// Events are collected within a [debounce] window; after the window closes
  /// the full buffer is scanned: any tradeId with a [OrderStage.cancel]
  /// entry is dropped in its entirety, and the surviving orders are
  /// emitted as [Valid] items.
  StreamWithStatus<Validation<Order>> subscribeUncancelledOrders({
    required Listing listing,
    Duration debounce = const Duration(milliseconds: 500),
  }) {
    final response = StreamWithStatus<Validation<Order>>();
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

    // tradeId → list of all seen orders for that tradeId.
    final Map<String, List<Order>> buffer = {};
    // tradeIds that have already been emitted (or are cancelled).
    final Set<String> handled = {};
    Timer? timer;

    void flush() {
      for (final entry in buffer.entries) {
        final tradeId = entry.key;
        if (handled.contains(tradeId)) continue;
        final orders = entry.value;
        if (orders.any((r) => r.stage == OrderStage.cancel)) {
          handled.add(tradeId);
          continue;
        }
        final latest = orders.reduce(
          (a, b) => a.createdAt >= b.createdAt ? a : b,
        );
        response.add(Valid(latest));
        handled.add(tradeId);
      }
    }

    response.addSubscription(
      raw.replayStream.listen((order) {
        final tradeId = order.getDtag() ?? order.id;
        buffer.putIfAbsent(tradeId, () => []).add(order);
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
  /// stream so [subscribeToMyOrders] creates a fresh one on next
  /// login.
  Future<void> reset() async {
    await _myOrdersSubscription?.cancel();
    _myOrdersSubscription = null;
    _myOrders = null;
  }

  /// Permanent teardown — closes the stream. Only call when the Hostr
  /// instance itself is being disposed.
  Future<void> dispose() async {
    await _myOrders?.close();
    _myOrders = null;
    await _myOrdersSubscription?.cancel();
    _myOrdersSubscription = null;
  }

  @override
  StreamWithStatus<Validation<Order>> queryVerified({
    Filter? filter,
    Duration debounce = const Duration(milliseconds: 50),
    bool closeSourceOnClose = true,
    String? name,
  }) {
    // TODO: implement queryVerified
    throw UnimplementedError();
  }

  @override
  Future<OrderDeps> resolve(Order item) async {
    return OrderDeps(
      listing: await listings.getOneByAnchor(item.parsedTags.listingAnchor),
    );
  }

  @override
  StreamWithStatus<Validation<Order>> subscribeVerified({
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
  Validation<Order> verify(Order item, OrderDeps deps) {
    // TODO: implement verify
    throw UnimplementedError();
  }
}
