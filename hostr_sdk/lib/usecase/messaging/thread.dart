import 'dart:async';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/messaging/thread_watcher.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Nip01Event;

@Injectable()
class Thread {
  final CustomLogger logger;
  final Messaging messaging;
  final Auth auth;
  ThreadWatcher? _watcher;
  Thread(
    @factoryParam this.anchor, {
    required this.logger,
    required this.auth,
    required this.messaging,
  });

  final String anchor;
  String get tradeId => getDTagFromAnchor(anchor);
  ThreadWatcher get watcher => _watcher ??= getIt<ThreadWatcher>(param1: this);
  final StreamWithStatus<Message> messages = StreamWithStatus<Message>();

  List<EscrowServiceSelected> get selectedEscrows {
    final items = messages.list.value
        .map((message) => message.child)
        .whereType<EscrowServiceSelected>()
        .toList();

    /// Deduplicate by escrow service ID, keeping the most recent selection for each service
    Map<String, EscrowServiceSelected> mapper = {};
    for (final item in items) {
      final key = item.parsedContent.service.id;
      mapper[key] = item;
    }

    return mapper.values.toList();
  }

  List<Message<Event>> get reservationRequests => messages.list.value
      .where((message) => message.child is ReservationRequest)
      .toList();

  List<Message> get textMessages =>
      messages.list.value.where((message) => message.child == null).toList();

  List<String> get participantPubkeys {
    final pubkeys = <String>{};
    for (final msg in messages.list.value) {
      pubkeys.add(msg.pubKey);
      pubkeys.addAll(msg.pTags);
    }
    return pubkeys.toList();
  }

  List<String> get counterpartyPubkeys {
    return participantPubkeys
        .where((pubkey) => pubkey != auth.activeKeyPair!.publicKey)
        .toList();
  }

  ReservationRequest get lastReservationRequest {
    return messages.list.value
        .where((element) => element.child is ReservationRequest)
        .map((element) => element.child as ReservationRequest)
        .last;
  }

  List<Message> get sortedMessages {
    final msgs = [...messages.list.value];
    msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return msgs;
  }

  Message? get getLatestMessage {
    final messagesList = [...reservationRequests, ...textMessages]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (messagesList.isEmpty) return null;
    return messagesList.reduce((a, b) => a.createdAt > b.createdAt ? a : b);
  }

  DateTime get getLastDateTime {
    final latest = getLatestMessage;
    return DateTime.fromMillisecondsSinceEpoch(latest!.createdAt * 1000);
  }

  Future<List<Future<List<RelayBroadcastResponse>>>> replyText(String content) {
    return messaging.broadcastText(
      content: content,
      tags: [
        [kThreadRefTag, anchor],
      ],
      recipientPubkeys: counterpartyPubkeys,
    );
  }

  Future<List<Future<List<RelayBroadcastResponse>>>> replyEvent<
    T extends Nip01Event
  >(T event, {List<List<String>> tags = const []}) {
    return messaging.broadcastEvent(
      event: event,
      tags: [
        [kThreadRefTag, anchor],
        ...tags,
      ],
      recipientPubkeys: counterpartyPubkeys,
    );
  }

  bool get isLastMessageOurs {
    final latest = getLatestMessage;
    final ours = auth.activeKeyPair!.publicKey;
    return latest?.pubKey == ours;
  }

  Message getLastMessageOrReservationRequest() {
    final latest = getLatestMessage;
    if (latest != null) return latest;

    final reservationRequests = messages.list.value
        .where((element) => element.child is ReservationRequest)
        .toList();
    if (reservationRequests.isNotEmpty) {
      return reservationRequests.last;
    }

    throw Exception('No messages or reservation requests found in thread');
  }

  Future<void> close() async {
    await _watcher?.close();
    _watcher = null;
    await messages.close();
  }
}
