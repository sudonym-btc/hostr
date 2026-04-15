import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Nip01Event;
import 'package:rxdart/rxdart.dart';

import '../../../util/custom_logger.dart';
import '../../../util/stream_status.dart';
import '../../auth/auth.dart';
import '../../user_subscriptions/user_subscriptions.dart';
import '../messaging.dart';
import 'state.dart';

@Injectable()
class Thread {
  final CustomLogger _logger;
  final Messaging _messaging;
  final Auth _auth;
  final UserSubscriptions _userSubscriptions;
  final BehaviorSubject<ThreadState> state;
  final List<StreamSubscription> _stateSubscriptions = [];

  final String anchor;

  final StreamWithStatus<Nip01Event> events = StreamWithStatus<Nip01Event>();

  /// Participants derived from the Message envelopes at routing time.
  /// Populated by [addRoutingParticipants] called from [Threads].
  final Set<String> _knownParticipants = {};

  String conversationTag = '';
  final Map<String, int> _seenUntil = {};
  Timer? _seenReceiptDebounce;

  bool _isTradeCandidate(ThreadState current) =>
      current.events.any((e) => e is Reservation);

  bool get isTradeCandidate =>
      conversationTag.isNotEmpty || _isTradeCandidate(state.value);

  Thread(
    @factoryParam this.anchor, {
    required CustomLogger logger,
    required Auth auth,
    required Messaging messaging,
    required UserSubscriptions userSubscriptions,
  }) : _auth = auth,
       _messaging = messaging,
       _userSubscriptions = userSubscriptions,
       _logger = logger.scope('thread'),
       state = BehaviorSubject<ThreadState>.seeded(
         ThreadState.initial(
           ourPubkey: auth.activeKeyPair!.publicKey,
           anchor: anchor,
         ),
       ) {
    _stateSubscriptions.add(
      events.stream.listen((event) {
        if (event is SeenStatus) _processSeenReceipt(event);
        _emitState();
      }),
    );
    _stateSubscriptions.add(
      _userSubscriptions.latestHeartbeats$.itemsStream.listen((_) {
        _emitState();
      }),
    );
  }

  /// Record participants derived from the DM envelope at routing time.
  void addRoutingParticipants(Iterable<String> pubkeys) {
    _knownParticipants.addAll(pubkeys.where((p) => p.isNotEmpty));
  }

  /// Single entry point for all thread events.
  void process(Nip01Event event) {
    events.add(event);
  }

  void _processSeenReceipt(SeenStatus status) {
    final pubkey = status.pubKey;
    final timestamp = status.seenUntil;
    if (timestamp == null || pubkey.isEmpty) return;

    final existing = _seenUntil[pubkey] ?? 0;
    if (timestamp > existing) {
      _seenUntil[pubkey] = timestamp;
      _emitState();
    }
  }

  void _emitState() => _logger.spanSync('_emitState', () {
    if (state.isClosed) return;
    final keyPair = _auth.activeKeyPair;
    if (keyPair == null) return;
    final nextEvents = events.items.whereType<Event>().toList();
    final nextParticipantPubkeys = <String>{
      ..._knownParticipants,
      ...addedParticipants,
    }.toList();

    state.add(
      state.value.copyWith(
        events: nextEvents,
        participantPubkeys: _knownParticipants.toList(),
        counterpartyPubkeys: nextParticipantPubkeys
            .where((pubkey) => pubkey != keyPair.publicKey)
            .toList(),
        received: _computeReceived(
          events: nextEvents,
          counterpartyPubkeys: nextParticipantPubkeys
              .where((pubkey) => pubkey != keyPair.publicKey)
              .toList(),
        ),
        seenUntil: Map.unmodifiable(_seenUntil),
      ),
    );
  });

  bool _computeReceived({
    required List<Event> events,
    required List<String> counterpartyPubkeys,
  }) {
    if (events.isEmpty || counterpartyPubkeys.isEmpty) {
      return false;
    }

    final latestCreatedAt = events
        .map((e) => e.createdAt)
        .reduce((a, b) => a > b ? a : b);
    final latestHeartbeats = {
      for (final heartbeat in _userSubscriptions.latestHeartbeats$.items)
        heartbeat.pubKey: heartbeat,
    };

    return counterpartyPubkeys.every((pubkey) {
      final heartbeat = latestHeartbeats[pubkey];
      return heartbeat != null && heartbeat.createdAt >= latestCreatedAt;
    });
  }

