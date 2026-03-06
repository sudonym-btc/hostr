import 'dart:async';

import 'package:hostr_sdk/usecase/escrow/escrow.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01EventModel, ZapReceipt;
import 'package:rxdart/rxdart.dart';

import '../../util/main.dart';
import '../auth/auth.dart';
import '../requests/requests.dart';
import '../reservation_pairs/reservation_pairs.dart';
import '../reservation_transitions/reservation_transitions.dart';
import '../reservations/reservations.dart';
import '../reviews/reviews.dart';
import '../zaps/zaps.dart';
import 'threads.dart';

/// User-scoped subscription manager.
///
/// Instead of opening N × 5 Nostr subscriptions (one set per trade thread),
/// this singleton maintains a **constant 5** long-lived subscriptions that
/// cover all trades the user is involved in.
///
/// [TradeSubscriptions] becomes a lightweight filter/view layer that simply
/// does `.where(tradeId == mine)` on these shared streams.
///
/// ## Lifecycle
///
/// - **Starts** when the user logs in ([start]).
/// - **Resets** on logout ([reset]).
/// - **Expands** filters automatically as new trade IDs, listing anchors,
///   and escrow services are discovered from the message inbox.
///
/// ## Managed streams
///
/// | Stream | Filter pattern | Expandable? |
/// |---|---|---|
/// | [allMyReservations$] | `kinds=[32122], #d=[known tradeIds]` | Yes |
/// | [allTransitions$]    | `kinds=[32126], #t=[known tradeIds]` | Yes |
/// | [myReviews$]       | `kinds=[32124], authors=[myPubkey]`  | No (static) |
/// | [paymentEvents$]   | kind 9735 + EVM contract queries     | Dynamic (combine) |
@Singleton()
class UserSubscriptions {
  final Auth _auth;
  final Threads _threads;
  final Reservations _reservations;
  final ReservationTransitions _transitions;
  final ReservationPairs _reservationPairs;

  final Reviews _reviews;
  final Zaps _zaps;
  final EscrowUseCase _escrow;
  final CustomLogger _logger;

  UserSubscriptions({
    required Auth auth,
    required Threads threads,
    required Reservations reservations,
    required ReservationTransitions transitions,
    required ReservationPairs reservationPairs,
    required Reviews reviews,
    required Zaps zaps,
    required EscrowUseCase escrow,
    required CustomLogger logger,
  }) : _auth = auth,
       _threads = threads,
       _reservations = reservations,
       _transitions = transitions,
       _reservationPairs = reservationPairs,
       _reviews = reviews,
       _zaps = zaps,
       _escrow = escrow,
       _logger = logger;

  // ── Public streams ────────────────────────────────────────────────────

  /// All reservations for trades the user is involved in (by trade ID / d-tag).
  late ExpandableSubscription<Reservation> allMyReservations$;

  /// Validated reservation pairs derived from [allMyReservations$].
  /// Each pair is grouped by trade ID and validated (proof-checked) via
  /// [ReservationPairs.verifyFromSource].
  late StreamWithStatus<Validation<ReservationPairStatus>>
  allMyReservationPairs$;

  /// All reservation transitions across every trade the user is in.
  late ExpandableSubscription<ReservationTransition> allTransitions$;

  /// All reviews authored by the current user. Static filter.
  late StreamWithStatus<Review> myReviews$;

  /// Combined payment events (zaps + escrow) across all trades.
  late DynamicCombinedStreamWithStatus<PaymentEvent> paymentEvents$;

  /// Emits `true` once all required streams are live.
  final BehaviorSubject<bool> _isLive = BehaviorSubject.seeded(false);
  ValueStream<bool> get isLive => _isLive;

  // ── Discovery state ───────────────────────────────────────────────────

  final Set<String> _knownTradeIds = {};
  final Set<String> _knownSellerPubkeys = {};
  final Set<String> _knownEscrowServiceKeys = {};
  final Set<String> _knownZapTradeIds = {};

  final List<StreamSubscription> _discoverySubscriptions = [];
  bool _started = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  /// Start all user-scoped subscriptions. Call after login.
  void start() {
    if (_started) return;
    _started = true;

    final myPubkey = _auth.getActiveKey().publicKey;
    _logger.d('UserSubscriptions starting for $myPubkey');

    // 1. Static: my reviews (never needs filter expansion)
    myReviews$ = _reviews.subscribe(
      Filter(authors: [myPubkey]),
      name: 'user-reviews',
    );

    // 2. Expandable: reservations by trade ID (d-tag)
    allMyReservations$ = _reservations.expandableSubscribe(
      _emptyTradeIdFilter(),
      name: 'user-reservations',
    );

    // 3. Validated pairs from the raw reservations stream
    allMyReservationPairs$ = _reservationPairs.verifyFromSource(
      source: allMyReservations$.stream,
    );

    // 4. Expandable: transitions by trade ID
    allTransitions$ = _transitions.expandableSubscribe(
      _emptyTradeFilter(),
      name: 'user-transitions',
    );

    // 5. Dynamic: combined payment events (zaps + escrow)
    paymentEvents$ = DynamicCombinedStreamWithStatus<PaymentEvent>();

    // Wire up liveness tracking
    _trackLiveness();

    // Discover existing threads and listen for new ones
    _startDiscoveryEngine();
  }

