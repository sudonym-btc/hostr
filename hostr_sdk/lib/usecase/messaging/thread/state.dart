import 'package:models/main.dart';

class ThreadState {
  final String ourPubkey;
  final String anchor;

  /// All non-receipt events in the thread: [Message] (plain text DMs),
  /// [Reservation], [EscrowServiceSelected]. SeenReceipts are handled
  /// separately via [seenUntil].
  final List<Event> events;

  final List<String> counterpartyPubkeys;
  final bool received;

  /// Maps pubkey → highest `seen_until` timestamp from their kind:16 receipts.
  final Map<String, int> seenUntil;

  /// Cached sorted copy of [events], recomputed only when events change.
  final List<Event> sortedEvents;

  /// Cached set of all pubkeys that appear in events.
  final List<String> participantPubkeys;

  // ── Readable events ──

  /// Events that contribute to read/unread state: plain-text [Message]s and
  /// reservation-proposal [Message]s (child is [Reservation]).
  /// Excludes [EscrowServiceSelected] children and [SeenStatus] events.
  List<Message> get readableEvents => events
      .whereType<Message>()
      .where((m) => m.child == null || m.child is Reservation)
      .toList();

  // ── Read status ──

  /// Have ALL counterparties read our latest sent readable message?
  bool get read {
    if (counterpartyPubkeys.isEmpty) return false;
    final ourLatest = readableEvents
        .where((e) => e.pubKey == ourPubkey)
        .map((e) => e.createdAt)
        .fold(0, (int a, int b) => a > b ? a : b);
    if (ourLatest == 0) return false;
    return counterpartyPubkeys.every((cp) => (seenUntil[cp] ?? 0) >= ourLatest);
  }

  /// How many readable events are unread for a given pubkey.
  int unreadCount(String pubkey) {
    final seen = seenUntil[pubkey] ?? 0;
    return readableEvents
        .where((e) => e.pubKey != pubkey && e.createdAt > seen)
        .length;
  }

  /// Whether there are counterparty readable events newer than our last seen receipt.
  bool get shouldSendReceipt {
    final ourSeen = seenUntil[ourPubkey] ?? 0;
    final latestCounterparty = readableEvents
        .where((e) => e.pubKey != ourPubkey)
        .map((e) => e.createdAt)
        .fold(0, (int a, int b) => a > b ? a : b);
    return latestCounterparty > ourSeen;
  }

  // ── Typed accessors ──

  List<EscrowServiceSelected> get selectedEscrows {
    Map<String, EscrowServiceSelected> mapper = {};
    for (final item in events.whereType<EscrowServiceSelected>()) {
      mapper[item.service.id] = item;
    }
    return mapper.values.toList();
  }

  List<Reservation> get reservationRequests => events
      .whereType<Message>()
      .map((e) => e.child)
      .whereType<Reservation>()
      .toList();

  List<Message> get textMessages => events
      .whereType<Message>()
      .where((element) => element.child == null)
      .toList();

  Reservation get lastReservationRequest => reservationRequests.last;

  Event? get getLatestEvent {
    if (sortedEvents.isEmpty) return null;
    return sortedEvents.last;
  }

  Event getLastEventOrReservationRequest() {
    final latest = getLatestEvent;
    if (latest != null) return latest;

    final rr = reservationRequests;
    if (rr.isNotEmpty) return rr.last;

    throw Exception('No events or reservation requests found in thread');
  }

  DateTime get getLastDateTime {
    final readable = readableEvents;
    final ts = readable.isNotEmpty
        ? readable.map((e) => e.createdAt).reduce((a, b) => a > b ? a : b)
        : getLatestEvent?.createdAt ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true);
  }

  bool get isLastMessageOurs {
    final latest = getLatestEvent;
    return latest?.pubKey == ourPubkey;
  }

  static List<Event> _computeSortedEvents(List<Event> events) {
    final evts = [...events];
    evts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return evts;
  }

  ThreadState({
    required this.ourPubkey,
    required this.anchor,
    required this.events,
    required this.counterpartyPubkeys,
    this.received = false,
    this.seenUntil = const {},
    List<Event>? sortedEvents,
    required this.participantPubkeys,
  }) : sortedEvents = sortedEvents ?? _computeSortedEvents(events);

  factory ThreadState.initial({
    required String ourPubkey,
    required String anchor,
  }) {
    return ThreadState(
      ourPubkey: ourPubkey,
      anchor: anchor,
      events: const [],
      counterpartyPubkeys: [],
      received: false,
      seenUntil: const {},
      sortedEvents: const [],
      participantPubkeys: const [],
    );
  }

  ThreadState copyWith({
    List<Event>? events,
    List<String>? participantPubkeys,
    List<String>? counterpartyPubkeys,
    bool? received,
    Map<String, int>? seenUntil,
  }) {
    final newEvents = events ?? this.events;
    final eventsChanged = !identical(newEvents, this.events);
    return ThreadState(
      ourPubkey: ourPubkey,
      anchor: anchor,
      events: newEvents,
      counterpartyPubkeys: counterpartyPubkeys ?? this.counterpartyPubkeys,
      received: received ?? this.received,
      seenUntil: seenUntil ?? this.seenUntil,
      sortedEvents: eventsChanged ? null : sortedEvents,
      participantPubkeys: participantPubkeys ?? this.participantPubkeys,
    );
  }
}