  List<String> addedParticipants = [];

  String? get tradeId {
    if (conversationTag.isNotEmpty) return conversationTag;
    for (final e in state.value.events.reversed) {
      if (e is Reservation) {
        final id = e.getDtag();
        if (id != null && id.isNotEmpty) return id;
      }
    }
    return null;
  }

  int get participantCount => {
    _auth.getActiveKey().publicKey,
    ...state.value.participantPubkeys,
    ...addedParticipants,
  }.where((p) => p.isNotEmpty).length;

  int get lastActivityTimestamp {
    final readable = state.value.readableEvents;
    if (readable.isNotEmpty) {
      return readable.map((e) => e.createdAt).reduce((a, b) => a > b ? a : b);
    }
    final items = events.items;
    if (items.isEmpty) return 0;
    return items.map((e) => e.createdAt).reduce((a, b) => a > b ? a : b);
  }

  void configureConversation({
    required String conversationTag,
    Iterable<String> participants = const [],
  }) {
    this.conversationTag = conversationTag;
    final myPubkey = _auth.getActiveKey().publicKey;
    for (final pubkey in participants.toSet()) {
      if (pubkey.isNotEmpty &&
          pubkey != myPubkey &&
          !addedParticipants.contains(pubkey)) {
        addedParticipants.add(pubkey);
      }
    }
  }

  List<String> get _recipientPubkeys {
    final myPubkey = _auth.getActiveKey().publicKey;
    final recipients = <String>{
      ...state.value.counterpartyPubkeys,
      ...addedParticipants,
    }..removeWhere((pubkey) => pubkey.isEmpty || pubkey == myPubkey);
    final sorted = recipients.toList()..sort();
    return sorted;
  }

  List<List<String>> get _conversationTags => conversationTag.isEmpty
      ? const []
      : [
          [kConversationTag, conversationTag],
        ];

  Future<List<Future<List<RelayBroadcastResponse>>>> replyText(
    String content,
  ) => _logger.span('replyText', () async {
    return _messaging.broadcastText(
      content: content.trim(),
      tags: _conversationTags,
      recipientPubkeys: _recipientPubkeys,
    );
  });

  Future<Nip01Event> replyTextAndWait(String content) =>
      _logger.span('replyTextAndWait', () async {
        return _messaging.broadcastTextAndAwait(
          content: content.trim(),
          tags: _conversationTags,
          recipientPubkeys: _recipientPubkeys,
        );
      });

  Future<List<Future<List<RelayBroadcastResponse>>>>
  replyEvent<T extends Nip01Event>(
    T event, {
    List<List<String>> tags = const [],
  }) => _logger.span('replyEvent', () async {
    return _messaging.broadcastEvent(
      event: event,
      tags: [..._conversationTags, ...tags],
      recipientPubkeys: _recipientPubkeys,
    );
  });

  Future<void> broadcastSeenReceipt<T extends Nip01Event>() =>
      _logger.span('broadcastSeenReceipt', () async {
        return _messaging.broadcastSeenReceipt(
          seenUntil: state.value.sortedEvents.last.createdAt,
          tags: [..._conversationTags],
          recipientPubkeys: _knownParticipants.toList(),
        );
      });

  /// Mark this conversation as read. Debounces by 1 second to avoid
  /// sending receipts for accidental taps.
  void markAsRead() {
    _seenReceiptDebounce?.cancel();
    _seenReceiptDebounce = Timer(
      const Duration(seconds: 1),
      () => _sendSeenReceipt(),
    );
  }

  Future<void> _sendSeenReceipt() => _logger.span('_sendSeenReceipt', () async {
    if (!state.value.shouldSendReceipt) return;
    if (_recipientPubkeys.isEmpty) return;

    final sorted = state.value.sortedEvents;
    if (sorted.isEmpty) return;

    await broadcastSeenReceipt();
  });

  Future<void> close() => _logger.span('close', () async {
    _seenReceiptDebounce?.cancel();
    for (final s in _stateSubscriptions) {
      await s.cancel();
    }
    await state.close();
    await events.close();
  });
}
