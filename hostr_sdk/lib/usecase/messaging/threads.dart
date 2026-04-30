import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event;
import 'package:rxdart/rxdart.dart';

import '../../injection.dart';
import '../../util/main.dart';
import '../auth/auth.dart';
import '../user_subscriptions/user_subscriptions.dart';
import 'thread.dart';

@Singleton()
class Threads {
  final CustomLogger _logger;
  final Auth _auth;
  final UserSubscriptions _userSubscriptions;

  final StreamController<Thread> threadController =
      StreamController<Thread>.broadcast();
  Stream<Thread> get threadStream => threadController.stream;

  final BehaviorSubject<StreamStatus> _statusSubject =
      BehaviorSubject<StreamStatus>.seeded(StreamStatusIdle());
  Stream<StreamStatus> get status => _statusSubject.stream;

  /// Raw parsedGiftwraps
  final StreamWithStatus<Nip01Event> events$ = StreamWithStatus<Nip01Event>();

  List<Nip01Event> _state = const [];
  List<Nip01Event> get state => _state;

  /// Tracks IDs of all events processed — prevents duplicate routing.
  final Set<String> _processedIds = {};

  final Map<String, Thread> threads = {};
  bool _seenReceiptsArmed = false;

  /// Number of conversations with unread messages;
  final BehaviorSubject<int> _unreadCount = BehaviorSubject<int>.seeded(0);
  Stream<int> get unreadConversationCount$ => _unreadCount.stream;

  void _recomputeUnreadCount() {
    final keyPair = _auth.activeKeyPair;
    if (keyPair == null) return;
    final myPubkey = keyPair.publicKey;
    var count = 0;
    for (final thread in threads.values) {
      if (thread.state.value.events.isEmpty) continue;
      if (thread.state.value.unreadCount(myPubkey) > 0) count++;
    }
    if (count != _unreadCount.value) {
      _unreadCount.add(count);
    }
  }

  StreamSubscription? _statusSubscription;
  StreamSubscription? _eventSubscription;
  final Map<String, StreamSubscription> _threadStateSubscriptions = {};

  Threads({
    required Auth auth,
    required UserSubscriptions userSubscriptions,
    required CustomLogger logger,
  }) : _auth = auth,
       _userSubscriptions = userSubscriptions,
       _logger = logger.scope('threads') {
    _statusSubscription = _userSubscriptions.giftwraps$.status
        .distinct((a, b) => a.runtimeType == b.runtimeType)
        .listen((status) {
          _statusSubject.add(status);
          events$.addStatus(status);
          _logger.d("Thread stats $status");
          if (status is StreamStatusLive && !_seenReceiptsArmed) {
            _seenReceiptsArmed = true;
            for (final thread in threads.values) {
              thread.armSeenReceiptsAfterHydration();
            }
          }
          if (status is StreamStatusQueryComplete) {
            _logger.d('Threads query complete');
          }
        });
    _eventSubscription = _userSubscriptions.giftwraps$.replayStream.listen(
      processEvent,
    );
  }

  Future<void> stop() => _logger.span('stop', () async {
    for (final thread in threads.values) {
      await thread.close();
    }
    threads.clear();
  });

  Future<void> reset() => _logger.span('reset', () async {
    await stop();
    _state = const [];
    _processedIds.clear();
    _seenReceiptsArmed = false;
    _unreadCount.add(0);
    _statusSubject.add(StreamStatusIdle());
    await events$.reset();
  });

  /// Waits for an event with the specified ID to appear in the processed stream.
  Future<Nip01Event> awaitEventId(String expectedId) => _logger.span(
    'awaitEventId',
    () async {
      _logger.d('Awaiting event with id $expectedId');
      return events$.replayStream.firstWhere((event) => event.id == expectedId);
    },
  );

  static List<String> normalizeParticipants(Iterable<String> participants) =>
      ReservationGroup.normalizeParticipants(participants);

  static String conversationIdentifier(
    Iterable<String> participants, {
    String conversationTag = '',
  }) => ReservationGroup.groupIdForParticipants(
    tradeId: conversationTag,
    participants: participants,
  );

