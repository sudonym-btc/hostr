import 'dart:async';

import 'package:hostr/core/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Ndk, Filter, GiftWrap, Nip01EventModel;
import 'package:rxdart/rxdart.dart';

import '../requests/requests.dart';
import 'messaging.dart';
import 'thread.dart';

class ThreadsSyncStatus {
  final bool subscribed;
  final bool completed;
  final List<Thread> threads;

  ThreadsSyncStatus({
    required this.subscribed,
    required this.completed,
    required this.threads,
  });
}

class Threads extends HydratedCubit<List<Message>> {
  final CustomLogger logger = CustomLogger();
  final Messaging messaging;
  final Requests requests;
  final Ndk ndk;
  final Map<String, Thread> threads = {};

  StreamController<List<Thread>> outputStreamController =
      StreamController<List<Thread>>();
  Stream<List<Thread>> get outputStream => outputStreamController.stream;

  StreamController<ThreadsSyncStatus> syncStatusController =
      StreamController<ThreadsSyncStatus>.broadcast();
  Stream<ThreadsSyncStatus> get syncStatusStream => syncStatusController.stream;

  final ReplaySubject<Message> _messageReplaySubject = ReplaySubject<Message>();
  Stream<Message> get messageStream => _messageReplaySubject.stream;

  CustomNdkResponse<Message>? _subscription;
  StreamSubscription<Message>? _streamSubscription;
  bool get isSubscribed => _subscription != null;
  bool subscriptionCompleted = false;

  Threads(this.messaging, this.requests, this.ndk) : super([]);

  void sync() {
    _closeSubscription();
    subscriptionCompleted = false;
    _emitSyncStatus();

    _rebuildThreadsFromMessages(state);

    final myPubkey = ndk.accounts.getPublicKey();
    if (myPubkey == null) {
      throw Exception('No active account found for subscribing to gift-wraps.');
    }
    final filter = Filter(
      kinds: [GiftWrap.kGiftWrapEventkind],
      pTags: [myPubkey],
      since: getMostRecentTimestamp(),
    );
    logger.d(
      'Subscribing to message gift-wraps with filter: $filter since ${getMostRecentTimestamp()}',
    );
    _subscription = requests.subscribe<Message>(filter: filter);
    _subscription!.future.then((_) {
      logger.d('Threads query completed.');
      subscriptionCompleted = true;
      _emitSyncStatus();
    });

    _streamSubscription = _subscription!.stream.listen(processMessage);
  }

  void stop() {
    _closeSubscription();
    subscriptionCompleted = false;
    _emitSyncStatus();
  }

  void _closeSubscription() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    final subscriptionId = _subscription?.requestId;
    _subscription = null;
    subscriptionCompleted = false;
    if (subscriptionId == null) return;
    // Best-effort: close the underlying NDK subscription to free relay resources.
    ndk.requests.closeSubscription(subscriptionId);
  }

  void _emitSyncStatus() {
    syncStatusController.add(
      ThreadsSyncStatus(
        subscribed: _subscription != null,
        completed: subscriptionCompleted,
        threads: threads.values.toList(),
      ),
    );
  }

  /// Waits for a message with the specified ID to be received.
  /// Listens to the replay subject which captures all messages.
  Future<Message> awaitId(String expectedId) {
    logger.d('Awaiting message with id $expectedId');
    return _messageReplaySubject.firstWhere(
      (message) => message.id == expectedId,
    );
  }

  void processMessage(Message message) {
    _messageReplaySubject.add(message);
    logger.d('Received message with id ${message.id} ${message}');
    if (state.any((existing) => existing.id == message.id)) {
      return;
    }
    String? id = message.reservationRequestAnchor;
    if (id == null) {
      return;
    }
    if (threads[id] == null) {
      threads[id] = Thread(id, messaging: messaging, accounts: ndk.accounts);
      outputStreamController.add(threads.values.toList());
    }
    threads[id]!.addMessage(message);
    emit([...state, message]);
  }

  /// Get the most recent timestamp from all cached threads.
  /// Returns null if no messages cached.
  int? getMostRecentTimestamp() {
    int? maxTimestamp;
    for (final message in state) {
      if (maxTimestamp == null || message.createdAt > maxTimestamp) {
        maxTimestamp = message.createdAt;
      }
    }
    return maxTimestamp;
  }

  void _rebuildThreadsFromMessages(List<Message> messages) {
    threads.clear();
    for (final message in messages) {
      String? id = message.reservationRequestAnchor;
      if (id == null) {
        continue;
      }
      threads[id] ??= Thread(id, messaging: messaging, accounts: ndk.accounts);
      threads[id]!.addMessage(message);
    }
    outputStreamController.add(threads.values.toList());
  }

  @override
  List<Message> fromJson(Map<String, dynamic> json) {
    final messages = json['messages'];
    if (messages is! List) {
      return [];
    }
    return messages.map((message) {
      final event = Nip01EventModel.fromJson(message);
      return Message.safeFromNostrEvent(event);
    }).toList();
  }

  @override
  Map<String, dynamic>? toJson(List<Message> state) {
    return {'messages': state.map((message) => message.toString()).toList()};
  }

  @override
  Future<void> close() async {
    stop();
    await outputStreamController.close();
    await syncStatusController.close();
    await _messageReplaySubject.close();
    return super.close();
  }
}
