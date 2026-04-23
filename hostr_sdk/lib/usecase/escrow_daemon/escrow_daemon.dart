import 'dart:async';
import 'dart:math';

import 'package:meta/meta.dart' show visibleForTesting;
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01Event;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../../config.dart' show CoinlibEventSigner;
import '../../hostr.dart';
import '../../util/main.dart';
import '../escrow/escrow_verification.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract_registry.dart';
import '../reservation_groups/reservation_groups.dart';
import '../reservations/reservation_pubkey_proofs.dart';
import 'escrow_daemon_models.dart';

typedef EscrowReservationNoticeSender =
    Future<void> Function({
      required String content,
      required List<List<String>> tags,
      required List<String> recipientPubkeys,
    });

typedef EscrowReservationLegacyNoticeSender =
    Future<void> Function({
      required String content,
      required List<List<String>> tags,
      required String recipientPubkey,
    });

typedef EscrowReservationExistingMessages =
    Iterable<TextMessage> Function(String tradeId);

const _hostrTradeIdTag = 'tradeId';

class EscrowReservationNotifier {
  final KeyPair Function() escrowKeyPair;
  final DateTime Function() clock;
  final Future<Listing?> Function(String listingAnchor) loadListing;
  final Future<ProfileMetadata?> Function(String pubkey) loadMetadata;
  final EscrowReservationNoticeSender sendText;
  final EscrowReservationLegacyNoticeSender sendLegacyText;
  final EscrowReservationExistingMessages existingMessagesForTrade;
  final CustomLogger _logger;

  EscrowReservationNotifier({
    required this.escrowKeyPair,
    DateTime Function()? clock,
    required this.loadListing,
    required this.loadMetadata,
    required this.sendText,
    required this.sendLegacyText,
    required this.existingMessagesForTrade,
    required CustomLogger logger,
  }) : clock = clock ?? (() => DateTime.now().toUtc()),
       _logger = logger.scope('reservation-notifier');

  Future<void> notifyReservation(ReservationGroup group) async {
    final tradeId = group.tradeId;
    if (_hasEnded(group)) {
      _logger.d('Skipping reservation notice for $tradeId: reservation ended');
      return;
    }

    final buyerPubkey = await _resolveProvenPubkey(group, role: 'buyer');
    final sellerPubkey =
        await _resolveProvenPubkey(group, role: 'seller') ?? group.sellerPubkey;

    if (buyerPubkey == null) {
      _logger.d('Skipping reservation notice for $tradeId: no buyer proof');
      return;
    }

    final listing = await loadListing(group.listingAnchor);
    final hostName = await _displayNameFor(sellerPubkey);
    final buyerContent = _buyerNoticeContent(
      hostName: hostName,
      listingTitle: listing?.title,
      start: group.start,
      end: group.end,
    );
    final sellerContent = _sellerNoticeContent(
      listingTitle: listing?.title,
      start: group.start,
      end: group.end,
    );

    await _maybeSend(
      tradeId: tradeId,
      role: 'buyer',
      recipientPubkey: buyerPubkey,
      content: buyerContent,
    );
    await _maybeSend(
      tradeId: tradeId,
      role: 'seller',
      recipientPubkey: sellerPubkey,
      content: sellerContent,
    );
  }

  bool _hasEnded(ReservationGroup group) {
    final end = group.end;
    if (end == null) return false;
    return !end.toUtc().isAfter(clock().toUtc());
  }

  Future<String?> _resolveProvenPubkey(
    ReservationGroup group, {
    required String role,
  }) async {
    final keyPair = escrowKeyPair();
    for (final reservation in group.reservations) {
      final proof = await reservation.resolvePubkeyProof(
        role: role,
        recipientKeyPair: keyPair,
      );
      if (proof != null) return proof.pubkey;
    }
    return null;
  }

