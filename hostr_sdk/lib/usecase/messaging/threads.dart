import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, GiftWrap, Nip01EventModel;
import 'package:rxdart/rxdart.dart';

import '../../util/main.dart';
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

  final StreamController<Thread> threadController = StreamController<Thread>();
  Stream<Thread> get threadStream => threadController.stream;

  final BehaviorSubject<StreamStatus> _statusSubject =
      BehaviorSubject<StreamStatus>.seeded(StreamStatusIdle());
  Stream<StreamStatus> get status => _statusSubject.stream;

  final Map<String, Thread> threads = {};

  StreamWithStatus<Message>? subscription;
  StreamSubscription<StreamStatus>? _statusSubscription;
  StreamSubscription<Message>? _messageSubscription;

  Threads({
    required this.messaging,
    required this.requests,
    required this.auth,
    required this.logger,
    required this.payments,
  }) : super([]);

  void sync() {
    _closeSubscription();
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
    subscription = requests.subscribe<Message>(filter: filter);
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
  }

  Future<List<Message>> refresh() async {
    sync();
    if (subscription == null) return [];
    List<Message> newMessages = await subscription!.stream
        .takeUntil(subscription!.status.whereType<StreamStatusQueryComplete>())
        .toList();
    stop();
    return newMessages;
  }

  void stop() {
    _closeSubscription();
    for (final thread in threads.values) {
      thread.close();
    }
    threads.clear();
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

  void processMessage(Message message) {
    logger.d('Received message with id ${message.id} $message');
    if (state.any((existing) => existing.id == message.id)) {
      return;
    }

    String? id = threadIdentifierForMessage(message);

    if (threads[id] == null) {
      threads[id] = getIt<Thread>(param1: id);
      threadController.add(threads[id]!);
    }
    threads[id]!.messages.add(message);
    emit(
      [...state, message].toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
    );
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
    for (final thread in threads.values) {
      await thread.close();
    }
    threads.clear();
    await threadController.close();
    await _statusSubject.close();
    return super.close();
  }
}
