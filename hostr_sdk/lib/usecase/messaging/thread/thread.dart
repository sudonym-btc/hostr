import 'dart:async';
import 'dart:math' as math;

import 'package:injectable/injectable.dart' hide Order;
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Nip01Event;
import 'package:rxdart/rxdart.dart';

import '../../../util/custom_logger.dart';
import '../../../util/stream_status.dart';
import '../../auth/auth.dart';
import '../../user_subscriptions/user_subscriptions.dart';
import '../messaging.dart';
import 'state.dart';

@Injectable()
class Thread {
  final CustomLogger _logger;
  final Messaging _messaging;
  final Auth _auth;
  final UserSubscriptions _userSubscriptions;
  final BehaviorSubject<ThreadState> state;
  final List<StreamSubscription> _stateSubscriptions = [];

  final String anchor;

  final StreamWithStatus<Nip01Event> events = StreamWithStatus<Nip01Event>();

  /// Participants derived from the Message envelopes at routing time.
  /// Populated by [addRoutingParticipants] called from [Threads].
  final Set<String> _knownParticipants = {};

  String conversationTag = '';
  final Map<String, int> _seenUntil = {};
  Timer? _seenReceiptDebounce;
  int _suppressSeenReceiptsThrough = 0;
  bool _seenReceiptsArmed = false;

  bool _isTradeCandidate(ThreadState current) =>
      current.orderRequests.isNotEmpty || current.events.any((e) => e is Order);

  bool get isTradeCandidate =>
      conversationTag.isNotEmpty || _isTradeCandidate(state.value);

  Thread(
    @factoryParam this.anchor, {
    required CustomLogger logger,
    required Auth auth,
    required Messaging messaging,
    required UserSubscriptions userSubscriptions,
  }) : _auth = auth,
       _messaging = messaging,
       _userSubscriptions = userSubscriptions,
       _logger = logger.scope('thread'),
       state = BehaviorSubject<ThreadState>.seeded(
         ThreadState.initial(
           ourPubkey: auth.activeKeyPair!.publicKey,
           anchor: anchor,
         ),
       ) {
    _stateSubscriptions.add(
      events.stream.listen((event) {
        if (event is SeenStatus) {
          _processSeenReceipt(event);
        } else {
          _processEvent(event);
        }
      }),
    );
    _stateSubscriptions.add(
      _userSubscriptions.latestHeartbeats$.stream
          .where(
            (heartbeat) =>
                _knownParticipants.contains(heartbeat.pubKey) ||
                addedParticipants.contains(heartbeat.pubKey),
          )
          .listen((_) {
            _processHeartbeat();
          }),
    );
  }

  /// Record participants derived from the DM envelope at routing time.
  void addRoutingParticipants(Iterable<String> pubkeys) {
    _knownParticipants.addAll(pubkeys.where((p) => p.isNotEmpty));
  }

  List<String> _sortedPubkeys(Iterable<String> pubkeys) =>
      (pubkeys.where((p) => p.isNotEmpty).toSet().toList()..sort());

  List<String> _currentParticipantPubkeys() => _sortedPubkeys({
    _auth.getActiveKey().publicKey,
    ..._knownParticipants,
    ...addedParticipants,
  });

  List<String> _currentCounterpartyPubkeys() {
    final myPubkey = _auth.getActiveKey().publicKey;
    return _sortedPubkeys(
      {
        ..._knownParticipants,
        ...addedParticipants,
      }.where((pubkey) => pubkey != myPubkey),
    );
  }

  void _emitParticipantState() {
    if (state.isClosed) return;
    final nextCounterpartyPubkeys = _currentCounterpartyPubkeys();
    state.add(
      state.value.copyWith(
        participantPubkeys: _currentParticipantPubkeys(),
        counterpartyPubkeys: nextCounterpartyPubkeys,
        received: _computeReceived(
          events: state.value.events,
          counterpartyPubkeys: nextCounterpartyPubkeys,
        ),
        seenUntil: Map.unmodifiable(_seenUntil),
      ),
    );
  }

  /// Single entry point for all thread events.
  void process(Nip01Event event) {
    events.add(event);
  }

  void _processSeenReceipt(SeenStatus status) {
    final pubkey = status.pubKey;
    final timestamp = status.seenUntil;
    if (timestamp == null || pubkey.isEmpty) return;
    _recordSeenUntil(pubkey: pubkey, timestamp: timestamp);
  }

