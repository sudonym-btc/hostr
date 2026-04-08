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
  final StreamWithStatus<Message> messages = StreamWithStatus<Message>();
  String conversationTag = '';

  bool _isTradeCandidate(ThreadState current) => current.messages.any(
    (message) =>
        message.child is Reservation &&
        (message.child as Reservation).isNegotiation,
  );

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
      messages.stream.listen((_) {
        _emitState();
      }),
    );
    _stateSubscriptions.add(
      _userSubscriptions.latestHeartbeats$.itemsStream.listen((_) {
        _emitState();
      }),
    );
  }

  void _emitState() => _logger.spanSync('_emitState', () {
    if (state.isClosed) return;
    final keyPair = _auth.activeKeyPair;
    if (keyPair == null) return;
    final nextMessages = messages.items;
    final nextParticipantPubkeys = <String>{
      for (final message in nextMessages) ...message.pTags,
      for (final message in nextMessages) message.pubKey,
    }.toList();

    state.add(
      state.value.copyWith(
        messages: nextMessages,
        counterpartyPubkeys: nextParticipantPubkeys
            .where((pubkey) => pubkey != keyPair.publicKey)
            .toList(),
        received: _computeReceived(
          messages: nextMessages,
          counterpartyPubkeys: nextParticipantPubkeys
              .where((pubkey) => pubkey != keyPair.publicKey)
              .toList(),
        ),
      ),
    );
  });

  bool _computeReceived({
    required List<Message> messages,
    required List<String> counterpartyPubkeys,
  }) {
    if (messages.isEmpty || counterpartyPubkeys.isEmpty) {
      return false;
    }

    final latestMessageCreatedAt = messages
        .map((message) => message.createdAt)
        .reduce((a, b) => a > b ? a : b);
    final latestHeartbeats = {
      for (final heartbeat in _userSubscriptions.latestHeartbeats$.items)
        heartbeat.pubKey: heartbeat,
    };

    return counterpartyPubkeys.every((pubkey) {
      final heartbeat = latestHeartbeats[pubkey];
      return heartbeat != null && heartbeat.createdAt >= latestMessageCreatedAt;
    });
  }

  List<String> addedParticipants = [];

  String? get tradeId {
    if (conversationTag.isNotEmpty) return conversationTag;
    for (final m in state.value.messages.reversed) {
      if (m.child is Reservation) {
        final id = (m.child as Reservation).getDtag();
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

  int get lastActivityTimestamp => messages.items.isEmpty
      ? 0
      : messages.items.map((m) => m.createdAt).reduce((a, b) => a > b ? a : b);

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

  Future<Message> replyTextAndWait(String content) =>
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

  Future<void> close() => _logger.span('close', () async {
    for (final s in _stateSubscriptions) {
      await s.cancel();
    }
    await state.close();
    await messages.close();
  });
}
