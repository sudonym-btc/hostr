import 'dart:async';
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01Event;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart' show BlockNum;

import '../../config.dart' show CoinlibEventSigner;
import '../../util/main.dart';
import '../auth/auth.dart';
import '../escrow/escrow_verification.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract_registry.dart';
import '../escrows/escrows.dart';
import '../evm/evm.dart';
import '../listings/listings.dart';
import '../messaging/messaging.dart';
import '../metadata/metadata.dart';
import '../requests/requests.dart';
import '../reservation_groups/reservation_group_participant_resolver.dart';
import '../reservation_groups/reservation_groups.dart';
import '../reservations/reservation_participant_keyring.dart';
import '../reservations/reservation_participant_tags.dart';
import '../reservations/reservations.dart';
import '../user_subscriptions/user_subscriptions.dart';
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

typedef EscrowReservationGroupVerifier =
    Future<Validation<ReservationGroup>> Function(
      ReservationGroup group, {
      required bool forceValidateSelfSigned,
      required EscrowVerification escrowVerification,
    });

typedef EscrowDaemonClock = DateTime Function();

const _hostrTradeIdTag = 'tradeId';
const _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class EscrowReservationNotifier {
  final KeyPair Function() escrowKeyPair;
  final EscrowDaemonClock clock;
  final Future<Listing?> Function(String listingAnchor) loadListing;
  final Future<ProfileMetadata?> Function(String pubkey) loadMetadata;
  final EscrowReservationNoticeSender sendText;
  final EscrowReservationLegacyNoticeSender sendLegacyText;
  final EscrowReservationExistingMessages existingMessagesForTrade;
  final CustomLogger _logger;
  final Set<String> _sentNoticeKeys = {};

  EscrowReservationNotifier({
    required this.escrowKeyPair,
    EscrowDaemonClock? clock,
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
      _logger.i(
        'Skipping reservation notice: trade=$tradeId reason=reservation_ended',
      );
      return;
    }

    final resolvedParticipants = await _resolveParticipantSet(group);
    final buyerPubkey = _resolvedRolePubkey(
      resolvedParticipants,
      role: 'buyer',
      requireProofWhenPresent: true,
    );
    final sellerPubkey =
        _resolvedRolePubkey(resolvedParticipants, role: 'seller') ??
        group.sellerPubkey;

    if (buyerPubkey == null) {
      _logger.i(
        'Skipping reservation notice: trade=$tradeId reason=no_buyer_proof',
      );
      return;
    }

    _logger.i(
      'Reservation notice recipients resolved: '
      'trade=$tradeId buyer=$buyerPubkey seller=$sellerPubkey',
    );

    final listing = await loadListing(group.listingAnchor);
    final hostName = await _displayNameFor(sellerPubkey);
    final currentYear = clock().toUtc().year;
    final buyerContent = _buyerNoticeContent(
      hostName: hostName,
      listingTitle: listing?.title,
      start: group.start,
      end: group.end,
      currentYear: currentYear,
    );
    final sellerContent = _sellerNoticeContent(
      listingTitle: listing?.title,
      start: group.start,
      end: group.end,
      currentYear: currentYear,
    );

    await _maybeSend(
      tradeId: tradeId,
      noticeType: 'reservation_placed',
      role: 'buyer',
      recipientPubkey: buyerPubkey,
      content: buyerContent,
    );
    await _maybeSend(
      tradeId: tradeId,
      noticeType: 'reservation_placed',
      role: 'seller',
      recipientPubkey: sellerPubkey,
      content: sellerContent,
    );
  }

  Future<void> notifyCancellation(ReservationGroup group) async {
    final tradeId = group.tradeId;
    final resolvedParticipants = await _resolveParticipantSet(group);
    final buyerPubkey = _resolvedRolePubkey(
      resolvedParticipants,
      role: 'buyer',
      requireProofWhenPresent: true,
    );
    if (buyerPubkey == null) {
      _logger.i(
        'Skipping reservation cancellation notice: '
        'trade=$tradeId reason=no_buyer_proof',
      );
      return;
    }

    final listing = await loadListing(group.listingAnchor);
    final currentYear = clock().toUtc().year;
    await _maybeSend(
      tradeId: tradeId,
      noticeType: 'reservation_cancelled',
      role: 'buyer',
      recipientPubkey: buyerPubkey,
      content: _buyerCancellationNoticeContent(
        listingTitle: listing?.title,
        start: group.start,
        end: group.end,
        currentYear: currentYear,
      ),
    );
  }

  bool _hasEnded(ReservationGroup group) {
    final end = group.end;
    if (end == null) return false;
    return !end.toUtc().isAfter(clock().toUtc());
  }

  Future<ResolvedReservationGroupParticipants> _resolveParticipantSet(
    ReservationGroup group,
  ) {
    return ReservationGroupParticipantResolver(
      keyring: KeyPairReservationParticipantKeyring(
        keyPairs: [escrowKeyPair()],
        logger: _logger,
      ),
    ).resolve(group);
  }

  String? _resolvedRolePubkey(
    ResolvedReservationGroupParticipants participants, {
    required String role,
    bool requireProofWhenPresent = false,
  }) {
    return participants.resolvedParticipantPubkeyForRole(
      role,
      requireResolvedProof: requireProofWhenPresent,
    );
  }

  Future<void> _maybeSend({
    required String tradeId,
    required String noticeType,
    required String role,
    required String recipientPubkey,
    required String content,
  }) async {
    final noticeKey = '$tradeId|$noticeType|$role|$recipientPubkey';
    if (_sentNoticeKeys.contains(noticeKey) ||
        _hasExistingNotice(
          tradeId: tradeId,
          noticeType: noticeType,
          role: role,
          recipientPubkey: recipientPubkey,
        )) {
      _logger.i(
        'Skipping duplicate reservation notice: '
        'trade=$tradeId role=$role recipient=$recipientPubkey',
      );
      return;
    }

    final tags = [
      [_hostrTradeIdTag, tradeId],
      ['hostr_notice', noticeType, role, recipientPubkey],
    ];

    _logger.i(
      'Sending reservation notice: '
      'trade=$tradeId role=$role recipient=$recipientPubkey',
    );
    await sendText(
      content: content,
      tags: tags,
      recipientPubkeys: [recipientPubkey],
    );
    try {
      await sendLegacyText(
        content: content,
        tags: tags,
        recipientPubkey: recipientPubkey,
      );
    } catch (error, stackTrace) {
      _logger.w(
        'Legacy reservation notice failed: '
        'trade=$tradeId role=$role recipient=$recipientPubkey error=$error',
      );
      _logger.d('$stackTrace');
    }
    _sentNoticeKeys.add(noticeKey);
  }

  bool _hasExistingNotice({
    required String tradeId,
    required String noticeType,
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
            tag[1] == noticeType &&
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
    required int currentYear,
  }) {
    final reservation = _reservationDescription(
      listingTitle: listingTitle,
      start: start,
      end: end,
      currentYear: currentYear,
    );
    return 'You successfully reserved $reservation, hosted by $hostName. '
        "Your payment is safely in escrow. We've reached out to the host to confirm, and they should be in touch soon. "
        'If they do not confirm in a timely manner, you can be refunded.';
  }

  static String _sellerNoticeContent({
    required String? listingTitle,
    required DateTime? start,
    required DateTime? end,
    required int currentYear,
  }) {
    final reservation = _reservationDescription(
      listingTitle: listingTitle,
      start: start,
      end: end,
      currentYear: currentYear,
    );
    return 'A reservation was placed for $reservation. '
        'Payment has been paid and is sitting in escrow. '
        'Please login to https://hostr.network to confirm the booking with the guest.';
  }

  static String _buyerCancellationNoticeContent({
    required String? listingTitle,
    required DateTime? start,
    required DateTime? end,
    required int currentYear,
  }) {
    final reservation = _reservationDescription(
      listingTitle: listingTitle,
      start: start,
      end: end,
      currentYear: currentYear,
    );
    return 'Your reservation for $reservation could not be confirmed by escrow. '
        'No booking was created, and any escrowed payment should be refunded '
        'according to the payment method used.';
  }

  static String _reservationDescription({
    required String? listingTitle,
    required DateTime? start,
    required DateTime? end,
    required int currentYear,
  }) {
    final title = listingTitle?.trim().isNotEmpty == true
        ? listingTitle!.trim()
        : 'a listing';
    final range = _dateRange(start, end, currentYear: currentYear);
    final suffix = range.isEmpty ? '' : ' $range';
    return '$title$suffix';
  }

  static String _dateRange(
    DateTime? start,
    DateTime? end, {
    required int currentYear,
  }) {
    if (start == null && end == null) return '';
    final dates = [?start, ?end];
    final includeYear = dates.any((date) => date.toUtc().year != currentYear);
    if (start == null) return _date(end!, includeYear: includeYear);
    if (end == null) return _date(start, includeYear: includeYear);
    return '${_date(start, includeYear: includeYear)} - '
        '${_date(end, includeYear: includeYear)}';
  }

  static String _date(DateTime date, {required bool includeYear}) {
    final utc = date.toUtc();
    final month = _monthAbbreviations[utc.month - 1];
    final formatted = '${utc.day} $month';
    return includeYear ? '$formatted ${utc.year}' : formatted;
  }

  static String _shortPubkey(String pubkey) =>
      pubkey.length <= 8 ? pubkey : pubkey.substring(0, 8);
}

