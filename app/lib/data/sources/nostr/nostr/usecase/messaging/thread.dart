import 'dart:async';

import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Nip01Event, Accounts;

import './messaging.dart';

class Thread {
  Thread(this.id, {required this.messaging, required this.accounts});
  final String id;
  final Messaging messaging;
  final Accounts accounts;
  final List<Message> messages = [];
  final StreamController<List<Message>> _messagesStreamController =
      StreamController<List<Message>>.broadcast();
  Stream<List<Message>> get outputStream => _messagesStreamController.stream;

  void addMessage(Message message) {
    messages.add(message);
    _messagesStreamController.add(List<Message>.unmodifiable(messages));
  }

  String counterpartyPubkey() {
    return accounts.getPublicKey() != messages[0].pubKey
        ? messages[0].pubKey
        : messages[0].pTags
              .where((tag) => tag != accounts.getPublicKey())
              .first;
  }

  Message? getLatestMessage() {
    if (messages.isEmpty) return null;
    return messages.reduce((a, b) => a.createdAt > b.createdAt ? a : b);
  }

  DateTime getLastDateTime() {
    final latest = messages.reduce((a, b) => a.createdAt > b.createdAt ? a : b);
    return DateTime.fromMillisecondsSinceEpoch(latest.createdAt * 1000);
  }

  Future<List<Future<List<RelayBroadcastResponse>>>> replyText(String content) {
    return messaging.broadcastMessage(
      content: content,
      tags: [
        ['a', id],
      ],
      recipientPubkey: counterpartyPubkey(),
    );
  }

  Future<List<Future<List<RelayBroadcastResponse>>>> replyEvent<
    T extends Nip01Event
  >(T event, {List<List<String>> tags = const []}) {
    return messaging.broadcastEvent(
      event: event,
      tags: [
        ['a', id],
        ...tags,
      ],
      recipientPubkey: counterpartyPubkey(),
    );
  }
}
