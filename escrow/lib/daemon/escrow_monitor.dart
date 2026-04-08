import 'dart:async';

import 'package:escrow/shared/protocol.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;
import 'package:rxdart/rxdart.dart';

/// Status of a tracked escrow trade.
enum TradeStatus { funded, arbitrated, released, claimed, unknown }

/// In-memory snapshot of a trade derived from on-chain events.
class TradeSnapshot {
  final String tradeId;
  final TradeStatus status;
  final int amountSats;
  final String? lastTxHash;
  final DateTime updatedAt;

  TradeSnapshot({
    required this.tradeId,
    required this.status,
    required this.amountSats,
    this.lastTxHash,
    required this.updatedAt,
  });

  TradeSnapshot copyWith({
    TradeStatus? status,
    int? amountSats,
    String? lastTxHash,
    DateTime? updatedAt,
  }) =>
      TradeSnapshot(
        tradeId: tradeId,
        status: status ?? this.status,
        amountSats: amountSats ?? this.amountSats,
        lastTxHash: lastTxHash ?? this.lastTxHash,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  TradeSummary toSummary() => TradeSummary(
        tradeId: tradeId,
        status: status.name,
        amountSats: amountSats,
        txHash: lastTxHash,
        updatedAt: updatedAt,
      );
}

/// Long-running monitor that subscribes to:
///   1. On-chain escrow contract events (fund, arbitrate, release, claim).
///   2. Nostr thread messages.
///   3. Reservation events that p-tag or are authored by this escrow. For
///      each [ReservationGroup] where the escrow has not yet published a
///      status, force-validates the buyer's escrow proof and broadcasts a
///      commit (valid) or cancel (invalid) reservation.
///
/// Maintains an in-memory map of all known trades so the CLI can read state
/// instantly without re-querying the chain.
class EscrowMonitor {
  final Hostr hostr;
  final SupportedEscrowContract contract;
  final EscrowService escrowService;

  final Map<String, TradeSnapshot> _trades = {};
  final _tradesSubject = BehaviorSubject<Map<String, TradeSnapshot>>.seeded({});

  StreamSubscription? _eventSub;
  StreamSubscription? _threadSub;

  // ── Reservation auto-confirmation state ──────────────────────────────────
  late final EscrowVerification _escrowVerification;
  final Map<String, ReservationGroup> _reservationGroups = {};
  StreamSubscription? _reservationPTagSub;
  StreamSubscription? _reservationAuthorSub;
  Timer? _reservationDebounce;

