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
        maxDuration: config.maxDuration,
        type: EscrowType.EVM,
        feePercent: config.feePercent,
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

  // ── Public API ────────────────────────────────────────────────────────────

  /// Start listening to contract events, Nostr threads, and reservations.
  ///
  /// Must be called after [bootstrap].
  void start() {
    _startContractListener();
    _startThreadListener();
    _startReservationListener();
    _logger.i('Escrow monitor started');
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

  /// All tracked trades (unmodifiable).
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
    _hostr.auth.hd.getActiveEvmKey().then((evmKey) {
      final streamer = context.contract.allEvents(
        ContractEventsParams(arbiterEvmAddress: evmKey.address),
        null,
      );

      streamer.status.listen((status) {
        if (status is StreamStatusError) {
          _logger.e('Contract event stream error: ${status.error}');
        } else {
          _logger.d('Contract event stream status: ${status.runtimeType}');
        }
      });

      _eventSub = streamer.stream.listen(
        _onEscrowEvent,
        onError: (e, st) => _logger.e('Contract event error: $e'),
      );
    });
  }

  void _onEscrowEvent(EscrowEvent event) {
    if (event is EscrowFundedEvent) {
      _logger.i(
        'Trade funded: ${event.tradeId}  '
        '${event.amount.getInSats} sats',
      );
      _trades[event.tradeId] = TradeSnapshot(
        tradeId: event.tradeId,
        status: TradeStatus.funded,
        amountSats: event.amount.getInSats.toInt(),
        lastTxHash: event.transactionHash,
        updatedAt: event.block.timestamp,
      );
    } else if (event is EscrowArbitratedEvent) {
      _logger.i(
        'Trade arbitrated: ${event.tradeId}  '
        'forwarded=${event.forwarded}',
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

  void _startThreadListener() {
    _hostr.userSubscriptions.start();
    _threadSub = _hostr.messaging.threads.threadStream.listen((thread) {
      _logger.d('New/updated thread: ${thread.anchor}');
    }, onError: (e) => _logger.e('Thread stream error: $e'));
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

    await _hostr.reservations.upsert(reservation);

    // Update local group so we don't re-process.
    final groupId = ReservationGroup.groupIdFromEvent(reservation);
    _reservationGroups[groupId] = (_reservationGroups[groupId] ?? group)
        .addReservation(reservation);

    _logger.i('✓ Published escrow COMMIT for trade=${group.tradeId}');
  }

  Future<void> _publishEscrowCancellation(
    ReservationGroup group,
    Reservation buyer,
  ) async {
    final keyPair = _hostr.auth.activeKeyPair!;

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

    await _hostr.reservations.upsert(reservation);

    // Update local group so we don't re-process.
    final groupId = ReservationGroup.groupIdFromEvent(reservation);
    _reservationGroups[groupId] = (_reservationGroups[groupId] ?? group)
        .addReservation(reservation);

    _logger.i('✗ Published escrow CANCEL for trade=${group.tradeId}');
  }
}
