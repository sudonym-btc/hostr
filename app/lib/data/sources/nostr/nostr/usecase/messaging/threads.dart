import 'dart:async';

import 'package:hostr/core/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Ndk, Filter, GiftWrap, Nip01EventModel;
import 'package:rxdart/rxdart.dart';

import '../requests/requests.dart';
import 'messaging.dart';
import 'thread.dart';

class Threads extends HydratedCubit<List<Message>> {
  final CustomLogger logger = CustomLogger();
  final Messaging messaging;
  final Requests requests;
  final Ndk ndk;

  final StreamController<Thread> threadController = StreamController<Thread>();
  Stream<Thread> get threadStream => threadController.stream;

  final BehaviorSubject<SubscriptionStatus> _statusSubject =
      BehaviorSubject<SubscriptionStatus>.seeded(SubscriptionStatusIdle());
  Stream<SubscriptionStatus> get status => _statusSubject.stream;

  final Map<String, Thread> threads = {};

  SubscriptionResponse<Message>? subscription;
  StreamSubscription<SubscriptionStatus>? _statusSubscription;
  StreamSubscription<Message>? _messageSubscription;

  Threads(this.messaging, this.requests, this.ndk) : super([]);

  void sync() {
    _closeSubscription();
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
    subscription = requests.subscribe<Message>(filter: filter);
    _statusSubscription?.cancel();
    _statusSubscription = subscription!.status.listen((status) {
      _statusSubject.add(status);
      logger.d("Thread stats $status");
      if (status is SubscriptionStatusQueryComplete) {
        logger.d('Threads query complete');
      }
    });
    _messageSubscription?.cancel();
    _messageSubscription = subscription!.stream.listen(processMessage);
  }

  void stop() {
    _closeSubscription();
  }

  void _closeSubscription() {
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _messageSubscription?.cancel();
    _messageSubscription = null;
    subscription?.close();
  }

  /// Waits for a message with the specified ID to be received.
  /// Listens to the replay subject which captures all messages.
  Future<Message> awaitMessageId(String expectedId) {
    logger.d('Awaiting message with id $expectedId');
    return subscription!.replay.firstWhere(
      (message) => message.id == expectedId,
    );
  }

  void processMessage(Message message) {
    logger.d('Received message with id ${message.id} $message');
    if (state.any((existing) => existing.id == message.id)) {
      return;
    }

    String? id = message.threadAnchor;

    if (threads[id] == null) {
      threads[id] = Thread(id, messaging: messaging, accounts: ndk.accounts);
      threadController.add(threads[id]!);
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
    logger.d('Rebuilding threads from ${messages.length} messages');
    for (final message in messages) {
      processMessage(message);
    }
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
    // @todo are the right close methods called here?
    stop();
    await _statusSubject.close();
    return super.close();
  }
}
