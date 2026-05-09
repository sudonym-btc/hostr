import 'dart:async';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Ndk;

import '../../util/main.dart';
import '../auth/auth.dart';
import '../reservation_groups/reservation_group_participant_resolver.dart';
import '../reservations/reservation_participant_keyring.dart';
import '../reservations/reservations.dart';
import '../trade_account_allocator/trade_account_allocator.dart';
import '../user_subscriptions/user_subscriptions.dart';
import 'thread.dart';
import 'threads.dart';

class EscrowTradeThreadPlan {
  const EscrowTradeThreadPlan({
    required this.thread,
    required this.participantPubkeys,
    required this.recipientPubkeys,
    required this.rolePubkeys,
  });

  final Thread thread;
  final List<String> participantPubkeys;
  final List<String> recipientPubkeys;
  final Map<String, String> rolePubkeys;
}

class EscrowTradeThreadResolver {
  EscrowTradeThreadResolver({
    required Auth auth,
    required Reservations reservations,
    required UserSubscriptions userSubscriptions,
    required Threads threads,
    required TradeAccountAllocator tradeAccountAllocator,
    Ndk? ndk,
    required CustomLogger logger,
  }) : _auth = auth,
       _reservations = reservations,
       _userSubscriptions = userSubscriptions,
       _threads = threads,
       _tradeAccountAllocator = tradeAccountAllocator,
       _ndk = ndk,
       _logger = logger.scope('escrow-trade-thread-resolver');

  final Auth _auth;
  final Reservations _reservations;
  final UserSubscriptions _userSubscriptions;
  final Threads _threads;
  final TradeAccountAllocator _tradeAccountAllocator;
  final Ndk? _ndk;
  final CustomLogger _logger;

