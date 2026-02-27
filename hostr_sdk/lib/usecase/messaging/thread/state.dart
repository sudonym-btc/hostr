import 'package:models/main.dart';

class ThreadState {
  final String ourPubkey;
  final String anchor;
  final List<Message> messages;
  final List<String> counterpartyPubkeys;

  /// Cached sorted copy of [messages], recomputed only when messages change.
  final List<Message> sortedMessages;

  /// Cached set of all pubkeys that appear in messages, recomputed only when messages change.
  final List<String> participantPubkeys;

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

  /// Messages whose child is a negotiate-stage [Reservation] (replaces the
  /// old `reservationRequestMessages` backed by `ReservationRequest`).
  List<Message> get reservationRequestMessages => messages
      .where(
        (message) =>
            message.child is Reservation &&
            (message.child as Reservation).parsedContent.isNegotiation,
      )
      .toList();

  /// Negotiate-stage [Reservation]s extracted from messages. This is the
  /// unified replacement for the old `List<ReservationRequest>` getter.
  List<Reservation> get reservationRequests => reservationRequestMessages
      .map((element) => element.child)
      .whereType<Reservation>()
      .toList();

  List<Message> get textMessages =>
      messages.where((message) => message.child == null).toList();

  static List<String> _computeParticipantPubkeys(List<Message> messages) {
    final pubkeys = <String>{};
    for (final msg in messages) {
      pubkeys.add(msg.pubKey);
      pubkeys.addAll(msg.pTags);
    }
    return pubkeys.toList();
  }

  /// The most recent negotiate-stage [Reservation] in the thread.
  Reservation get lastReservationRequest {
    return reservationRequests.last;
  }

  Message getLastMessageOrReservationRequest() {
    final latest = getLatestMessage;
    if (latest != null) return latest;

    final rr = reservationRequestMessages;
    if (rr.isNotEmpty) {
      return rr.last;
    }

    throw Exception('No messages or reservation requests found in thread');
  }

  static List<Message> _computeSortedMessages(List<Message> messages) {
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

  ThreadState({
    required this.ourPubkey,
    required this.anchor,
    required this.messages,
    required this.counterpartyPubkeys,
    List<Message>? sortedMessages,
    List<String>? participantPubkeys,
  }) : sortedMessages = sortedMessages ?? _computeSortedMessages(messages),
       participantPubkeys =
           participantPubkeys ?? _computeParticipantPubkeys(messages);

  factory ThreadState.initial({
    required String ourPubkey,
    required String anchor,
  }) {
    return ThreadState(
      ourPubkey: ourPubkey,
      anchor: anchor,
      messages: const [],
      counterpartyPubkeys: [],
      sortedMessages: const [],
      participantPubkeys: const [],
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
    final newMessages = messages ?? this.messages;
    final messagesChanged = !identical(newMessages, this.messages);
    return ThreadState(
      ourPubkey: ourPubkey,
      anchor: anchor,
      messages: newMessages,
      counterpartyPubkeys: counterpartyPubkeys ?? this.counterpartyPubkeys,
      sortedMessages: messagesChanged ? null : sortedMessages,
      participantPubkeys: messagesChanged ? null : participantPubkeys,
    );
  }
}
