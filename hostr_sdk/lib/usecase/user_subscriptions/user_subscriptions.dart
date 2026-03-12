import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01EventModel, ZapReceipt;
import 'package:rxdart/rxdart.dart';

import '../../util/main.dart';
import '../auth/auth.dart';
import '../escrow/escrow.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../messaging/threads.dart';
import '../requests/requests.dart';
import '../reservation_pairs/reservation_pairs.dart';
import '../reservation_transitions/reservation_transitions.dart';
import '../reservations/reservations.dart';
import '../reviews/reviews.dart';
import '../zaps/zaps.dart';

/// User-scoped subscription manager.
///
/// Instead of opening N × 5 Nostr subscriptions (one set per trade thread),
/// this singleton maintains a **constant 5** long-lived subscriptions that
/// cover all trades the user is involved in.
///
/// [Trade] becomes a lightweight filter/view layer that simply
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
       _logger = logger.scope('subscriptions');

  // ── Public streams ────────────────────────────────────────────────────

  /// All reservations for trades the user is involved in (by trade ID / d-tag).
  late ExpandableSubscription<Reservation> allMyReservations$;

  /// Validated reservation pairs derived from [allMyReservations$].
  /// Each pair is grouped by trade ID and validated (proof-checked) via
  /// [ReservationPairs.verifyFromSource].
  late StreamWithStatus<List<Validation<ReservationPair>>>
  allMyReservationPairs$;

  /// Latest validated reservation pairs flattened from [allMyReservationPairs$].
  late StreamWithStatus<Validation<ReservationPair>>
  allMyReservationPairsCurrent$;

  /// Reservation pairs where the current user is the **guest** (not the host).
  late StreamWithStatus<Validation<ReservationPair>> myTrips$;

  /// Reservation pairs where the current user is the **host**.
  late StreamWithStatus<Validation<ReservationPair>> myHostings$;

  /// All reservation transitions across every trade the user is in.
  late ExpandableSubscription<ReservationTransition> allTransitions$;

  /// All reviews authored by the current user. Static filter.
  late StreamWithStatus<Review> myReviews$;

  /// Combined payment events (zaps + escrow) across all trades.
  final StreamWithStatus<PaymentEvent> paymentEvents$ =
      StreamWithStatus<PaymentEvent>();

  /// Emits `true` once all required streams are live.
  final BehaviorSubject<bool> _isLive = BehaviorSubject.seeded(false);
  ValueStream<bool> get isLive => _isLive;

  final Set<String> _knownTradeIds = {};
  final Set<String> _knownSellerPubkeys = {};
  final Set<String> _knownEscrowServiceKeys = {};
  final Set<String> _knownZapTradeIds = {};
  final List<StreamWithStatus<PaymentEvent>> _paymentSources = [];

  final List<StreamSubscription> _discoverySubscriptions = [];
  bool _started = false;

  StreamWithStatus<Filter>? _reservationFilterSource;
  StreamWithStatus<Filter>? _transitionFilterSource;

  void start() => _logger.spanSync('start', () {
    if (_started) return;
    _started = true;

    final myPubkey = _auth.getActiveKey().publicKey;
    _logger.d('UserSubscriptions starting for $myPubkey');

    myReviews$ = _reviews.subscribe(
      Filter(authors: [myPubkey]),
      name: 'user-reviews',
    );

    _reservationFilterSource = StreamWithStatus<Filter>();
    _transitionFilterSource = StreamWithStatus<Filter>();

    allMyReservations$ = _reservations.expandableSubscribe(
      _reservationFilterSource!,
      name: 'user-reservations',
    );

    allMyReservationPairs$ = _reservationPairs.verifyFromSource(
      source: allMyReservations$.stream,
    );
    allMyReservationPairsCurrent$ = allMyReservationPairs$.currentItems();

    myTrips$ = allMyReservationPairs$.whereItems(
      (item) => item.event.hostPubkey != myPubkey,
    );
    myHostings$ = allMyReservationPairs$.whereItems(
      (item) => item.event.hostPubkey == myPubkey,
    );

    allTransitions$ = _transitions.expandableSubscribe(
      _transitionFilterSource!,
      name: 'user-transitions',
    );

    _trackLiveness();
    _startDiscoveryEngine();
  });

  Future<void> reset() => _logger.span('reset', () async {
    if (!_started) return;
    _started = false;
    _logger.d('UserSubscriptions resetting');

    for (final sub in _discoverySubscriptions) {
      await sub.cancel();
    }
    _discoverySubscriptions.clear();

    await myTrips$.close();
    await myHostings$.close();
    await allMyReservationPairsCurrent$.close();
    await allMyReservationPairs$.close();
    await allMyReservations$.reset();
    await allTransitions$.reset();
    await myReviews$.reset();
    await paymentEvents$.reset();

    for (final source in _paymentSources) {
      await source.close();
    }
    _paymentSources.clear();

    await _reservationFilterSource?.close();
    _reservationFilterSource = null;
    await _transitionFilterSource?.close();
    _transitionFilterSource = null;

    _knownTradeIds.clear();
    _knownSellerPubkeys.clear();
    _knownEscrowServiceKeys.clear();
    _knownZapTradeIds.clear();

    _isLive.add(false);
  });

  Future<void> dispose() => _logger.span('dispose', () async {
    await reset();
    await allMyReservations$.close();
    await allTransitions$.close();
    await myReviews$.close();
    await paymentEvents$.close();
    await _isLive.close();
  });

  void _startDiscoveryEngine() => _logger.spanSync('_startDiscoveryEngine', () {
    _logger.d("processing threads");

    _discoverySubscriptions.add(
      _threads.subscription!.replayStream.listen((message) {
        final child = message.child;
        if (child is Reservation) {
          _processReservationRequest(child);
        } else if (child is EscrowServiceSelected) {
          _maybeAddEscrowStream(child, message.parsedTags.threadAnchor);
        }
      }),
    );

    _discoverySubscriptions.add(
      _threads.status.whereType<StreamStatusLive>().take(1).listen((_) {
        _logger.d('Threads live — marking filter sources live');
        _reservationFilterSource?.addStatus(StreamStatusLive());
        _transitionFilterSource?.addStatus(StreamStatusLive());
      }),
    );
  });

  void _processReservationRequest(Reservation reservation) =>
      _logger.spanSync('_processReservationRequest', () {
        _logger.d('handling reservation message $reservation');

        bool tradeIdsChanged = false;

        final tradeId = reservation.getDtag();
        if (tradeId != null &&
            tradeId.isNotEmpty &&
            _knownTradeIds.add(tradeId)) {
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

        if (tradeIdsChanged) {
          _emitReservationFilter();
          _emitTransitionFilter();
        }
      });

  void _emitReservationFilter() =>
      _logger.spanSync('_emitReservationFilter', () {
        if (_knownTradeIds.isEmpty) return;
        final filter = Filter(dTags: _knownTradeIds.toList());
        _logger.d('emitting reservation filter dTags=${filter.dTags}');
        _reservationFilterSource?.add(filter);
      });

  void _emitTransitionFilter() => _logger.spanSync('_emitTransitionFilter', () {
    if (_knownTradeIds.isEmpty) return;
    final filter = Filter(tags: {'t': _knownTradeIds.toList()});
    _logger.d('emitting transition filter #t=$_knownTradeIds');
    _transitionFilterSource?.add(filter);
  });

  void _addZapReceiptStream({
    required String sellerPubkey,
    required String tradeId,
  }) => _logger.spanSync('_addZapReceiptStream', () {
    _logger.d(
      'UserSubscriptions adding zap receipt stream for '
      'seller=$sellerPubkey tradeId=$tradeId',
    );
    final zapSource = _zaps.subscribeZapReceipts(
      pubkey: sellerPubkey,
      eventId: tradeId,
    );
    final mapped = zapSource.asyncMap<PaymentEvent>((event) async {
      final receipt = ZapReceipt.fromEvent(event);
      final amountSats = receipt.amountSats;
      if (amountSats == null) {
        throw FormatException('Zap receipt ${event.id} has no parsable amount');
      }
      return ZapFundedEvent(
        tradeId: receipt.eventId!,
        event: Nip01EventModel.fromEntity(event),
        zapReceipt: receipt,
        amount: BitcoinAmount.fromInt(BitcoinUnit.sat, amountSats),
      );
    });
    mapped.onClose = () => zapSource.close();
    _addPaymentSource(mapped);
  });

  void _maybeAddEscrowStream(
    EscrowServiceSelected escrowSelected,
    String threadAnchor,
  ) => _logger.spanSync('_maybeAddEscrowStream', () {
    final serviceId = escrowSelected.service.id;
    final key = '$threadAnchor:$serviceId';
    if (!_knownEscrowServiceKeys.add(key)) return;

    _logger.d(
      'UserSubscriptions adding escrow stream for '
      'service=$serviceId thread=$threadAnchor',
    );
    _addPaymentSource(_escrow.checkEscrowStatus(escrowSelected, threadAnchor));
  });

  void _addPaymentSource(StreamWithStatus<PaymentEvent> source) {
    _paymentSources.add(source);
    paymentEvents$.combine(source);
  }

  void _trackLiveness() => _logger.spanSync('_trackLiveness', () {
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
  });
}
