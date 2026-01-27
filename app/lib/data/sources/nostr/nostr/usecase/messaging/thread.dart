import 'dart:async';

import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_response.dart';
import 'package:ndk/ndk.dart' show Nip01Event;

import './messaging.dart';

class Thread {
  Thread(this.id, this.messaging);
  final String id;
  final Messaging messaging;
  final List<Message> messages = [];
  final StreamController<List<Message>> _messagesStreamController =
      StreamController<List<Message>>();
  Stream<List<Message>> get outputStream => _messagesStreamController.stream;

  String get counterpartPubkey => id.split(':')[1];

  void addMessage(Message message) {
    messages.add(message);
    _messagesStreamController.add(List<Message>.unmodifiable(messages));
  }

  Future<List<NdkBroadcastResponse>> replyText(String content) {
    return messaging.broadcastMessage(
      content: content,
      tags: [
        ['a', id],
      ],
      recipientPubkey: counterpartPubkey,
    );
  }

  Future<List<NdkBroadcastResponse>> replyEvent<T extends Nip01Event>(
    T event, {
    List<List<String>> tags = const [],
  }) {
    return messaging.broadcastEvent(
      event: event,
      tags: [
        ['a', id],
        ...tags,
      ],
      recipientPubkey: counterpartPubkey,
    );
  }
}
