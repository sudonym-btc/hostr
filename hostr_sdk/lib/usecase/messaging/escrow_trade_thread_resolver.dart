import 'dart:async';

import 'package:models/main.dart';

import '../../util/main.dart';
import '../auth/auth.dart';
import '../order_groups/order_group_participant_resolver.dart';
import '../orders/order_participant_keyring.dart';
import '../orders/orders.dart';
import '../trade_account_allocator/trade_account_allocator.dart';
import '../user_subscriptions/user_subscriptions.dart';
import 'thread.dart';
import 'threads.dart';

class EscrowTradeThreadResolver {
  EscrowTradeThreadResolver({
    required Auth auth,
    required Orders orders,
    required UserSubscriptions userSubscriptions,
    required Threads threads,
    required TradeAccountAllocator tradeAccountAllocator,
    required CustomLogger logger,
  }) : _auth = auth,
       _orders = orders,
       _userSubscriptions = userSubscriptions,
       _threads = threads,
       _tradeAccountAllocator = tradeAccountAllocator,
       _logger = logger.scope('escrow-trade-thread-resolver');

  final Auth _auth;
  final Orders _orders;
  final UserSubscriptions _userSubscriptions;
  final Threads _threads;
  final TradeAccountAllocator _tradeAccountAllocator;
  final CustomLogger _logger;

  Future<Thread> resolve({
    required String tradeId,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final normalizedTradeId = tradeId.trim();
    if (normalizedTradeId.isEmpty) {
      throw StateError('Messaging escrow requires a concrete order tradeId');
    }

    final activePubkey = _auth.getActiveKey().publicKey;
    var resolvedParticipants = (await _resolvedOrderGroupForTradeId(
      normalizedTradeId,
      timeout: timeout,
    ))?.participants;
    if (resolvedParticipants == null) {
      final orders = await _orders.getByTradeId(normalizedTradeId);
      if (orders.isNotEmpty) {
        resolvedParticipants = await OrderGroupParticipantResolver(
          keyring: DefaultOrderParticipantKeyring(
            auth: _auth,
            tradeAccountAllocator: _tradeAccountAllocator,
            logger: _logger,
          ),
        ).resolve(OrderGroup(orders: orders));
      }
    }
    if (resolvedParticipants == null) {
      throw StateError(
        'Cannot message escrow until the tradeId resolves to a order group',
      );
    }

    final missingRoles = <String>[
      if (!resolvedParticipants.hasResolvedParticipantForRole(
        'seller',
        requireResolvedProof: true,
      ))
        'seller',
      if (!resolvedParticipants.hasResolvedParticipantForRole(
        'buyer',
        requireResolvedProof: true,
      ))
        'buyer',
      if (!resolvedParticipants.hasResolvedParticipantForRole(
        'escrow',
        requireResolvedProof: true,
      ))
        'escrow',
    ];
    if (missingRoles.isNotEmpty) {
      throw StateError(
        'Cannot message escrow until the tradeId resolves to seller, buyer, '
        'and escrow participants: ${missingRoles.join(', ')}',
      );
    }

    final participantPubkeys = resolvedParticipants.resolvedParticipantSet;
    if (!participantPubkeys.contains(activePubkey)) {
      throw StateError(
        'Cannot message escrow for a trade unless the active user is the '
        'buyer, seller, escrow participant, or controls a trade participant key',
      );
    }

    final thread = _threads.ensureTradeConversation(
      tradeId: normalizedTradeId,
      participants: participantPubkeys,
    );
    return thread;
  }

  Future<ResolvedValidatedOrderGroupParticipants?>
  _resolvedOrderGroupForTradeId(
    String tradeId, {
    required Duration timeout,
  }) async {
    final snapshots = await Future.wait([
      _resolvedOrderGroupSnapshot(
        _userSubscriptions.myResolvedTripsList$,
        timeout: timeout,
      ),
      _resolvedOrderGroupSnapshot(
        _userSubscriptions.myResolvedHostingsList$,
        timeout: timeout,
      ),
    ]);
    final matches = snapshots
        .expand((items) => items)
        .where((item) => item.group.tradeId == tradeId)
        .toList();
    if (matches.isEmpty) return null;
    final valid = matches.where((item) => item.validation is Valid).toList();
    return valid.isNotEmpty ? valid.last : matches.last;
  }

  Future<List<ResolvedValidatedOrderGroupParticipants>>
  _resolvedOrderGroupSnapshot(
    StreamWithStatus<List<ResolvedValidatedOrderGroupParticipants>> source, {
    required Duration timeout,
  }) async {
    if (source.items.isNotEmpty || timeout <= Duration.zero) {
      return source.items.isEmpty ? const [] : source.items.last;
    }

    final completer =
        Completer<List<ResolvedValidatedOrderGroupParticipants>>();
    Timer? timer;
    StreamSubscription<List<ResolvedValidatedOrderGroupParticipants>>?
    itemSubscription;
    StreamSubscription<StreamStatus>? statusSubscription;

    List<ResolvedValidatedOrderGroupParticipants> latest() =>
        source.items.isEmpty ? const [] : source.items.last;

    void complete([List<ResolvedValidatedOrderGroupParticipants>? items]) {
      if (!completer.isCompleted) {
        completer.complete(items ?? latest());
      }
    }

    itemSubscription = source.stream.listen(
      complete,
      onError: (_) => complete(),
    );
    statusSubscription = source.status.listen((status) {
      if (status is StreamStatusQueryComplete || status is StreamStatusLive) {
        complete();
      }
      if (status is StreamStatusError) {
        complete();
      }
    });
    timer = Timer(timeout, complete);

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      await itemSubscription.cancel();
      await statusSubscription.cancel();
    }
  }
}
