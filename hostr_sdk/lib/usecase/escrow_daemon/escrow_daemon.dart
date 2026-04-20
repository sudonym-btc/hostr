import 'dart:async';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../../hostr.dart';
import '../../util/main.dart';
import '../escrow/escrow_verification.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract_registry.dart';
import '../reservation_groups/reservation_groups.dart';
import 'escrow_daemon_models.dart';

/// Use case that encapsulates all escrow-daemon business logic:
///
///   1. **Bootstrap** — build the [EscrowService] descriptor, verify the
///      contract is deployed, and publish to the relay.
///   2. **Monitor** — subscribe to on-chain contract events, Nostr thread
///      messages, and reservation events; auto-confirm or cancel buyer
///      self-signed reservations.
///
/// This is a long-lived object. Create it with a [Hostr] that is already
/// authenticated (`hostr.auth.signin(…)` / `hostr.auth.init()` completed).
///
/// ```dart
/// final daemon = EscrowDaemon(hostr: hostr);
/// final ctx = await daemon.bootstrap(config);
/// daemon.start();
/// // … later …
/// await daemon.stop();
/// ```
class EscrowDaemon {
  final Hostr _hostr;
  final CustomLogger _logger;

  EscrowDaemonContext? _context;

  // ── Trade state ─────────────────────────────────────────────────────────
  final Map<String, TradeSnapshot> _trades = {};
  final _tradesSubject = BehaviorSubject<Map<String, TradeSnapshot>>.seeded({});

  // ── Reservation auto-confirmation state ─────────────────────────────────
  late final EscrowVerification _escrowVerification;
  final Map<String, ReservationGroup> _reservationGroups = {};

  // ── Subscriptions ───────────────────────────────────────────────────────
  StreamSubscription? _eventSub;
  final Map<String, StreamSubscription> _tradeEventSubs = {};
  StreamSubscription? _threadSub;
  StreamSubscription? _reservationPTagSub;
  StreamSubscription? _reservationAuthorSub;
  Timer? _reservationDebounce;