  void _recordSeenUntil({required String pubkey, required int timestamp}) {
    final existing = _seenUntil[pubkey] ?? 0;
    if (timestamp <= existing) return;

    _seenUntil[pubkey] = timestamp;
    if (state.isClosed) return;
    state.add(state.value.copyWith(seenUntil: Map.unmodifiable(_seenUntil)));
  }

  /// Binary-inserts [event] into an already-sorted list, returning a new list.
  List<Event> _insertSorted(List<Event> sorted, Event event) {
    int lo = 0, hi = sorted.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (sorted[mid].createdAt <= event.createdAt) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return [...sorted.sublist(0, lo), event, ...sorted.sublist(lo)];
  }

  /// Called when a new non-SeenStatus event arrives. Binary-inserts the event
  /// into the already-sorted [state.value.events] — O(log n) search + O(n) copy
  /// instead of a full O(n log n) resort on every emission.
  void _processEvent(Nip01Event rawEvent) =>
      _logger.spanSync('_processEvent', () {
        if (state.isClosed) return;
        final keyPair = _auth.activeKeyPair;
        if (keyPair == null) return;
        if (rawEvent is! Event) return;

        final nextEvents = _insertSorted(state.value.events, rawEvent);
        final nextParticipantPubkeys = _currentParticipantPubkeys();
        final nextCounterpartyPubkeys = _currentCounterpartyPubkeys();

        state.add(
          state.value.copyWith(
            events: nextEvents,
            participantPubkeys: nextParticipantPubkeys,
            counterpartyPubkeys: nextCounterpartyPubkeys,
            received: _computeReceived(
              events: nextEvents,
              counterpartyPubkeys: nextCounterpartyPubkeys,
            ),
            seenUntil: Map.unmodifiable(_seenUntil),
          ),
        );
      });

  /// Called when a relevant heartbeat arrives. Only recomputes [received] —
  /// the event list is unchanged.
  void _processHeartbeat() => _logger.spanSync('_processHeartbeat', () {
    if (state.isClosed) return;
    state.add(
      state.value.copyWith(
        received: _computeReceived(
          events: state.value.events,
          counterpartyPubkeys: state.value.counterpartyPubkeys,
        ),
      ),
    );
  });

  bool _computeReceived({
    required List<Event> events,
    required List<String> counterpartyPubkeys,
  }) {
    if (events.isEmpty || counterpartyPubkeys.isEmpty) {
      return false;
    }

    final latestCreatedAt = events
        .map((e) => e.createdAt)
        .reduce((a, b) => a > b ? a : b);
    final latestHeartbeats = {
      for (final heartbeat in _userSubscriptions.latestHeartbeats$.items)
        heartbeat.pubKey: heartbeat,
    };

    return counterpartyPubkeys.every((pubkey) {
      final heartbeat = latestHeartbeats[pubkey];
      return heartbeat != null && heartbeat.createdAt >= latestCreatedAt;
    });
  }

  List<String> addedParticipants = [];

  String? get tradeId {
    if (conversationTag.isNotEmpty) return conversationTag;
    for (final e in state.value.events.reversed) {
      if (e is Order) {
        final id = e.getDtag();
        if (id != null && id.isNotEmpty) return id;
      }
    }
    return null;
  }

  int get participantCount => {
    _auth.getActiveKey().publicKey,
    ...state.value.participantPubkeys,
    ...addedParticipants,
  }.where((p) => p.isNotEmpty).length;

  int get lastActivityTimestamp {
    final readable = state.value.readableEvents;
    if (readable.isNotEmpty) {
      return readable.map((e) => e.createdAt).reduce((a, b) => a > b ? a : b);
    }
    final items = events.items;
    if (items.isEmpty) return 0;
    return items.map((e) => e.createdAt).reduce((a, b) => a > b ? a : b);
  }

  void configureConversation({
    required String conversationTag,
    Iterable<String> participants = const [],
  }) {
    this.conversationTag = conversationTag;
    final myPubkey = _auth.getActiveKey().publicKey;
    for (final pubkey in participants.toSet()) {
      if (pubkey.isNotEmpty &&
          pubkey != myPubkey &&
          !addedParticipants.contains(pubkey)) {
        addedParticipants.add(pubkey);
      }
    }
    _emitParticipantState();
  }

  int _latestCounterpartyReadableCreatedAt([ThreadState? current]) {
    final snapshot = current ?? state.value;
    return snapshot.readableEvents
        .where((event) => event.pubKey != snapshot.ourPubkey)
        .map((event) => event.createdAt)
        .fold(0, math.max);
  }