/// Use case that encapsulates all escrow-daemon business logic:
///
///   1. **Bootstrap** — build the [EscrowService] descriptor and verify the
///      contract is deployed.
///   2. **Monitor** — subscribe to on-chain contract events, Nostr thread
///      messages, and reservation events; auto-confirm or cancel buyer
///      self-signed reservations.
///
/// This is a long-lived object. Resolve it from dependency injection after auth
/// is initialized (`hostr.auth.signin(…)` / `hostr.auth.init()` completed).
///
/// ```dart
/// final daemon = hostr.escrowDaemon;
/// final ctx = await daemon.bootstrap(config);
/// daemon.start();
/// // … later …
/// await daemon.stop();
/// ```
@Singleton()
class EscrowDaemon {
  final Auth _auth;
  final Evm _evm;
  final Listings _listings;
  final MetadataUseCase _metadata;
  final Messaging _messaging;
  final Requests _requests;
  final Escrows _escrows;
  final Reservations _reservations;
  final UserSubscriptions _userSubscriptions;
  final EscrowVerification _escrowVerification;
  final EscrowReservationGroupVerifier _verifyReservationGroup;
  final CustomLogger _logger;

  EscrowDaemonContext? _context;
  bool _isStarted = false;

  // ── Trade state ─────────────────────────────────────────────────────────
  final Map<String, TradeSnapshot> _trades = {};
  final _tradesSubject = BehaviorSubject<Map<String, TradeSnapshot>>.seeded({});
  final Map<String, EscrowEvent> _latestTerminalEvents = {};

