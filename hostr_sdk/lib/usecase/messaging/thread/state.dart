import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:models/main.dart';

class ThreadSubscriptionState {
  final StreamStatus paymentStreamStatus;
  final List<PaymentEvent> paymentEvents;
  final StreamStatus reservationStreamStatus;
  final List<Reservation> reservations;
  final List<Reservation> allListingReservations;
  final StreamStatus allListingReservationsStreamStatus;

  const ThreadSubscriptionState({
    required this.paymentStreamStatus,
    required this.paymentEvents,
    required this.reservationStreamStatus,
    required this.reservations,
    required this.allListingReservations,
    required this.allListingReservationsStreamStatus,
  });

  factory ThreadSubscriptionState.initial() {
    return ThreadSubscriptionState(
      paymentStreamStatus: StreamStatusIdle(),
      paymentEvents: [],
      reservationStreamStatus: StreamStatusIdle(),
      reservations: [],
      allListingReservations: [],
      allListingReservationsStreamStatus: StreamStatusIdle(),
    );
  }

  ThreadSubscriptionState copyWith({
    StreamStatus? paymentStreamStatus,
    List<PaymentEvent>? paymentEvents,
    StreamStatus? reservationStreamStatus,
    List<Reservation>? reservations,
    List<Reservation>? allListingReservations,
    StreamStatus? allListingReservationsStreamStatus,
  }) {
    return ThreadSubscriptionState(
      paymentStreamStatus: paymentStreamStatus ?? this.paymentStreamStatus,
      paymentEvents: paymentEvents ?? this.paymentEvents,
      reservationStreamStatus:
          reservationStreamStatus ?? this.reservationStreamStatus,
      reservations: reservations ?? this.reservations,
      allListingReservations:
          allListingReservations ?? this.allListingReservations,
      allListingReservationsStreamStatus:
          allListingReservationsStreamStatus ??
          this.allListingReservationsStreamStatus,
    );
  }
}

class ThreadState {
  final String ourPubkey;
  final String anchor;
  final String tradeId;
  final String? salt;
  final List<Message> messages;
  final ThreadSubscriptionState subscriptions;
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

  List<Message<Event>> get reservationRequests =>
      messages.where((message) => message.child is ReservationRequest).toList();

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
    final messagesList = [...reservationRequests, ...textMessages]
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
    required this.tradeId,
    required this.salt,
    required this.messages,
    required this.counterpartyPubkeys,
    required this.subscriptions,
  });

  factory ThreadState.initial({
    required String ourPubkey,
    required String anchor,
    required String tradeId,
  }) {
    return ThreadState(
      ourPubkey: ourPubkey,
      anchor: anchor,
      tradeId: tradeId,
      salt: null,
      messages: const [],
      counterpartyPubkeys: [],
      subscriptions: ThreadSubscriptionState.initial(),
    );
  }

  Message? get latestMessageOrReservationRequest {
    final messagesList = [...reservationRequests, ...textMessages]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (messagesList.isEmpty) return null;
    return messagesList.reduce((a, b) => a.createdAt > b.createdAt ? a : b);
  }

  ThreadState copyWith({
    String? salt,
    List<Message>? messages,
    ThreadSubscriptionState? subscriptions,
    List<String>? counterpartyPubkeys,
  }) {
    return ThreadState(
      ourPubkey: ourPubkey,
      anchor: anchor,
      tradeId: tradeId,
      salt: salt ?? this.salt,
      messages: messages ?? this.messages,
      subscriptions: subscriptions ?? this.subscriptions,
      counterpartyPubkeys: counterpartyPubkeys ?? this.counterpartyPubkeys,
    );
  }
}
