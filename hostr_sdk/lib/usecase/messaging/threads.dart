import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import '../../injection.dart';
import '../../util/main.dart';
import '../user_subscriptions/user_subscriptions.dart';
import 'thread.dart';

@Singleton()
class Threads {
  final CustomLogger _logger;
  final UserSubscriptions _userSubscriptions;

  final StreamController<Thread> threadController =
      StreamController<Thread>.broadcast();
  Stream<Thread> get threadStream => threadController.stream;

  final BehaviorSubject<StreamStatus> _statusSubject =
      BehaviorSubject<StreamStatus>.seeded(StreamStatusIdle());
  Stream<StreamStatus> get status => _statusSubject.stream;
  StreamWithStatus<Message> get messages$ => _userSubscriptions.messages$;
  List<Message> _state = const [];
  List<Message> get state => _state;

  final Map<String, Thread> threads = {};

  /// O(1) duplicate guard — tracks every message id we have already ingested.
  final Set<String> _seenIds = {};

  StreamSubscription? _statusSubscription;
  StreamSubscription<Message>? _messageSubscription;

  Threads({
    required UserSubscriptions userSubscriptions,
    required CustomLogger logger,
  }) : _userSubscriptions = userSubscriptions,
       _logger = logger.scope('threads') {
    _statusSubscription = messages$.status
        .distinct((a, b) => a.runtimeType == b.runtimeType)
        .listen((status) {
          _statusSubject.add(status);
          _logger.d("Thread stats $status");
          if (status is StreamStatusQueryComplete) {
            _logger.d('Threads query complete');
          }
        });
    _messageSubscription = messages$.replayStream.listen(processMessage);
  }

  Future<void> stop() => _logger.span('stop', () async {
    for (final thread in threads.values) {
      await thread.close();
    }
    threads.clear();
    _seenIds.clear();
  });

  /// Fully resets messaging state, clearing both in-memory threads and
  /// the persisted [HydratedCubit] storage. Call on sign-out so a
  /// subsequent login starts with a clean slate.
  Future<void> reset() => _logger.span('reset', () async {
    await stop();
    _seenIds.clear();
    _state = const [];
    _statusSubject.add(StreamStatusIdle());
  });

  /// Waits for a message with the specified ID to be received.
  /// Listens to the replay subject which captures all messages.
  Future<Message> awaitMessageId(String expectedId) =>
      _logger.span('awaitMessageId', () async {
        _logger.d('Awaiting message with id $expectedId');
        return messages$.replayStream.firstWhere(
          (message) => message.id == expectedId,
        );
      });

  static List<String> normalizeParticipants(Iterable<String> participants) =>
      (participants.where((p) => p.isNotEmpty).toSet().toList()..sort());

  static String conversationIdentifier(
    Iterable<String> participants, {
    String conversationTag = '',
  }) {
    final preimage = jsonEncode([
      normalizeParticipants(participants),
      conversationTag.trim(),
    ]);
    return crypto.sha256.convert(utf8.encode(preimage)).toString();
  }

  static String threadIdentifierForMessage(Message message) =>
      conversationIdentifier([
        message.pubKey,
        ...message.pTags,
      ], conversationTag: message.getFirstTag(kConversationTag) ?? '');

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
    if (created) threadController.add(thread);
    return thread;
  }

  List<Thread> findByConversationTag(String tag) =>
      threads.values.where((t) => t.conversationTag == tag.trim()).toList();

  String? findPreferredConversationIdByTradeId(String tradeId) {
    final matches = findByConversationTag(tradeId);
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final c = a.participantCount.compareTo(b.participantCount);
      return c != 0
          ? c
          : b.lastActivityTimestamp.compareTo(a.lastActivityTimestamp);
    });
    return matches.first.anchor;
  }

  Thread? findPreferredThreadByTradeId(String tradeId) {
    final anchor = findPreferredConversationIdByTradeId(tradeId);
    return anchor != null ? threads[anchor] : null;
  }

  void processMessage(
    Message message,
  ) => _logger.spanSync('processMessage', () {
    _logger.d(
      'Received message ${message.id}, content: ${message.content.runtimeType}',
    );
    if (!_seenIds.add(message.id)) return;

    final thread = ensureConversation(
      participants: [message.pubKey, ...message.pTags],
      conversationTag: message.getFirstTag(kConversationTag) ?? '',
    );
    thread.messages.add(message);

    // Insert in sorted order (by createdAt) instead of copying + re-sorting
    // the entire list on every message.
    final list = [...state];
    var lo = 0;
    var hi = list.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (list[mid].createdAt <= message.createdAt) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    list.insert(lo, message);
    _state = List.unmodifiable(list);
  });

  /// Get the most recent timestamp from all cached threads.
  /// Returns null if no messages cached.
  int? getMostRecentTimestamp() =>
      _logger.spanSync('getMostRecentTimestamp', () {
        int? maxTimestamp;
        for (final message in state) {
          if (maxTimestamp == null || message.createdAt > maxTimestamp) {
            maxTimestamp = message.createdAt;
          }
        }
        return maxTimestamp;
      });

  Future<void> close() => _logger.span('close', () async {
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    await stop();
    for (final thread in threads.values) {
      await thread.close();
    }
    threads.clear();
    _seenIds.clear();
    await threadController.close();
    await _statusSubject.close();
  });
}