  Future<void> _maybeSend({
    required String tradeId,
    required String role,
    required String recipientPubkey,
    required String content,
  }) async {
    if (_hasExistingNotice(
      tradeId: tradeId,
      role: role,
      recipientPubkey: recipientPubkey,
    )) {
      _logger.d(
        'Skipping duplicate reservation notice: '
        'trade=$tradeId role=$role recipient=$recipientPubkey',
      );
      return;
    }

    final tags = [
      [_hostrTradeIdTag, tradeId],
      ['hostr_notice', 'reservation_placed', role, recipientPubkey],
    ];

    await sendText(
      content: content,
      tags: tags,
      recipientPubkeys: [recipientPubkey],
    );
    await sendLegacyText(
      content: content,
      tags: tags,
      recipientPubkey: recipientPubkey,
    );
  }

  bool _hasExistingNotice({
    required String tradeId,
    required String role,
    required String recipientPubkey,
  }) {
    final escrowPubkey = escrowKeyPair().publicKey;
    return existingMessagesForTrade(tradeId).any((message) {
      if (message.pubKey != escrowPubkey) return false;
      if (!message.pTags.contains(recipientPubkey)) return false;
      final hasTradeId = message.tags.any(
        (tag) =>
            tag.length >= 2 && tag[0] == _hostrTradeIdTag && tag[1] == tradeId,
      );
      if (!hasTradeId) return false;
      return message.tags.any(
        (tag) =>
            tag.length >= 4 &&
            tag[0] == 'hostr_notice' &&
            tag[1] == 'reservation_placed' &&
            tag[2] == role &&
            tag[3] == recipientPubkey,
      );
    });
  }

  Future<String> _displayNameFor(String pubkey) async {
    final profile = await loadMetadata(pubkey);
    return profile?.metadata.displayName ??
        profile?.metadata.name ??
        _shortPubkey(pubkey);
  }

  static String _buyerNoticeContent({
    required String hostName,
    required String? listingTitle,
    required DateTime? start,
    required DateTime? end,
  }) {
    final reservation = _reservationDescription(
      listingTitle: listingTitle,
      start: start,
      end: end,
    );
    return 'You successfully reserved $reservation, hosted by $hostName. '
        "Your payment is safely in escrow. We've reached out to the host to confirm, and they should be in touch soon. "
        'If they do not confirm in a timely manner, you can be refunded.';
  }

  static String _sellerNoticeContent({
    required String? listingTitle,
    required DateTime? start,
    required DateTime? end,
  }) {
    final reservation = _reservationDescription(
      listingTitle: listingTitle,
      start: start,
      end: end,
    );
    return 'A reservation was placed for $reservation. '
        'Payment has been paid and is sitting in escrow. '
        'Please login to https://hostr.network to confirm the booking with the guest.';
  }

  static String _reservationDescription({
    required String? listingTitle,
    required DateTime? start,
    required DateTime? end,
  }) {
    final title = listingTitle?.trim().isNotEmpty == true
        ? listingTitle!.trim()
        : 'a listing';
    final range = _dateRange(start, end);
    final suffix = range.isEmpty ? '' : ' $range';
    return '$title$suffix';
  }