  // ── Reservation auto-confirmation state ─────────────────────────────────
  late final EscrowReservationNotifier _reservationNotifier;
  final Map<String, ReservationGroup> _reservationGroups = {};
  final Map<String, Timer> _reservationRetryTimers = {};
  PublishSubject<String>? _reservationRetryTradeIds;
  List<String> _legacyDmBootstrapRelays = const [];

  // ── Subscriptions ───────────────────────────────────────────────────────
  StreamSubscription? _eventSub;
  StreamSubscription<int>? _blockSub;
  final Map<String, StreamSubscription> _tradeEventSubs = {};
  StreamSubscription? _threadSub;
  StreamSubscription? _reservationSub;
  int? _latestBlockNum;
  static const _reservationRetryDelay = Duration(seconds: 5);

  EscrowDaemon({
    required Auth auth,
    required Evm evm,
    required Listings listings,
    required MetadataUseCase metadata,
    required Messaging messaging,
    required Requests requests,
    required Escrows escrows,
    required Reservations reservations,
    required UserSubscriptions userSubscriptions,
    required EscrowVerification escrowVerification,
    @ignoreParam EscrowReservationGroupVerifier? verifyReservationGroup,
    @ignoreParam EscrowDaemonClock? clock,
    required CustomLogger logger,
  }) : _auth = auth,
       _evm = evm,
       _listings = listings,
       _metadata = metadata,
       _messaging = messaging,
       _requests = requests,
       _escrows = escrows,
       _reservations = reservations,
       _userSubscriptions = userSubscriptions,
       _escrowVerification = escrowVerification,
       _verifyReservationGroup =
           verifyReservationGroup ?? _defaultVerifyReservationGroup,
       _logger = logger.scope('escrow-daemon') {
    _reservationNotifier = EscrowReservationNotifier(
      escrowKeyPair: () => _auth.activeKeyPair!,
      clock: clock,
      loadListing: (anchor) => _listings.getOneByAnchor(anchor),
      loadMetadata: (pubkey) => _metadata.loadMetadata(pubkey),
      existingMessagesForTrade: (_) => _messaging.threads.threads.values.expand(
        (thread) => thread.state.value.textMessages,
      ),
      sendText:
          ({required content, required tags, required recipientPubkeys}) async {
            await _messaging.broadcastTextAllowingExternalRelays(
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

  void setLegacyDmBootstrapRelays(List<String> relays) {
    _legacyDmBootstrapRelays = [
      ...{
        for (final relay in relays)
          if (relay.trim().isNotEmpty) relay.trim(),
      },
    ];
  }

  Future<void> _sendLegacyDm({
    required String content,
    required List<List<String>> tags,
    required String recipientPubkey,
  }) async {
    final keyPair = _auth.activeKeyPair!;
    final signer = CoinlibEventSigner(
      privateKey: keyPair.privateKey,
      publicKey: keyPair.publicKey,
    );
    final encrypted = await signer.encrypt(content, recipientPubkey);
    if (encrypted == null) {
      throw StateError('Failed to encrypt legacy DM for $recipientPubkey');
    }

    final relays = [
      ...{
        ...await _messaging.recipientMessageRelays(recipientPubkey),
        ..._legacyDmBootstrapRelays,
      },
    ];

    await _requests.broadcastEvent(
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
      relays: relays,
    );
  }

  // ── Getters ───────────────────────────────────────────────────────────────

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

  /// Whether the long-lived escrow listeners are currently active.
  bool get isStarted => _isStarted;

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  /// Builds the [EscrowService] and verifies the contract is deployed.
  ///
  /// Auth must already be initialized before calling this.
  Future<EscrowDaemonContext> bootstrap(EscrowDaemonConfig config) async {
    _logger.i('Bootstrapping escrow daemon…');

    final chain = _evm.configuredChains[config.chainIndex];
    final contractAddress = chain.config.escrowContractAddress!;
    final pubKey = _auth.activeKeyPair!.publicKey;
    final evmKey = await _auth.hd.getActiveEvmKey();
    final existingService = await _findExistingService(
      pubKey: pubKey,
      contractAddress: contractAddress,
    );
    final serviceId =
        existingService?.getFirstTag('d') ??
        'multi-escrow-${chain.config.chainId}';

    final escrowService = EscrowService(
      pubKey: pubKey,
      tags: EventTags([
        ['d', serviceId],
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

    final configuredChain = _evm.getChainForEscrowService(escrowService);
    final contract = configuredChain.escrow.getSupportedEscrowContract(
      escrowService,
    );

    await contract.ensureDeployed();

    _logger.i('Escrow service loaded: ${escrowService.content}');

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
    final services = await _escrows.list(
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
    if (_isStarted) return;
    _isStarted = true;
    try {
      _startBlockTipListener();
      _startContractListener();
      await _startThreadListener();
      _startReservationListener();
      _logger.i('Escrow monitor started');
    } catch (_) {
      _isStarted = false;
      rethrow;
    }
  }

  /// Stop all subscriptions.
  Future<void> stop() async {
    await _eventSub?.cancel();
    await _blockSub?.cancel();
    for (final sub in _tradeEventSubs.values) {
      await sub.cancel();
    }
    _tradeEventSubs.clear();
    _latestTerminalEvents.clear();
    await _threadSub?.cancel();
    await _reservationSub?.cancel();
    await _reservationRetryTradeIds?.close();
    _reservationRetryTradeIds = null;
    for (final timer in _reservationRetryTimers.values) {
      timer.cancel();
    }
    _reservationRetryTimers.clear();
    _tradesSubject.close();
    _isStarted = false;
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

  @visibleForTesting
  void startReservationListenerForTesting() => _startReservationListener();

  static Future<Validation<ReservationGroup>> _defaultVerifyReservationGroup(
    ReservationGroup group, {
    required bool forceValidateSelfSigned,
    required EscrowVerification escrowVerification,
  }) {
    return ReservationGroups.verifyGroupOnChain(
      group,
      forceValidateSelfSigned: forceValidateSelfSigned,
      escrowVerification: escrowVerification,
    );
  }

  // ── Contract events ───────────────────────────────────────────────────────

  /// Phase 1: Subscribe to `TradeCreated` events filtered by our arbiter
  /// address. For each discovered trade ID, spin up a per-trade stream
  /// (phase 2) that delivers ALL lifecycle events for that trade.
  void _startContractListener() {
    _auth.hd.getActiveEvmKey().then((evmKey) {
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
      ContractEventsParams(
        tradeId: tradeId,
        fromBlockOverride: const BlockNum.exact(0),
      ),
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
      final funded = TradeSnapshot(
        tradeId: event.tradeId,
        status: TradeStatus.funded,
        amount: event.amount,
        lastTxHash: event.transactionHash,
        updatedAt: updatedAt,
        updatedBlockNum: event.blockNum,
      );
      final terminal = _latestTerminalEvents[event.tradeId];
      final existing = _trades[event.tradeId];
      _trades[event.tradeId] = terminal != null
          ? _snapshotWithTerminalEvent(funded, terminal)
          : existing != null && _isTerminalStatus(existing.status)
          ? existing.copyWith(amount: event.amount)
          : funded;
    } else if (event is EscrowArbitratedEvent) {
      _logger.i(
        'Trade arbitrated: ${event.tradeId}  '
        'paymentForwarded=${event.paymentForwarded} '
        'bondForwarded=${event.bondForwarded}',
      );
      _latestTerminalEvents[event.tradeId] = _latestTerminalFor(
        _latestTerminalEvents[event.tradeId],
        event,
      );
      final existing = _trades[event.tradeId];
      if (existing != null) {
        _trades[event.tradeId] = _snapshotWithTerminalEvent(existing, event);
      }
    } else if (event is EscrowReleasedEvent) {
      _logger.i('Trade released: ${event.tradeId}');
      _latestTerminalEvents[event.tradeId] = _latestTerminalFor(
        _latestTerminalEvents[event.tradeId],
        event,
      );
      final existing = _trades[event.tradeId];
      if (existing != null) {
        _trades[event.tradeId] = _snapshotWithTerminalEvent(existing, event);
      }
    } else if (event is EscrowClaimedEvent) {
      _logger.i('Trade claimed: ${event.tradeId}');
      _latestTerminalEvents[event.tradeId] = _latestTerminalFor(
        _latestTerminalEvents[event.tradeId],
        event,
      );
      final existing = _trades[event.tradeId];
      if (existing != null) {
        _trades[event.tradeId] = _snapshotWithTerminalEvent(existing, event);
      }
    }

    _tradesSubject.add(_trades);
  }

  EscrowEvent _latestTerminalFor(EscrowEvent? current, EscrowEvent next) {
    if (current == null) return next;
    if (next.blockNum != current.blockNum) {
      return next.blockNum > current.blockNum ? next : current;
    }
    if (next.transactionIndex != current.transactionIndex) {
      return next.transactionIndex > current.transactionIndex ? next : current;
    }
    return next.logIndex >= current.logIndex ? next : current;
  }

  TradeSnapshot _snapshotWithTerminalEvent(
    TradeSnapshot snapshot,
    EscrowEvent event,
  ) {
    final status = switch (event) {
      EscrowArbitratedEvent() => TradeStatus.arbitrated,
      EscrowReleasedEvent() => TradeStatus.released,
      EscrowClaimedEvent() => TradeStatus.claimed,
      _ => snapshot.status,
    };
    return snapshot.copyWith(
      status: status,
      lastTxHash: event.transactionHash,
      updatedAt: _updatedAtForEscrowEvent(event),
      updatedBlockNum: event.blockNum,
    );
  }

  bool _isTerminalStatus(TradeStatus status) =>
      status == TradeStatus.arbitrated ||
      status == TradeStatus.released ||
      status == TradeStatus.claimed;

  DateTime _updatedAtForEscrowEvent(EscrowEvent event) {
    final block = event.block;
    if (block != null) return block.timestamp;

    return DateTime.now().toUtc();
  }

  // ── Nostr thread messages ─────────────────────────────────────────────────

  Future<void> _startThreadListener() async {
    _logger.i('Starting thread listener…');
    await _userSubscriptions.start();
    _logger.i('UserSubscriptions started');

    _threadSub = _messaging.threads.threadStream.listen((thread) {
      _logger.d('New/updated thread: ${thread.anchor}');
    }, onError: (e) => _logger.e('Thread stream error: $e'));

    // Wait for the initial gift-wrap query to complete so threads are
    // populated before the daemon reports ready. Timeout after 30s so
    // a slow relay doesn't block startup indefinitely.
    _logger.i('Waiting for thread query to complete…');
    try {
      await _messaging.threads.status
          .firstWhere(
            (s) => s is StreamStatusQueryComplete || s is StreamStatusLive,
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      _logger.w(
        'Thread loading timed out after 30s — '
        'continuing with ${_messaging.threads.threads.length} threads',
      );
    }
    _logger.i(
      'Threads ready: ${_messaging.threads.threads.length} conversations',
    );
  }

  // ── Reservation auto-confirmation ─────────────────────────────────────────

  void _startReservationListener() {
    final escrowPubkey = _auth.activeKeyPair!.publicKey;

    final escrowTaggedReservations = _reservations.subscribe(
      Filter(pTags: [escrowPubkey]),
      name: 'escrow-reservation-triggers',
    );

    final retryTradeIds = PublishSubject<String>();
    _reservationRetryTradeIds = retryTradeIds;
    final triggeredTradeIds = reservationListenerEvents(
      escrowTaggedReservations,
    ).map(reservationTradeId).whereType<String>();

    _reservationSub =
        Rx.merge<String>([triggeredTradeIds, retryTradeIds.stream])
            .where((tradeId) => tradeId.isNotEmpty)
            .doOnData(
              (tradeId) =>
                  _logger.d('Reservation trigger received: trade=$tradeId'),
            )
            .flatMap(
              (tradeId) =>
                  Stream.fromFuture(_processReservationTradeId(tradeId)),
              maxConcurrent: 1,
            )
            .listen(
              (_) {},
              onError: (e, st) =>
                  _logger.e('Reservation processing stream error: $e'),
            );

    _logger.i('Reservation listener started for $escrowPubkey');
  }

  Future<void> _processReservationTradeId(String tradeId) async {
    try {
      final groups = await _queryReservationGroupsForTrade(tradeId);
      for (final group in groups) {
        await _processGroup(group);
      }
    } catch (e, st) {
      _logger.e('Error processing reservation trade=$tradeId: $e');
      _logger.e('$st');
    }
  }

  Future<List<ReservationGroup>> _queryReservationGroupsForTrade(
    String tradeId,
  ) async {
    final escrowPubkey = _auth.activeKeyPair!.publicKey;
    final reservations = await _reservations.getByTradeId(tradeId);
    final groups =
        Reservations.toReservationGroups(reservations: reservations).values
            .where(
              (group) => reservationGroupInvolvesEscrow(group, escrowPubkey),
            )
            .toList()
          ..sort((a, b) => a.groupId.compareTo(b.groupId));

    for (final group in groups) {
      _reservationGroups[group.groupId] = group;
    }
    return groups;
  }

  void _scheduleReservationRetry(String tradeId) {
    _reservationRetryTimers[tradeId]?.cancel();
    _reservationRetryTimers[tradeId] = Timer(_reservationRetryDelay, () {
      _reservationRetryTimers.remove(tradeId);
      _reservationRetryTradeIds?.add(tradeId);
    });
  }

  Future<void> _processGroup(ReservationGroup group) async {
    // Already confirmed/cancelled by us — do not publish another reservation,
    // but still run the idempotent notifier in case the daemon restarted after
    // confirming and before sending participant DMs.
    final escrowReservation = group.escrowReservation;
    if (escrowReservation != null) {
      _reservationRetryTimers.remove(group.tradeId)?.cancel();
      if (escrowReservation.stage == ReservationStage.commit) {
        await _reservationNotifier.notifyReservation(group);
      } else if (escrowReservation.stage == ReservationStage.cancel) {
        await _reservationNotifier.notifyCancellation(group);
      }
      return;
    }

    final buyer = group.buyerReservation;
    if (buyer == null) return;
    if (buyer.stage != ReservationStage.commit) return;
    if (buyer.proof?.escrowProof == null) return;

    final tradeId = group.tradeId;
    _logger.i('Processing reservation group: trade=$tradeId');

    try {
      final result = await _verifyReservationGroup(
        group,
        forceValidateSelfSigned: true,
        escrowVerification: _escrowVerification,
      );

      if (result is Valid<ReservationGroup>) {
        _reservationRetryTimers.remove(group.tradeId)?.cancel();
        final latest = await _latestReservationGroup(group);
        if (latest != null) {
          final latestEscrowReservation = latest.escrowReservation;
          if (latestEscrowReservation != null) {
            _reservationGroups[latest.groupId] = latest;
            if (latestEscrowReservation.stage == ReservationStage.cancel) {
              await _reservationNotifier.notifyCancellation(latest);
            } else if (latestEscrowReservation.stage ==
                ReservationStage.commit) {
              await _reservationNotifier.notifyReservation(latest);
            }
            return;
          }
        }

        await _publishEscrowConfirmation(group, buyer);
        await _reservationNotifier.notifyReservation(group);
      } else if (result is Invalid<ReservationGroup>) {
        final reason = result.reason;
        if (isRetryableReservationVerificationFailure(reason)) {
          _logger.w(
            'Escrow proof pending verification for trade=$tradeId: $reason. '
            'Retrying in ${_reservationRetryDelay.inSeconds}s.',
          );
          _scheduleReservationRetry(group.tradeId);
          return;
        }
        _logger.w('Escrow proof INVALID for trade=$tradeId: $reason');
        await _publishEscrowCancellation(group, buyer);
        await _reservationNotifier.notifyCancellation(group);
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
    final keyPair = _auth.activeKeyPair!;

    final reservation = await _reservations.confirm(group, keyPair);

    // Update local group so we don't re-process.
    final groupId = rawReservationGroupId(reservation);
    _reservationGroups[groupId] = (_reservationGroups[groupId] ?? group)
        .addReservation(reservation);

    _logger.i('✓ Published escrow CONFIRM for trade=${group.tradeId}');
  }

  Future<ReservationGroup?> _latestReservationGroup(
    ReservationGroup group,
  ) async {
    final reservations = await _reservations.getByTradeId(group.tradeId);
    final groups = Reservations.toReservationGroups(reservations: reservations);
    final escrowPubkey = _auth.activeKeyPair!.publicKey;
    final latest =
        groups[group.groupId] ??
        groups.values.where((candidate) {
          return reservationGroupInvolvesEscrow(candidate, escrowPubkey);
        }).firstOrNull;
    if (latest != null) {
      _reservationGroups[latest.groupId] = latest;
    }
    return latest;
  }

  Future<void> _publishEscrowCancellation(
    ReservationGroup group,
    Reservation buyer,
  ) async {
    final keyPair = _auth.activeKeyPair!;

    final reservation = await _reservations.cancel(group, keyPair);

    // Update local group so we don't re-process.
    final groupId = rawReservationGroupId(reservation);
    _reservationGroups[groupId] = (_reservationGroups[groupId] ?? group)
        .addReservation(reservation);

    _logger.i('✗ Published escrow CANCEL for trade=${group.tradeId}');
  }

  @visibleForTesting
  static String? reservationTradeId(Reservation reservation) =>
      reservation.getDtag();

  @visibleForTesting
  static bool reservationGroupInvolvesEscrow(
    ReservationGroup group,
    String escrowPubkey,
  ) {
    if (group.escrowPubkey == escrowPubkey) return true;
    return group.reservations.any(
      (reservation) =>
          reservation.pubKey == escrowPubkey ||
          reservation.parsedTags.getTags('p').contains(escrowPubkey),
    );
  }

  @visibleForTesting
  static bool isRetryableReservationVerificationFailure(String reason) =>
      reason.startsWith('Escrow logs do not contain a funding event') ||
      reason.startsWith('Failed to query escrow logs for trade ');
}
