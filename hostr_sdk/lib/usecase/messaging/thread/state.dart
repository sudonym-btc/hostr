import 'package:models/main.dart';

class ThreadState {
  final String ourPubkey;
  final String anchor;
  final List<Message> messages;
  final List<String> counterpartyPubkeys;

  List<EscrowServiceSelected> get selectedEscrows {
    final items = messages
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

  List<Message> get reservationRequestMessages =>
      messages.where((message) => message.child is ReservationRequest).toList();

  List<ReservationRequest> get reservationRequests => reservationRequestMessages
      .map((element) => element.child)
      .whereType<ReservationRequest>()
      .toList();

  List<Message> get textMessages =>
      messages.where((message) => message.child == null).toList();

  List<String> get participantPubkeys {
    final pubkeys = <String>{};
    for (final msg in messages) {
      pubkeys.add(msg.pubKey);
      pubkeys.addAll(msg.pTags);
    }
    return pubkeys.toList();
  }

  ReservationRequest get lastReservationRequest {
    return messages
        .where((element) => element.child is ReservationRequest)
        .map((element) => element.child as ReservationRequest)
        .last;
  }

  Message getLastMessageOrReservationRequest() {
    final latest = getLatestMessage;
    if (latest != null) return latest;

    final reservationRequests = messages
        .where((element) => element.child is ReservationRequest)
        .toList();
    if (reservationRequests.isNotEmpty) {
      return reservationRequests.last;
    }

    throw Exception('No messages or reservation requests found in thread');
  }

  List<Message> get sortedMessages {
    final msgs = [...messages];
    msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return msgs;
  }

  Message? get getLatestMessage {
    final messagesList = [...reservationRequestMessages, ...textMessages]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (messagesList.isEmpty) return null;
    return messagesList.reduce((a, b) => a.createdAt > b.createdAt ? a : b);
  }

  DateTime get getLastDateTime {
    final latest = getLatestMessage;
    return DateTime.fromMillisecondsSinceEpoch(latest!.createdAt * 1000);
  }

  bool get isLastMessageOurs {
    final latest = getLatestMessage;
    return latest?.pubKey == ourPubkey;
  }

  const ThreadState({
    required this.ourPubkey,
    required this.anchor,
    required this.messages,
    required this.counterpartyPubkeys,
  });

  factory ThreadState.initial({
    required String ourPubkey,
    required String anchor,
  }) {
    return ThreadState(
      ourPubkey: ourPubkey,
      anchor: anchor,
      messages: const [],
      counterpartyPubkeys: [],
    );
  }

  Message? get latestMessageOrReservationRequest {
    final messagesList = [...reservationRequestMessages, ...textMessages]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (messagesList.isEmpty) return null;
    return messagesList.reduce((a, b) => a.createdAt > b.createdAt ? a : b);
  }

  ThreadState copyWith({
    List<Message>? messages,
    List<String>? counterpartyPubkeys,
  }) {
    return ThreadState(
      ourPubkey: ourPubkey,
      anchor: anchor,
      messages: messages ?? this.messages,
      counterpartyPubkeys: counterpartyPubkeys ?? this.counterpartyPubkeys,
    );
  }
}