  Future<EscrowTradeThreadPlan> resolve({
    required String tradeId,
    Thread? tradeThread,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final normalizedTradeId = tradeId.trim();
    if (normalizedTradeId.isEmpty) {
      throw StateError(
        'Messaging escrow requires a concrete reservation tradeId',
      );
    }

    final activePubkey = _auth.getActiveKey().publicKey;
    final resolvedItem = await _resolvedReservationGroupForTradeId(
      normalizedTradeId,
      timeout: timeout,
    );
    var resolvedParticipants = resolvedItem?.participants;
    var group = resolvedItem?.group;
    if (resolvedParticipants == null || group == null) {
      final reservations = await _reservations.getByTradeId(normalizedTradeId);
      if (reservations.isNotEmpty) {
        group ??= ReservationGroup(reservations: reservations);
        resolvedParticipants ??= await ReservationGroupParticipantResolver(
          keyring: DefaultReservationParticipantKeyring(
            auth: _auth,
            tradeAccountAllocator: _tradeAccountAllocator,
            ndk: _ndk,
            logger: _logger,
          ),
        ).resolve(group);
      }
    }
    final state = tradeThread?.state.value;

    String? rawSellerPubkey =
        resolvedParticipants?.rawParticipantPubkeyForRole('seller') ??
        group?.sellerPubkey;
    String? rawBuyerPubkey =
        resolvedParticipants?.rawParticipantPubkeyForRole('buyer') ??
        group?.buyerPubkey;
    String? rawEscrowPubkey =
        resolvedParticipants?.rawParticipantPubkeyForRole('escrow') ??
        group?.escrowPubkey ??
        state?.selectedEscrows.lastOrNull?.service.escrowPubkey;

    final seenParticipants = <String>{
      activePubkey,
      if (state != null) ...state.participantPubkeys,
      if (state != null) ...state.counterpartyPubkeys,
    };

    for (final request
        in state?.reservationRequests.reversed ?? const <Reservation>[]) {
      seenParticipants.add(request.pubKey);
      seenParticipants.addAll(request.parsedTags.getTags('p'));
      final anchor = request.parsedTags.listingAnchor;
      if ((rawSellerPubkey == null || rawSellerPubkey.isEmpty) &&
          anchor.isNotEmpty) {
        rawSellerPubkey = getPubKeyFromAnchor(anchor);
      }
      rawBuyerPubkey ??= request.parsedTags.getTagValueByMarker('p', 'buyer');
      rawEscrowPubkey ??= request.parsedTags.getTagValueByMarker('p', 'escrow');
    }

    if ((rawSellerPubkey == null || rawSellerPubkey.isEmpty) && state != null) {
      rawSellerPubkey = _pubkeyForThreadRole(
        role: 'seller',
        group: group,
        state: state,
      );
    }
    if ((rawEscrowPubkey == null || rawEscrowPubkey.isEmpty) && state != null) {
      rawEscrowPubkey = _pubkeyForThreadRole(
        role: 'escrow',
        group: group,
        state: state,
      );
    }

    if (rawBuyerPubkey == null || rawBuyerPubkey.isEmpty) {
      final candidates = seenParticipants
          .where(
            (pubkey) =>
                pubkey.isNotEmpty &&
                pubkey != rawSellerPubkey &&
                pubkey != rawEscrowPubkey,
          )
          .toSet();
      if (activePubkey != rawSellerPubkey && activePubkey != rawEscrowPubkey) {
        rawBuyerPubkey = activePubkey;
      } else if (candidates.length == 1) {
        rawBuyerPubkey = candidates.single;
      }
    }

    final sellerPubkey = await _chatPubkeyForReservationParticipant(
      activePubkey: activePubkey,
      tradeId: normalizedTradeId,
      participants: resolvedParticipants,
      rawPubkey: rawSellerPubkey,
    );
    final buyerPubkey = await _chatPubkeyForReservationParticipant(
      activePubkey: activePubkey,
      tradeId: normalizedTradeId,
      participants: resolvedParticipants,
      rawPubkey: rawBuyerPubkey,
    );
    final escrowPubkey = await _chatPubkeyForReservationParticipant(
      activePubkey: activePubkey,
      tradeId: normalizedTradeId,
      participants: resolvedParticipants,
      rawPubkey: rawEscrowPubkey,
    );

    final missingRoles = <String>[
      if (sellerPubkey == null || sellerPubkey.isEmpty) 'seller',
      if (buyerPubkey == null || buyerPubkey.isEmpty) 'buyer',
      if (escrowPubkey == null || escrowPubkey.isEmpty) 'escrow',
    ];
    if (missingRoles.isNotEmpty) {
      throw StateError(
        'Cannot message escrow until the tradeId resolves to seller, buyer, '
        'and escrow participants: ${missingRoles.join(', ')}',
      );
    }

    final rolePubkeys = <String, String>{
      'seller': sellerPubkey!,
      'buyer': buyerPubkey!,
      'escrow': escrowPubkey!,
    };
    final participantPubkeys = rolePubkeys.values.toSet();
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
    thread.configureConversation(
      conversationTag: normalizedTradeId,
      participants: participantPubkeys,
    );

    return EscrowTradeThreadPlan(
      thread: thread,
      participantPubkeys: participantPubkeys.toList()..sort(),
      recipientPubkeys:
          participantPubkeys.where((pubkey) => pubkey != activePubkey).toList()
            ..sort(),
      rolePubkeys: rolePubkeys,
    );
  }

  String? _pubkeyForThreadRole({
    required String role,
    required ReservationGroup? group,
    required ThreadState state,
  }) {
    final selected = state.selectedEscrows.lastOrNull;
    final selectedEscrow = selected?.service.escrowPubkey;
    return switch (role) {
      'seller' || 'host' => group?.sellerPubkey,
      'guest' || 'buyer' => group?.buyerPubkey,
      'escrow' => group?.escrowPubkey ?? selectedEscrow,
      _ => null,
    };
  }

  Future<String?> _chatPubkeyForReservationParticipant({
    required String activePubkey,
    required String tradeId,
    required ResolvedReservationGroupParticipants? participants,
    required String? rawPubkey,
  }) async {
    if (rawPubkey == null || rawPubkey.isEmpty) return null;
    return _resolvedIdentityForRawParticipant(participants, rawPubkey) ??
        (await _activeControlsReservationPubkey(
              activePubkey: activePubkey,
              tradeId: tradeId,
              pubkey: rawPubkey,
            )
            ? activePubkey
            : rawPubkey);
  }

  String? _resolvedIdentityForRawParticipant(
    ResolvedReservationGroupParticipants? participants,
    String? rawPubkey,
  ) {
    if (rawPubkey == null || rawPubkey.isEmpty) return null;
    return participants?.identityByParticipantPubkey[rawPubkey];
  }

  Future<bool> _activeControlsReservationPubkey({
    required String activePubkey,
    required String tradeId,
    required String pubkey,
  }) async {
    if (pubkey.isEmpty) return false;
    if (pubkey == activePubkey) return true;

    try {
      final accountIndex = await _tradeAccountAllocator
          .tryFindTradeAccountIndexByTradeId(tradeId);
      if (accountIndex == null) return false;
      final tradeKey = await _auth.hd.getTradeKeyPair(
        accountIndex: accountIndex,
      );
      return tradeKey.publicKey == pubkey;
    } catch (error, stackTrace) {
      _logger.w(
        'Failed to resolve active trade key for $tradeId',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<ResolvedValidatedReservationGroupParticipants?>
  _resolvedReservationGroupForTradeId(
    String tradeId, {
    required Duration timeout,
  }) async {
    final snapshots = await Future.wait([
      _resolvedReservationGroupSnapshot(
        _userSubscriptions.myResolvedTripsList$,
        timeout: timeout,
      ),
      _resolvedReservationGroupSnapshot(
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

  Future<List<ResolvedValidatedReservationGroupParticipants>>
  _resolvedReservationGroupSnapshot(
    StreamWithStatus<List<ResolvedValidatedReservationGroupParticipants>>
    source, {
    required Duration timeout,
  }) async {
    if (source.items.isNotEmpty || timeout <= Duration.zero) {
      return source.items.isEmpty ? const [] : source.items.last;
    }

    final completer =
        Completer<List<ResolvedValidatedReservationGroupParticipants>>();
    Timer? timer;
    StreamSubscription<List<ResolvedValidatedReservationGroupParticipants>>?
    itemSubscription;
    StreamSubscription<StreamStatus>? statusSubscription;

    List<ResolvedValidatedReservationGroupParticipants> latest() =>
        source.items.isEmpty ? const [] : source.items.last;

    void complete([
      List<ResolvedValidatedReservationGroupParticipants>? items,
    ]) {
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