  EscrowDaemon({required Hostr hostr})
    : _hostr = hostr,
      _logger = hostr.logger.scope('escrow-daemon') {
    _escrowVerification = EscrowVerification(evm: hostr.evm, logger: _logger);
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  /// The underlying [Hostr] instance.
  Hostr get hostr => _hostr;

  /// The daemon context created by [bootstrap]. Throws if not bootstrapped.
  EscrowDaemonContext get context {
    if (_context == null) {
      throw StateError(
        'EscrowDaemon has not been bootstrapped yet. '
        'Call bootstrap() first.',
      );
    }
    return _context!;
  }

  /// Whether [bootstrap] has been called successfully.
  bool get isBootstrapped => _context != null;

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  /// Builds the [EscrowService], verifies the contract is deployed, and
  /// publishes the service to the relay.
  ///
  /// The [Hostr] must already be authenticated before calling this.
  Future<EscrowDaemonContext> bootstrap(EscrowDaemonConfig config) async {
    _logger.i('Bootstrapping escrow daemon…');

    final chain = _hostr.evm.configuredChains[config.chainIndex];
    final contractAddress = chain.config.escrowContractAddress!;
    final pubKey = _hostr.auth.activeKeyPair!.publicKey;
    final evmKey = await _hostr.auth.hd.getActiveEvmKey();
    final existingService = await _findExistingService(
      pubKey: pubKey,
      contractAddress: contractAddress,
    );

    final escrowService = EscrowService(
      pubKey: pubKey,
      tags: EventTags([
        ['d', contractAddress],
      ]),
      content: EscrowServiceContent(
        pubkey: pubKey,
        evmAddress: evmKey.address.eip55With0x,
        contractAddress: contractAddress,
        contractBytecodeHash:
            await SupportedEscrowContractRegistry.bytecodeHashForAddress(
              chain.client,
              EthereumAddress.fromHex(contractAddress),
            ),
        chainId: chain.config.chainId,
        maxDuration: existingService?.maxDuration ?? config.maxDuration,
        type: EscrowType.EVM,
        feePercent: existingService?.feePercent ?? config.feePercent,
        tokenFeeHints: existingService?.tokenFeeHints ?? const {},
      ),
    );

    final configuredChain = _hostr.evm.getChainForEscrowService(escrowService);
    final contract = configuredChain.escrow.getSupportedEscrowContract(
      escrowService,
    );

    await contract.ensureDeployed();
    await _hostr.escrows.upsert(escrowService);

    _logger.i('Escrow service published: ${escrowService.content}');

    _context = EscrowDaemonContext(
      escrowService: escrowService,
      contract: contract,
      configuredChain: configuredChain,
      web3client: configuredChain.client,
    );

    return _context!;
  }

  Future<EscrowService?> _findExistingService({
    required String pubKey,
    required String contractAddress,
  }) async {
    final services = await _hostr.escrows.list(
      Filter(kinds: EscrowService.kinds, authors: [pubKey]),
    );
    final matches =
        services
            .where(
              (service) =>
                  service.contractAddress.toLowerCase() ==
                  contractAddress.toLowerCase(),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (matches.isEmpty) return null;
    return matches.first;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Start listening to contract events, Nostr threads, and reservations.
  ///
  /// Must be called after [bootstrap]. Awaits the initial thread query so
  /// that conversations are available immediately after this returns.
  Future<void> start() async {
    _startContractListener();
    await _startThreadListener();
    _startReservationListener();
    _logger.i('Escrow monitor started');
  }

  /// Stop all subscriptions.
  Future<void> stop() async {
    await _eventSub?.cancel();
    for (final sub in _tradeEventSubs.values) {
      await sub.cancel();
    }
    _tradeEventSubs.clear();
    await _threadSub?.cancel();
    await _reservationPTagSub?.cancel();
    await _reservationAuthorSub?.cancel();
    _reservationDebounce?.cancel();
    _tradesSubject.close();
  }

  /// All tracked trades (unmodifiable).
  Map<String, TradeSnapshot> get trades => Map.unmodifiable(_trades);

  /// Stream that emits whenever the trade map changes.
  ValueStream<Map<String, TradeSnapshot>> get trades$ => _tradesSubject.stream;

  /// Only pending (funded, unresolved) trades.
  List<TradeSnapshot> get pendingTrades =>
      _trades.values.where((t) => t.status == TradeStatus.funded).toList();

  /// Lookup a single trade.
  TradeSnapshot? getTrade(String tradeId) => _trades[tradeId];

  /// Eagerly update (or insert) a trade snapshot and notify listeners.
  ///
  /// Used after the daemon itself sends a transaction (e.g. arbitrate) so the
  /// CLI sees the updated status immediately, without waiting for the event
  /// stream to deliver the on-chain log.
  void updateTrade(TradeSnapshot snapshot) {
    _trades[snapshot.tradeId] = snapshot;
    _tradesSubject.add(_trades);
  }

  /// All reservation groups the escrow is involved in.
  Map<String, ReservationGroup> get reservationGroups =>
      Map.unmodifiable(_reservationGroups);

  // ── Contract events ───────────────────────────────────────────────────────

  /// Phase 1: Subscribe to `TradeCreated` events filtered by our arbiter
  /// address. For each discovered trade ID, spin up a per-trade stream
  /// (phase 2) that delivers ALL lifecycle events for that trade.
  void _startContractListener() {
    _hostr.auth.hd.getActiveEvmKey().then((evmKey) {
      final streamer = context.contract.allEvents(
        ContractEventsParams(arbiterEvmAddress: evmKey.address),
        null,
      );

      streamer.status.listen((status) {
        if (status is StreamStatusError) {
          _logger.e('Arbiter event stream error: ${status.error}');
        } else {
          _logger.d('Arbiter event stream status: ${status.runtimeType}');
        }
      });

      _eventSub = streamer.stream.listen((event) {
        if (event is EscrowFundedEvent) {
          _logger.i('Discovered trade: ${event.tradeId}  ${event.amount}');
          _startTradeListener(event.tradeId);
        }
      }, onError: (e, st) => _logger.e('Arbiter event error: $e'));
    });
  }

  /// Phase 2: Subscribe to ALL event types for a single trade.
  ///
  /// The per-trade filter does not restrict by arbiter, so it receives
  /// `TradeCreated`, `Arbitrated`, `ReleasedToCounterparty`, and `Claimed`.
  /// The [EscrowEventScanner] caches per-trade events and short-circuits
  /// from cache once a terminal state is reached.
  void _startTradeListener(String tradeId) {
    if (_tradeEventSubs.containsKey(tradeId)) return; // already listening

    final streamer = context.contract.allEvents(
      ContractEventsParams(tradeId: tradeId),
      null,
    );

    streamer.status.listen((status) {
      if (status is StreamStatusError) {
        _logger.e('Trade $tradeId event stream error: ${status.error}');
      }
    });

    _tradeEventSubs[tradeId] = streamer.stream.listen(
      _onTradeEvent,
      onError: (e, st) => _logger.e('Trade $tradeId event error: $e'),
    );
  }

  void _onTradeEvent(EscrowEvent event) {
    if (event is EscrowFundedEvent) {
      _logger.i('Trade funded: ${event.tradeId}  ${event.amount}');
      _trades[event.tradeId] = TradeSnapshot(
        tradeId: event.tradeId,
        status: TradeStatus.funded,
        amount: event.amount,
        lastTxHash: event.transactionHash,
        updatedAt: event.block.timestamp,
      );
    } else if (event is EscrowArbitratedEvent) {
      _logger.i(
        'Trade arbitrated: ${event.tradeId}  '
        'paymentForwarded=${event.paymentForwarded} '
        'bondForwarded=${event.bondForwarded}',
      );
      final existing = _trades[event.tradeId];
      if (existing != null) {
        _trades[event.tradeId] = existing.copyWith(
          status: TradeStatus.arbitrated,
          lastTxHash: event.transactionHash,
          updatedAt: event.block.timestamp,
        );
      }
    } else if (event is EscrowReleasedEvent) {
      _logger.i('Trade released: ${event.tradeId}');
      final existing = _trades[event.tradeId];
      if (existing != null) {
        _trades[event.tradeId] = existing.copyWith(
          status: TradeStatus.released,
          lastTxHash: event.transactionHash,
          updatedAt: event.block.timestamp,
        );
      }
    } else if (event is EscrowClaimedEvent) {
      _logger.i('Trade claimed: ${event.tradeId}');
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

  Future<void> _startThreadListener() async {
    _logger.i('Starting thread listener…');
    await _hostr.userSubscriptions.start();
    _logger.i('UserSubscriptions started');

    _threadSub = _hostr.messaging.threads.threadStream.listen((thread) {
      _logger.d('New/updated thread: ${thread.anchor}');
    }, onError: (e) => _logger.e('Thread stream error: $e'));

    // Wait for the initial gift-wrap query to complete so threads are
    // populated before the daemon reports ready. Timeout after 30s so
    // a slow relay doesn't block startup indefinitely.
    _logger.i('Waiting for thread query to complete…');
    try {
      await _hostr.messaging.threads.status
          .firstWhere(
            (s) => s is StreamStatusQueryComplete || s is StreamStatusLive,
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      _logger.w(
        'Thread loading timed out after 30s — '
        'continuing with ${_hostr.messaging.threads.threads.length} threads',
      );
    }
    _logger.i(
      'Threads ready: ${_hostr.messaging.threads.threads.length} conversations',
    );
  }

  // ── Reservation auto-confirmation ─────────────────────────────────────────

  void _startReservationListener() {
    final escrowPubkey = _hostr.auth.activeKeyPair!.publicKey;

    // 1. Reservations that p-tag the escrow (buyer's self-signed commits).
    final pTagStream = _hostr.reservations.subscribe(
      Filter(pTags: [escrowPubkey]),
    );
    _reservationPTagSub = pTagStream.stream.listen(
      _onReservation,
      onError: (e) => _logger.e('Reservation p-tag stream error: $e'),
    );

    // 2. Reservations authored by the escrow (our own past confirmations/
    //    cancellations). Needed so group.escrowReservation is populated and
    //    we skip groups we've already handled.
    final authorStream = _hostr.reservations.subscribe(
      Filter(authors: [escrowPubkey]),
    );
    _reservationAuthorSub = authorStream.stream.listen(
      _onReservation,
      onError: (e) => _logger.e('Reservation author stream error: $e'),
    );

    _logger.i('Reservation listener started for $escrowPubkey');
  }

  void _onReservation(Reservation reservation) {
    final groupId = ReservationGroup.groupIdFromEvent(reservation);
    final existing = _reservationGroups[groupId] ?? const ReservationGroup();
    _reservationGroups[groupId] = existing.addReservation(reservation);

    _logger.d(
      'Reservation received: '
      'trade=${reservation.getDtag()} '
      'pubkey=${reservation.pubKey.substring(0, 8)}… '
      'stage=${reservation.stage.name}',
    );

    // Debounce so rapid bursts (e.g. historical catch-up) are batched.
    _reservationDebounce?.cancel();
    _reservationDebounce = Timer(
      const Duration(milliseconds: 500),
      _processAllGroups,
    );
  }

  void _processAllGroups() {
    for (final entry in _reservationGroups.entries) {
      _processGroup(entry.value);
    }
  }

  Future<void> _processGroup(ReservationGroup group) async {
    // Already handled — our own reservation is in the group (from the relay).
    if (group.escrowReservation != null) return;

    final buyer = group.buyerReservation;
    if (buyer == null) return;
    if (buyer.stage != ReservationStage.commit) return;
    if (buyer.proof?.escrowProof == null) return;

    final tradeId = group.tradeId;
    _logger.i('Processing reservation group: trade=$tradeId');

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
        _logger.w('Escrow proof INVALID for trade=$tradeId: $reason');
        await _publishEscrowCancellation(group, buyer);
      }
    } catch (e, st) {
      _logger.e('Error processing group trade=$tradeId: $e');
      _logger.e('$st');
    }
  }

  Future<void> _publishEscrowConfirmation(
    ReservationGroup group,
    Reservation buyer,
  ) async {
    final keyPair = _hostr.auth.activeKeyPair!;

    final reservation = await _hostr.reservations.confirm(group, keyPair);

    // Update local group so we don't re-process.
    final groupId = ReservationGroup.groupIdFromEvent(reservation);
    _reservationGroups[groupId] = (_reservationGroups[groupId] ?? group)
        .addReservation(reservation);

    _logger.i('✓ Published escrow CONFIRM for trade=${group.tradeId}');
  }

  Future<void> _publishEscrowCancellation(
    ReservationGroup group,
    Reservation buyer,
  ) async {
    final keyPair = _hostr.auth.activeKeyPair!;

    final reservation = await _hostr.reservations.cancel(group, keyPair);

    // Update local group so we don't re-process.
    final groupId = ReservationGroup.groupIdFromEvent(reservation);
    _reservationGroups[groupId] = (_reservationGroups[groupId] ?? group)
        .addReservation(reservation);

    _logger.i('✗ Published escrow CANCEL for trade=${group.tradeId}');
  }
}
