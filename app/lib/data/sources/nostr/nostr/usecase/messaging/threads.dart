import 'dart:async';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event, Ndk, Filter, GiftWrap;
import 'package:rxdart/rxdart.dart';

import '../requests/requests.dart';
import 'messaging.dart';
import 'thread.dart';

class ThreadsSyncStatus {
  final bool syncing;
  final List<Thread> threads;

  ThreadsSyncStatus({required this.syncing, required this.threads});
}

class Threads {
  final Messaging messaging;
  final Requests requests;
  final Ndk ndk;
  final List<Message> messages = [];
  final Map<String, Thread> threads = {};
  StreamController<List<Thread>> outputStreamController =
      StreamController<List<Thread>>();
  Stream<List<Thread>> get outputStream => outputStreamController.stream;

  StreamController<ThreadsSyncStatus> syncStatusController =
      StreamController<ThreadsSyncStatus>.broadcast();
  Stream<ThreadsSyncStatus> get syncStatusStream => syncStatusController.stream;

  ReplaySubject<Message> _messageReplaySubject = ReplaySubject<Message>();
  Stream<Message> get messageStream => _messageReplaySubject.stream;

  StreamSubscription<Message>? _subscription;
  bool _isSyncing = false;

  Threads(this.messaging, this.requests, this.ndk);

  void populateMessages(List<Message> newMessages) {
    for (final message in newMessages) {
      processMessage(message);
    }
  }

  void sync() {
    _subscription?.cancel();
    _isSyncing = true;
    _emitSyncStatus();

    final myPubkey = ndk.accounts.getPublicKey();
    if (myPubkey == null) {
      throw Exception('No active account found for subscribing to gift-wraps.');
    }
    final filter = Filter(
      kinds: [GiftWrap.kGiftWrapEventkind],
      pTags: [myPubkey],
      since: getMostRecentTimestamp(),
    );
    print(
      'Subscribing to message gift-wraps with filter: $filter since ${getMostRecentTimestamp()}',
    );
    _subscription = requests
        .subscribe<Message>(filter: filter)
        .listen(
          processMessage,
          onDone: () {
            _isSyncing = false;
            _emitSyncStatus();
          },
        );

    // Mark syncing as complete after a reasonable timeout
    Future.delayed(const Duration(seconds: 2), () {
      if (_isSyncing) {
        _isSyncing = false;
        _emitSyncStatus();
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _isSyncing = false;
    _emitSyncStatus();
  }

  void _emitSyncStatus() {
    syncStatusController.add(
      ThreadsSyncStatus(syncing: _isSyncing, threads: threads.values.toList()),
    );
  }

  bool get isSyncing => _isSyncing;

  /// Waits for a message with the specified ID to be received.
  /// Listens to the replay subject which captures all messages.
  Future<Message> awaitId(String expectedId) {
    return _messageReplaySubject.firstWhere(
      (message) => message.id == expectedId,
    );
  }

  void processMessage(Message message) {
    _messageReplaySubject.add(message);
    String? id = extractAnchorThreadId(message);
    if (id == null) {
      return;
    }
    if (threads[id] == null) {
      threads[id] = Thread(id, messaging: messaging, accounts: ndk.accounts);
      outputStreamController.add(threads.values.toList());
    }
    threads[id]!.addMessage(message);
  }

  /// Get the most recent timestamp from all cached threads.
  /// Returns null if no messages cached.
  int? getMostRecentTimestamp() {
    int? maxTimestamp;
    for (final message in messages) {
      if (maxTimestamp == null || message.createdAt > maxTimestamp) {
        maxTimestamp = message.createdAt;
      }
    }
    return maxTimestamp;
  }
}

String? extractAnchorThreadId(Nip01Event event) {
  final tags = event.tags;
  for (final tag in tags) {
    if (tag.isNotEmpty && tag[0] == 'a' && tag.length > 1) {
      return tag[1];
    }
  }
  return null;
}