  /// Tear down everything. Call on logout.
  Future<void> reset() async {
    if (!_started) return;
    _started = false;
    _logger.d('UserSubscriptions resetting');

    for (final sub in _discoverySubscriptions) {
      await sub.cancel();
    }
    _discoverySubscriptions.clear();

    await allMyReservationPairs$.close();
    await allMyReservations$.reset();
    await allTransitions$.reset();
    await myReviews$.reset();
    await paymentEvents$.reset();

    _knownTradeIds.clear();
    _knownSellerPubkeys.clear();
    _knownEscrowServiceKeys.clear();
    _knownZapTradeIds.clear();

    _isLive.add(false);
  }

  Future<void> dispose() async {
    await reset();
    await allMyReservations$.close();
    await allTransitions$.close();
    await myReviews$.close();
    await paymentEvents$.close();
    await _isLive.close();
  }

  // ── Discovery engine ──────────────────────────────────────────────────

  /// Watches all threads for trade-related data and expands filters when
  /// new anchors / trade IDs / escrow services are discovered.
  void _startDiscoveryEngine() {
    _logger.d("UserSubscriptions: processing threads");

    // Start expandable subs now — they may have empty filters initially
    // but that's fine; events just won't match until filters are expanded.
    allMyReservations$.start();
    allTransitions$.start();

    _discoverySubscriptions.add(
      _threads.subscription!.replay.listen((message) {
        _logger.d('UserSubscriptions: message received! ${message.id}');
        final child = message.child;
        if (child is Reservation) {
          _processReservationRequest(child);
        } else if (child is EscrowServiceSelected) {
          _maybeAddEscrowStream(child, message.parsedTags.threadAnchor);
        }
      }),
    );
  }

  void _processReservationRequest(Reservation reservation) {
    _logger.d('UserSubscriptions: handling reservation message $reservation');

    bool tradeIdsChanged = false;

    // Extract trade IDs from reservation requests
    final tradeId = reservation.getDtag();
    if (tradeId != null && tradeId.isNotEmpty && _knownTradeIds.add(tradeId)) {
      tradeIdsChanged = true;
    }

    final anchor = reservation.parsedTags.listingAnchor;
    final sellerPubkey = getPubKeyFromAnchor(anchor);
    if (sellerPubkey.isNotEmpty && _knownSellerPubkeys.add(sellerPubkey)) {
      final tradeId = reservation.getDtag();
      if (tradeId != null && _knownZapTradeIds.add(tradeId)) {
        _addZapReceiptStream(sellerPubkey: sellerPubkey, tradeId: tradeId);
      }
    }

    // Expand filters if new trade IDs were discovered
    if (tradeIdsChanged) {
      _expandReservationFilter();
      _expandTransitionFilter();
    }
  }

  // ── Filter expansion ──────────────────────────────────────────────────

  void _expandReservationFilter() {
    if (_knownTradeIds.isEmpty) return;

    final fullFilter = Filter(dTags: _knownTradeIds.toList());
    _logger.d('UserSubscriptions: updating filter ${fullFilter.dTags}');
    allMyReservations$.updateFilter(
      expandedFilter: _reservations.kindFilter(fullFilter),
      deltaFilter: _reservations.kindFilter(fullFilter),
    );
  }

  void _expandTransitionFilter() {
    if (_knownTradeIds.isEmpty) return;

    final fullFilter = Filter(tags: {'t': _knownTradeIds.toList()});
    allTransitions$.updateFilter(
      expandedFilter: _transitions.kindFilter(fullFilter),
      deltaFilter: _transitions.kindFilter(fullFilter),
    );
  }

  void _addZapReceiptStream({
    required String sellerPubkey,
    required String tradeId,
  }) {
    _logger.d(
      'UserSubscriptions adding zap receipt stream for '
      'seller=$sellerPubkey tradeId=$tradeId',
    );
    paymentEvents$.combine(
      _zaps
          .subscribeZapReceipts(pubkey: sellerPubkey, eventId: tradeId)
          .asyncMap<PaymentEvent>((event) async {
            final receipt = ZapReceipt.fromEvent(event);
            final amountSats = receipt.amountSats;
            if (amountSats == null) {
              throw FormatException(
                'Zap receipt ${event.id} has no parsable amount',
              );
            }
            return ZapFundedEvent(
              tradeId: receipt.eventId!,
              event: Nip01EventModel.fromEntity(event),
              zapReceipt: receipt,
              amount: BitcoinAmount.fromInt(BitcoinUnit.sat, amountSats),
            );
          }, closeInner: true),
    );
  }

  void _maybeAddEscrowStream(
    EscrowServiceSelected escrowSelected,
    String threadAnchor,
  ) {
    final serviceId = escrowSelected.service.id;
    final key = '$threadAnchor:$serviceId';
    if (!_knownEscrowServiceKeys.add(key)) return;

    _logger.d(
      'UserSubscriptions adding escrow stream for '
      'service=$serviceId thread=$threadAnchor',
    );
    paymentEvents$.combine(
      _escrow.checkEscrowStatus(escrowSelected, threadAnchor),
    );
  }

  // ── Liveness tracking ─────────────────────────────────────────────────

  void _trackLiveness() {
    final streams = <Stream<StreamStatus>>[
      myReviews$.status,
      allMyReservations$.stream.status,
      allTransitions$.stream.status,
    ];

    if (streams.isEmpty) return;

    _discoverySubscriptions.add(
      Rx.combineLatest(
        streams,
        (statuses) => statuses.every((s) => s is StreamStatusLive),
      ).listen((allLive) {
        if (allLive && !_isLive.value) _isLive.add(true);
      }),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// An empty d-tag filter that will match nothing until trade IDs are
  /// discovered.
  Filter _emptyTradeIdFilter() {
    return Filter(dTags: <String>[]);
  }

  Filter _emptyTradeFilter() {
    return Filter(tags: {'t': <String>[]});
  }
}