  EscrowMonitor({
    required this.hostr,
    required this.contract,
    required this.escrowService,
  }) {
    _escrowVerification = EscrowVerification(
      evm: hostr.evm,
      logger: CustomLogger(),
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Start listening to contract events, Nostr threads, and reservations.
  void start() {
    _startContractListener();
    _startThreadListener();
    _startReservationListener();
    print('[monitor] Escrow monitor started');
  }

  /// Stop all subscriptions.
  Future<void> stop() async {
    await _eventSub?.cancel();
    await _threadSub?.cancel();
    await _reservationPTagSub?.cancel();
    await _reservationAuthorSub?.cancel();
    _reservationDebounce?.cancel();
    _tradesSubject.close();
  }

  /// All tracked trades.
  Map<String, TradeSnapshot> get trades => Map.unmodifiable(_trades);

  /// Stream that emits whenever the trade map changes.
  ValueStream<Map<String, TradeSnapshot>> get trades$ => _tradesSubject.stream;

  /// Only pending (funded, unresolved) trades.
  List<TradeSnapshot> get pendingTrades =>
      _trades.values.where((t) => t.status == TradeStatus.funded).toList();

  /// Lookup a single trade.
  TradeSnapshot? getTrade(String tradeId) => _trades[tradeId];

  /// All reservation groups the escrow is involved in.
  Map<String, ReservationGroup> get reservationGroups =>
      Map.unmodifiable(_reservationGroups);

  // ── Contract events ───────────────────────────────────────────────────────

  void _startContractListener() {
    hostr.auth.hd.getActiveEvmKey().then((evmKey) {
      final streamer = contract.allEvents(
        ContractEventsParams(
          arbiterEvmAddress: evmKey.address,
        ),
        null,
      );

      streamer.status.listen((status) {
        if (status is StreamStatusError) {
          print('[monitor] Contract event stream error: ${status.error}');
          print('[monitor] ${status.stackTrace}');
        } else {
          print('[monitor] Contract event stream status: '
              '${status.runtimeType}');
        }
      });

      _eventSub = streamer.stream.listen(
        _onEscrowEvent,
        onError: (e, st) => print('[monitor] Contract event error: $e'),
      );
    });
  }

  void _onEscrowEvent(EscrowEvent event) {
    if (event is EscrowFundedEvent) {
      print('[monitor] Trade funded: ${event.tradeId}  '
          '${event.amount.getInSats} sats');
      _trades[event.tradeId] = TradeSnapshot(
        tradeId: event.tradeId,
        status: TradeStatus.funded,
        amountSats: event.amount.getInSats.toInt(),
        lastTxHash: event.transactionHash,
        updatedAt: event.block.timestamp,
      );
    } else if (event is EscrowArbitratedEvent) {
      print('[monitor] Trade arbitrated: ${event.tradeId}  '
          'forwarded=${event.forwarded}');
      final existing = _trades[event.tradeId];
      if (existing != null) {
        _trades[event.tradeId] = existing.copyWith(
          status: TradeStatus.arbitrated,
          lastTxHash: event.transactionHash,
          updatedAt: event.block.timestamp,
        );
      }
    } else if (event is EscrowReleasedEvent) {
      print('[monitor] Trade released: ${event.tradeId}');
      final existing = _trades[event.tradeId];
      if (existing != null) {
        _trades[event.tradeId] = existing.copyWith(
          status: TradeStatus.released,
          lastTxHash: event.transactionHash,
          updatedAt: event.block.timestamp,
        );
      }
    } else if (event is EscrowClaimedEvent) {
      print('[monitor] Trade claimed: ${event.tradeId}');
      final existing = _trades[event.tradeId];
      if (existing != null) {
        _trades[event.tradeId] = existing.copyWith(
          status: TradeStatus.claimed,
          lastTxHash: event.transactionHash,
          updatedAt: event.block.timestamp,
        );
      }
    }

    _tradesSubject.add(_trades);
  }

  // ── Nostr thread messages ─────────────────────────────────────────────────

  void _startThreadListener() {
    hostr.userSubscriptions.start();
    _threadSub = hostr.messaging.threads.threadStream.listen(
      (thread) {
        print('[monitor] New/updated thread: ${thread.anchor}');
      },
      onError: (e) => print('[monitor] Thread stream error: $e'),
    );
  }

  // ── Reservation auto-confirmation ─────────────────────────────────────────

  /// Subscribes to reservation events where this escrow is either a p-tagged
  /// participant or the author. Incoming events are accumulated into
  /// [ReservationGroup]s and processed with a debounce.
  void _startReservationListener() {
    final escrowPubkey = hostr.auth.activeKeyPair!.publicKey;

    // 1. Reservations that p-tag the escrow (buyer's self-signed commits).
    final pTagStream = hostr.reservations.subscribe(
      Filter(pTags: [escrowPubkey]),
    );
    _reservationPTagSub = pTagStream.stream.listen(
      _onReservation,
      onError: (e) => print('[monitor] Reservation p-tag stream error: $e'),
    );

    // 2. Reservations authored by the escrow (our own past confirmations/
    //    cancellations). Needed so group.escrowReservation is populated and
    //    we skip groups we've already handled — the relay is our persistence.
    final authorStream = hostr.reservations.subscribe(
      Filter(authors: [escrowPubkey]),
    );
    _reservationAuthorSub = authorStream.stream.listen(
      _onReservation,
      onError: (e) => print('[monitor] Reservation author stream error: $e'),
    );

    print('[monitor] Reservation listener started for $escrowPubkey');
  }

  /// Accumulates a reservation into its [ReservationGroup] and schedules
  /// a debounced processing pass.
  void _onReservation(Reservation reservation) {
    final groupId = ReservationGroup.groupIdFromEvent(reservation);
    final existing = _reservationGroups[groupId] ?? const ReservationGroup();
    _reservationGroups[groupId] = existing.addReservation(reservation);

    print('[monitor] Reservation received: '
        'trade=${reservation.getDtag()} '
        'pubkey=${reservation.pubKey.substring(0, 8)}… '
        'stage=${reservation.stage.name}');

    // Debounce so rapid bursts (e.g. historical catch-up) are batched.
    _reservationDebounce?.cancel();
    _reservationDebounce = Timer(
      const Duration(milliseconds: 500),
      _processAllGroups,
    );
  }

  /// Iterates every accumulated group and processes those that need action.
  void _processAllGroups() {
    for (final entry in _reservationGroups.entries) {
      _processGroup(entry.value);
    }
  }

  /// For a single [ReservationGroup]:
  ///   - Skips if the escrow has already published (commit or cancel).
  ///   - Skips if there is no buyer commit with an escrow proof.
  ///   - Force-validates the buyer's escrow proof on-chain.
  ///   - Broadcasts a commit (valid) or cancel (invalid) reservation.
  Future<void> _processGroup(ReservationGroup group) async {
    // Already handled — our own reservation is in the group (from the relay).
    if (group.escrowReservation != null) return;

    final buyer = group.buyerReservation;
    if (buyer == null) return;
    if (buyer.stage != ReservationStage.commit) return;
    if (buyer.proof?.escrowProof == null) return;

    final tradeId = group.tradeId;
    print('[monitor] Processing reservation group: trade=$tradeId');

    try {
      final result = await ReservationGroups.verifyGroupOnChain(
        group,
        forceValidateSelfSigned: true,
        escrowVerification: _escrowVerification,
      );

      if (result is Valid<ReservationGroup>) {
        await _publishEscrowConfirmation(group, buyer);
      } else if (result is Invalid<ReservationGroup>) {
        final reason = result.reason;
        print('[monitor] Escrow proof INVALID for trade=$tradeId: $reason');
        await _publishEscrowCancellation(group, buyer);
      }
    } catch (e, st) {
      print('[monitor] Error processing group trade=$tradeId: $e');
      print('[monitor] $st');
    }
  }

  /// Broadcasts a commit reservation from the escrow, confirming the buyer's
  /// self-signed proof is valid.
  Future<void> _publishEscrowConfirmation(
    ReservationGroup group,
    Reservation buyer,
  ) async {
    final keyPair = hostr.auth.activeKeyPair!;

    final reservation = Reservation.create(
      pubKey: keyPair.publicKey,
      dTag: group.tradeId,
      listingAnchor: group.listingAnchor,
      pTags: [group.hostPubkey, buyer.pubKey],
      start: buyer.start,
      end: buyer.end,
      stage: ReservationStage.commit,
      quantity: buyer.quantity,
      amount: buyer.amount,
      recipient: buyer.recipient,
    ).signAs(keyPair, Reservation.fromNostrEvent);

    await hostr.reservations.upsert(reservation);

    // Update local group so we don't re-process.
    final groupId = ReservationGroup.groupIdFromEvent(reservation);
    _reservationGroups[groupId] =
        (_reservationGroups[groupId] ?? group).addReservation(reservation);

    print('[monitor] ✓ Published escrow COMMIT for trade=${group.tradeId}');
  }

  /// Broadcasts a cancel reservation from the escrow, indicating the buyer's
  /// self-signed proof failed validation.
  Future<void> _publishEscrowCancellation(
    ReservationGroup group,
    Reservation buyer,
  ) async {
    final keyPair = hostr.auth.activeKeyPair!;

    final reservation = Reservation.create(
      pubKey: keyPair.publicKey,
      dTag: group.tradeId,
      listingAnchor: group.listingAnchor,
      pTags: [group.hostPubkey, buyer.pubKey],
      start: buyer.start,
      end: buyer.end,
      stage: ReservationStage.cancel,
      quantity: buyer.quantity,
      amount: buyer.amount,
      recipient: buyer.recipient,
    ).signAs(keyPair, Reservation.fromNostrEvent);

    await hostr.reservations.upsert(reservation);

    // Update local group so we don't re-process.
    final groupId = ReservationGroup.groupIdFromEvent(reservation);
    _reservationGroups[groupId] =
        (_reservationGroups[groupId] ?? group).addReservation(reservation);

    print('[monitor] ✗ Published escrow CANCEL for trade=${group.tradeId}');
  }
}
