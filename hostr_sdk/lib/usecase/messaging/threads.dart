import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, GiftWrap, Nip01EventModel;
import 'package:rxdart/rxdart.dart';

import '../../injection.dart';
import '../../util/main.dart';
import '../auth/auth.dart';
import '../payments/payments.dart';
import '../requests/requests.dart';
import 'messaging.dart';
import 'thread.dart';

@Singleton()
class Threads extends HydratedCubit<List<Message>> {
  final CustomLogger logger;
  final Messaging messaging;
  final Requests requests;
  final Payments payments;
  final Auth auth;

  final StreamController<Thread> threadController =
      StreamController<Thread>.broadcast();
  Stream<Thread> get threadStream => threadController.stream;

  final BehaviorSubject<StreamStatus> _statusSubject =
      BehaviorSubject<StreamStatus>.seeded(StreamStatusIdle());
  Stream<StreamStatus> get status => _statusSubject.stream;

  final Map<String, Thread> threads = {};

  /// O(1) duplicate guard — tracks every message id we have already ingested.
  final Set<String> _seenIds = {};

  StreamWithStatus<Message>? subscription;
  StreamSubscription<StreamStatus>? _statusSubscription;
  StreamSubscription<Message>? _messageSubscription;

  Threads({
    required this.messaging,
    required this.requests,
    required this.auth,
    required CustomLogger logger,
    required this.payments,
  }) : logger = logger.scope('threads'),
       super([]);

  Future<void> sync() => logger.span('sync', () async {
    await _closeSubscription();
    _rebuildThreadsFromMessages(state);

    if (auth.activeKeyPair == null) {
      logger.d('Skipping thread sync — no active key pair');
      return;
    }

    final myPubkey = auth.getActiveKey().publicKey;
    final filter = Filter(
      kinds: [GiftWrap.kGiftWrapEventkind],
      pTags: [myPubkey],
      since: getMostRecentTimestamp(),
    );
    logger.d(
      'Subscribing to message gift-wraps with filter: $filter since ${getMostRecentTimestamp()}',
    );
    subscription = requests.subscribe<Message>(
      name: 'Threads-subscription',
      filter: filter,
    );
    _statusSubscription?.cancel();
    _statusSubscription = subscription!.status.listen((status) {
      _statusSubject.add(status);
      logger.d("Thread stats $status");
      if (status is StreamStatusQueryComplete) {
        logger.d('Threads query complete');
      }
    });
    _messageSubscription?.cancel();
    _messageSubscription = subscription!.stream.listen(processMessage);
  });

  Future<List<Message>> refresh() => logger.span('refresh', () async {
    sync();
    if (subscription == null) return [];
    List<Message> newMessages = await subscription!.stream
        .takeUntil(subscription!.status.whereType<StreamStatusQueryComplete>())
        .toList();
    stop();
    return newMessages;
  });

  Future<void> stop() => logger.span('stop', () async {
    await _closeSubscription();
    for (final thread in threads.values) {
      await thread.close();
    }
    threads.clear();
    _seenIds.clear();
  });

  /// Fully resets messaging state, clearing both in-memory threads and
  /// the persisted [HydratedCubit] storage. Call on sign-out so a
  /// subsequent login starts with a clean slate.
  Future<void> reset() => logger.span('reset', () async {
    await stop();
    _seenIds.clear();
    emit([]);
    await clear();
  });

  Future<void> _closeSubscription() =>
      logger.span('_closeSubscription', () async {
        await _statusSubscription?.cancel();
        _statusSubscription = null;
        await _messageSubscription?.cancel();
        _messageSubscription = null;
        await subscription?.close();
      });

  /// Waits for a message with the specified ID to be received.
  /// Listens to the replay subject which captures all messages.
  Future<Message> awaitMessageId(String expectedId) =>
      logger.span('awaitMessageId', () async {
        logger.d('Awaiting message with id $expectedId');
        return subscription!.replay.firstWhere(
          (message) => message.id == expectedId,
        );
      });

  // If DM'ing has nothing to do with reservation or a specific thread, we still want to keep it compatible with the same thread structure.
  // So we generate a thread ID based on the participants if no thread anchor is provided.
  static String threadIdentifierForMessage(Message message) {
    final sortedParticipants = <String>{
      ...message.pTags,
      message.pubKey,
    }.toList()..sort();
    return message.parsedTags.threadAnchor ??
        crypto.sha256
            .convert(utf8.encode(sortedParticipants.join(':')))
            .toString();
  }

  void processMessage(Message message) => logger.spanSync('processMessage', () {
    final id = threadIdentifierForMessage(message);
    logger.d(
      'Received message with id ${message.id} for thread $id, content: ${message.content.runtimeType}',
    );
    if (!_seenIds.add(message.id)) {
      return;
    }

    if (threads[id] == null) {
      threads[id] = getIt<Thread>(param1: id);
      threadController.add(threads[id]!);
    }
    threads[id]!.messages.add(message);

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
    emit(list);
  });

  /// Get the most recent timestamp from all cached threads.
  /// Returns null if no messages cached.
  int? getMostRecentTimestamp() =>
      logger.spanSync('getMostRecentTimestamp', () {
        int? maxTimestamp;
        for (final message in state) {
          if (maxTimestamp == null || message.createdAt > maxTimestamp) {
            maxTimestamp = message.createdAt;
          }
        }
        return maxTimestamp;
      });

  void _rebuildThreadsFromMessages(List<Message> messages) =>
      logger.spanSync('_rebuildThreadsFromMessages', () {
        threads.clear();
        _seenIds.clear();
        logger.d('Rebuilding threads from ${messages.length} messages');

        // Bulk ingest: route messages to threads in a single pass without
        // emitting intermediate state or re-sorting per message.
        for (final message in messages) {
          if (!_seenIds.add(message.id)) continue;

          final id = threadIdentifierForMessage(message);
          if (threads[id] == null) {
            threads[id] = getIt<Thread>(param1: id);
            threadController.add(threads[id]!);
          }
          threads[id]!.messages.add(message);
        }

        // Single sort + single emit for the entire batch.
        final sorted = List<Message>.of(messages)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        emit(sorted);
      });

  @override
  List<Message> fromJson(Map<String, dynamic> json) =>
      logger.spanSync('fromJson', () {
        final messages = json['messages'];
        if (messages is! List) {
          return <Message>[];
        }
        return messages.map((message) {
          final event = Nip01EventModel.fromJson(message);
          return Message.safeFromNostrEvent(event);
        }).toList();
      });

  @override
  Map<String, dynamic>? toJson(List<Message> state) => logger.spanSync(
    'toJson',
    () {
      return {'messages': state.map((message) => message.toString()).toList()};
    },
  );

  @override
  Future<void> close() => logger.span('close', () async {
    // @todo are the right close methods called here?
    await stop();
    for (final thread in threads.values) {
      await thread.close();
    }
    threads.clear();
    _seenIds.clear();
    await threadController.close();
    await _statusSubject.close();
    return super.close();
  });
}