  static String _dateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    if (start == null) return _date(end!);
    if (end == null) return _date(start);
    return '${_date(start)} - ${_date(end)}';
  }

  static String _date(DateTime date) =>
      date.toUtc().toIso8601String().split('T').first;

  static String _shortPubkey(String pubkey) =>
      pubkey.length <= 8 ? pubkey : pubkey.substring(0, 8);
}

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
  late final EscrowReservationNotifier _reservationNotifier;
  final Map<String, ReservationGroup> _reservationGroups = {};
  final Map<String, Timer> _reservationRetryTimers = {};

  // ── Subscriptions ───────────────────────────────────────────────────────
  StreamSubscription? _eventSub;
  StreamSubscription<int>? _blockSub;
  final Map<String, StreamSubscription> _tradeEventSubs = {};
  StreamSubscription? _threadSub;
  StreamSubscription? _reservationPTagSub;
  StreamSubscription? _reservationAuthorSub;
  Timer? _reservationDebounce;
  int? _latestBlockNum;
  static const _reservationRetryDelay = Duration(seconds: 5);

  EscrowDaemon({required Hostr hostr})
    : _hostr = hostr,
      _logger = hostr.logger.scope('escrow-daemon') {
    _escrowVerification = EscrowVerification(evm: hostr.evm, logger: _logger);
    _reservationNotifier = EscrowReservationNotifier(
      escrowKeyPair: () => _hostr.auth.activeKeyPair!,
      loadListing: (anchor) => _hostr.listings.getOneByAnchor(anchor),
      loadMetadata: (pubkey) => _hostr.metadata.loadMetadata(pubkey),
      existingMessagesForTrade: (_) => _hostr.messaging.threads.threads.values
          .expand((thread) => thread.state.value.textMessages),
      sendText:
          ({required content, required tags, required recipientPubkeys}) async {
            await _hostr.messaging.broadcastText(
              content: content,
              tags: tags,
              recipientPubkeys: recipientPubkeys,
            );
          },
      sendLegacyText:
          ({required content, required tags, required recipientPubkey}) async {
            await _sendLegacyDm(
              content: content,
              tags: tags,
              recipientPubkey: recipientPubkey,
            );
          },
      logger: _logger,
    );
  }

  Future<void> _sendLegacyDm({
    required String content,
    required List<List<String>> tags,
    required String recipientPubkey,
  }) async {
    final keyPair = _hostr.auth.activeKeyPair!;
    final signer = CoinlibEventSigner(
      privateKey: keyPair.privateKey,
      publicKey: keyPair.publicKey,
    );
    final encrypted = await signer.encrypt(content, recipientPubkey);
    if (encrypted == null) {
      throw StateError('Failed to encrypt legacy DM for $recipientPubkey');
    }

    await _hostr.requests.broadcast(
      event: Nip01Event(
        pubKey: keyPair.publicKey,
        kind: kNostrKindLegacyDM,
        tags: [
          ['p', recipientPubkey],
          ...tags,
        ],
        content: encrypted,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    );
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
              chain,
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
    _startBlockTipListener();
    _startContractListener();
    await _startThreadListener();
    _startReservationListener();
    _logger.i('Escrow monitor started');
  }

  /// Stop all subscriptions.
  Future<void> stop() async {
    await _eventSub?.cancel();
    await _blockSub?.cancel();
    for (final sub in _tradeEventSubs.values) {
      await sub.cancel();
    }
    _tradeEventSubs.clear();
    await _threadSub?.cancel();
    await _reservationPTagSub?.cancel();
    await _reservationAuthorSub?.cancel();
    _reservationDebounce?.cancel();
    for (final timer in _reservationRetryTimers.values) {
      timer.cancel();
    }
    _reservationRetryTimers.clear();
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

  int? get latestBlockNum => _latestBlockNum;

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

  @visibleForTesting
  static Stream<Reservation> reservationListenerEvents(
    StreamWithStatus<Reservation> source,
  ) => source.replayStream;

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

      _eventSub = streamer.replayStream.listen((event) {
        if (event is EscrowFundedEvent) {
          _logger.i('Discovered trade: ${event.tradeId}  ${event.amount}');
          _startTradeListener(event.tradeId);
        }
      }, onError: (e, st) => _logger.e('Arbiter event error: $e'));
    });
  }

  void _startBlockTipListener() {
    _blockSub ??= context.configuredChain.newBlocks().listen(
      (blockNum) => _latestBlockNum = blockNum,
      onError: (e, st) => _logger.e('Block tip stream error: $e'),
    );
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

    _tradeEventSubs[tradeId] = streamer.replayStream.listen(
      _onTradeEvent,
      onError: (e, st) => _logger.e('Trade $tradeId event error: $e'),
    );
  }

  void _onTradeEvent(EscrowEvent event) {
    final updatedAt = _updatedAtForEscrowEvent(event);
    _latestBlockNum = _latestBlockNum == null
        ? event.blockNum
        : max(_latestBlockNum!, event.blockNum);

    if (event is EscrowFundedEvent) {
      _logger.i('Trade funded: ${event.tradeId}  ${event.amount}');
      _trades[event.tradeId] = TradeSnapshot(
        tradeId: event.tradeId,
        status: TradeStatus.funded,
        amount: event.amount,
        lastTxHash: event.transactionHash,
        updatedAt: updatedAt,
        updatedBlockNum: event.blockNum,
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
          updatedAt: updatedAt,
          updatedBlockNum: event.blockNum,
        );
      }
    } else if (event is EscrowReleasedEvent) {
      _logger.i('Trade released: ${event.tradeId}');
      final existing = _trades[event.tradeId];
      if (existing != null) {
        _trades[event.tradeId] = existing.copyWith(
          status: TradeStatus.released,
          lastTxHash: event.transactionHash,
          updatedAt: updatedAt,
          updatedBlockNum: event.blockNum,
        );
      }
    } else if (event is EscrowClaimedEvent) {
      _logger.i('Trade claimed: ${event.tradeId}');
      final existing = _trades[event.tradeId];
      if (existing != null) {
        _trades[event.tradeId] = existing.copyWith(
          status: TradeStatus.claimed,
          lastTxHash: event.transactionHash,
          updatedAt: updatedAt,
          updatedBlockNum: event.blockNum,
        );
      }
    }

    _tradesSubject.add(_trades);
  }

  DateTime _updatedAtForEscrowEvent(EscrowEvent event) {
    final block = event.block;
    if (block != null) return block.timestamp;

    return DateTime.now().toUtc();
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
    _reservationPTagSub = reservationListenerEvents(pTagStream).listen(
      _onReservation,
      onError: (e) => _logger.e('Reservation p-tag stream error: $e'),
    );

    // 2. Reservations authored by the escrow (our own past confirmations/
    //    cancellations). Needed so group.escrowReservation is populated and
    //    we skip groups we've already handled.
    final authorStream = _hostr.reservations.subscribe(
      Filter(authors: [escrowPubkey]),
    );
    _reservationAuthorSub = reservationListenerEvents(authorStream).listen(
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

  void _scheduleReservationRetry(String groupId) {
    _reservationRetryTimers[groupId]?.cancel();
    _reservationRetryTimers[groupId] = Timer(_reservationRetryDelay, () {
      _reservationRetryTimers.remove(groupId);
      final latestGroup = _reservationGroups[groupId];
      if (latestGroup == null) return;
      unawaited(_processGroup(latestGroup));
    });
  }

  Future<void> _processGroup(ReservationGroup group) async {
    final groupId = group.reservations.isEmpty
        ? null
        : ReservationGroup.groupIdFromEvent(group.reservations.last);

    // Already confirmed/cancelled by us — do not publish another reservation,
    // but still run the idempotent notifier in case the daemon restarted after
    // confirming and before sending participant DMs.
    if (group.escrowReservation != null) {
      if (groupId != null) {
        _reservationRetryTimers.remove(groupId)?.cancel();
      }
      await _reservationNotifier.notifyReservation(group);
      return;
    }

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
        if (groupId != null) {
          _reservationRetryTimers.remove(groupId)?.cancel();
        }
        await _publishEscrowConfirmation(group, buyer);
        await _reservationNotifier.notifyReservation(group);
      } else if (result is Invalid<ReservationGroup>) {
        final reason = result.reason;
        if (reason != null &&
            isRetryableReservationVerificationFailure(reason)) {
          _logger.w(
            'Escrow proof pending verification for trade=$tradeId: $reason. '
            'Retrying in ${_reservationRetryDelay.inSeconds}s.',
          );
          if (groupId != null) {
            _scheduleReservationRetry(groupId);
          }
          return;
        }
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

  @visibleForTesting
  static bool isRetryableReservationVerificationFailure(String reason) =>
      reason.startsWith('Escrow logs do not contain a funding event') ||
      reason.startsWith('Failed to query escrow logs for trade ');
}
