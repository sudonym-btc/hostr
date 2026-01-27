import 'dart:async';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event, Ndk, Filter, GiftWrap;

import '../requests/requests.dart';
import 'messaging.dart';
import 'thread.dart';

class Threads {
  final Messaging messaging;
  final Requests requests;
  final Ndk ndk;
  final List<Message> messages = [];
  final Map<String, Thread> threads = {};
  StreamController<List<Thread>> outputStreamController =
      StreamController<List<Thread>>();
  Stream<List<Thread>> get outputStream => outputStreamController.stream;
  StreamSubscription<Message>? _subscription;
  Threads(this.messaging, this.requests, this.ndk);

  void populateMessages(List<Message> newMessages) {
    for (final message in newMessages) {
      processMessage(message);
    }
  }

  void sync() {
    _subscription?.cancel();
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
        .listen(processMessage);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void processMessage(Message message) {
    String? id = extractAnchorThreadId(message);
    if (id == null) {
      return;
    }
    if (threads[id] == null) {
      threads[id] = Thread(id, messaging);
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