  @visibleForTesting
  bool get shouldSendReceiptNow {
    final ourPubkey = _auth.getActiveKey().publicKey;
    final seenFloor = math.max(
      _seenUntil[ourPubkey] ?? 0,
      _suppressSeenReceiptsThrough,
    );
    return _latestCounterpartyReadableCreatedAt() > seenFloor;
  }

  /// Marks everything currently loaded in the thread as locally read without
  /// broadcasting a network seen receipt. This is used when the inbox first
  /// finishes hydrating so we do not acknowledge historical backlog as if it
  /// just arrived live.
  void markHistoryAsReadLocally() {
    final timestamp = _latestCounterpartyReadableCreatedAt();
    if (timestamp <= 0) return;

    _suppressSeenReceiptsThrough = math.max(
      _suppressSeenReceiptsThrough,
      timestamp,
    );
    _recordSeenUntil(
      pubkey: _auth.getActiveKey().publicKey,
      timestamp: timestamp,
    );
  }

  /// Enables network seen receipts after the initial giftwrap history has
  /// hydrated. Existing backlog becomes locally read without being broadcast.
  void armSeenReceiptsAfterHydration() {
    markHistoryAsReadLocally();
    _seenReceiptsArmed = true;
  }

  List<String> get _recipientPubkeys {
    final myPubkey = _auth.getActiveKey().publicKey;
    final recipients = <String>{
      ...state.value.counterpartyPubkeys,
      ...addedParticipants,
    }..removeWhere((pubkey) => pubkey.isEmpty || pubkey == myPubkey);
    final sorted = recipients.toList()..sort();
    return sorted;
  }

  List<List<String>> get _conversationTags => conversationTag.isEmpty
      ? const []
      : [
          [kConversationTag, conversationTag],
        ];

  Future<List<Future<List<RelayBroadcastResponse>>>> replyText(
    String content,
  ) => _logger.span('replyText', () async {
    return _messaging.broadcastText(
      content: content.trim(),
      tags: _conversationTags,
      recipientPubkeys: _recipientPubkeys,
    );
  });

  Future<Nip01Event> replyTextAndWait(String content) =>
      _logger.span('replyTextAndWait', () async {
        return _messaging.broadcastTextAndAwait(
          content: content.trim(),
          tags: _conversationTags,
          recipientPubkeys: _recipientPubkeys,
        );
      });

  Future<List<Future<List<RelayBroadcastResponse>>>>
  replyEvent<T extends Nip01Event>(
    T event, {
    List<List<String>> tags = const [],
  }) => _logger.span('replyEvent', () async {
    return _messaging.broadcastEvent(
      event: event,
      tags: [..._conversationTags, ...tags],
      recipientPubkeys: _recipientPubkeys,
    );
  });

  Future<Nip01Event> replyEventAndWait<T extends Nip01Event>(
    T event, {
    List<List<String>> tags = const [],
  }) => _logger.span('replyEventAndWait', () async {
    return _messaging.broadcastEventAndWait(
      event: event,
      tags: [..._conversationTags, ...tags],
      recipientPubkeys: _recipientPubkeys,
    );
  });

  Future<void> broadcastSeenReceipt<T extends Nip01Event>() =>
      _logger.span('broadcastSeenReceipt', () async {
        return _messaging.broadcastSeenReceipt(
          seenUntil: state.value.events.last.createdAt,
          tags: [..._conversationTags],
          recipientPubkeys: _knownParticipants.toList(),
        );
      });

  /// Mark this conversation as read. Debounces by 1 second to avoid
  /// sending receipts for accidental taps.
  void markAsRead() {
    _seenReceiptDebounce?.cancel();
    _seenReceiptDebounce = Timer(
      const Duration(seconds: 1),
      () => _sendSeenReceipt(),
    );
  }

  Future<void> _sendSeenReceipt() => _logger.span('_sendSeenReceipt', () async {
    if (!_seenReceiptsArmed) return;
    if (!shouldSendReceiptNow) return;
    if (_recipientPubkeys.isEmpty) return;

    final sorted = state.value.events;
    if (sorted.isEmpty) return;

    await broadcastSeenReceipt();
  });

  Future<void> close() => _logger.span('close', () async {
    _seenReceiptDebounce?.cancel();
    for (final s in _stateSubscriptions) {
      await s.cancel();
    }
    await state.close();
    await events.close();
  });
}