  static String conversationId(String tradeId, Iterable<String> participants) =>
      conversationIdentifier(participants, conversationTag: tradeId);

  /// Compute thread anchor from any event carrying DM routing tags.
  /// Works uniformly for [Message] and [SeenStatus].
  static String threadIdentifierFor<T extends Nip01Event>(T event) =>
      conversationIdentifier([
        event.pubKey,
        ...event.pTags,
      ], conversationTag: event.getFirstTag(kConversationTag) ?? '');

  Thread ensureConversation({
    required Iterable<String> participants,
    String conversationTag = '',
  }) {
    final tag = conversationTag.trim();
    final anchor = conversationIdentifier(participants, conversationTag: tag);
    final created = !threads.containsKey(anchor);
    final thread = threads.putIfAbsent(
      anchor,
      () => getIt<Thread>(param1: anchor),
    );
    thread.configureConversation(
      conversationTag: tag,
      participants: participants,
    );
    if (created) {
      if (_seenReceiptsArmed) {
        thread.armSeenReceiptsAfterHydration();
      }
      threadController.add(thread);
      _threadStateSubscriptions[anchor] = thread.state.listen(
        (_) => _recomputeUnreadCount(),
      );
    }
    return thread;
  }

  Thread? findTradeThread({
    required String tradeId,
    required Iterable<String> participants,
  }) => threads[conversationId(tradeId, participants)];

  Thread ensureTradeConversation({
    required String tradeId,
    required Iterable<String> participants,
  }) =>
      ensureConversation(participants: participants, conversationTag: tradeId);

  List<Thread> findByConversationTag(String tag) =>
      threads.values.where((t) => t.conversationTag == tag.trim()).toList();

  /// Route a raw event from [UserSubscriptions.parsedGiftwraps$] to the
  /// appropriate thread.
  ///
  /// The incoming stream contains [Nip01Event] (with children intact).
  /// Thread routing is computed uniformly from the envelope's
  /// DM routing tags via [threadIdentifierFor].
  ///
  /// For [Message] events, children are unwrapped here:
  /// - [Reservation] child → stored as [Reservation] in the thread
  /// - [EscrowServiceSelected] child → stored as [EscrowServiceSelected]
  /// - No child / plain text → stored as [Message]
  ///
  /// Unwrapped events are emitted on [_processedEvents$] for downstream
  /// consumers (reservations, background worker, inbox list).
  void processEvent(Nip01Event raw) => _logger.spanSync('processEvent', () {
    // Ignore duplicate events — the relay or subscription layer may deliver
    // the same event more than once (e.g. stored + live).
    if (!_processedIds.add(raw.id)) return;

    final routingParticipants = [raw.pubKey, ...raw.pTags];
    _logger.d(
      'Received ${raw.runtimeType} ${raw.id} routing $routingParticipants',
    );

    // Route to (or create) the thread using the envelope's DM routing tags.
    final thread = ensureConversation(
      participants: routingParticipants,
      conversationTag: raw.getFirstTag(kConversationTag) ?? '',
    );
    thread.addRoutingParticipants(routingParticipants);

    thread.process(raw);

    events$.add(raw);

    // Maintain sorted global state list.
    final list = [..._state];
    var lo = 0;
    var hi = list.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (list[mid].createdAt <= raw.createdAt) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    list.insert(lo, raw);
    _state = List.unmodifiable(list);
  });

  /// Get the most recent timestamp from all cached events.
  int? getMostRecentTimestamp() =>
      _logger.spanSync('getMostRecentTimestamp', () {
        int? maxTimestamp;
        for (final event in state) {
          if (maxTimestamp == null || event.createdAt > maxTimestamp) {
            maxTimestamp = event.createdAt;
          }
        }
        return maxTimestamp;
      });

  Future<void> close() => _logger.span('close', () async {
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    for (final sub in _threadStateSubscriptions.values) {
      await sub.cancel();
    }
    _threadStateSubscriptions.clear();
    await stop();
    for (final thread in threads.values) {
      await thread.close();
    }
    threads.clear();
    await threadController.close();
    await _statusSubject.close();
    await _unreadCount.close();
    await events$.close();
  });
}
