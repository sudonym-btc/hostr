import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Nip01Event;
import 'package:rxdart/rxdart.dart';

import '../../../util/custom_logger.dart';
import '../../../util/stream_status.dart';
import '../../auth/auth.dart';
import '../messaging.dart';
import 'state.dart';

@Injectable()
class Thread {
  final CustomLogger logger;
  final Messaging messaging;
  final Auth auth;
  final BehaviorSubject<ThreadState> state;
  final List<StreamSubscription> _stateSubscriptions = [];

  final String anchor;
  final StreamWithStatus<Message> messages = StreamWithStatus<Message>();

  bool _isTradeCandidate(ThreadState current) => current.messages.any(
    (message) =>
        message.child is Reservation &&
        (message.child as Reservation).isNegotiation,
  );

  bool get isTradeCandidate => _isTradeCandidate(state.value);

  Thread(
    @factoryParam this.anchor, {
    required CustomLogger logger,
    required this.auth,
    required this.messaging,
  }) : logger = logger.scope('thread'),
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
  }

  void _emitState() => logger.spanSync('_emitState', () {
    if (state.isClosed) return;
    final keyPair = auth.activeKeyPair;
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
      ),
    );
  });

  List<String> addedParticipants = [];

  Future<List<Future<List<RelayBroadcastResponse>>>> replyText(
    String content,
  ) => logger.span('replyText', () async {
    return messaging.broadcastText(
      content: content.trim(),
      tags: [
        [kThreadRefTag, anchor],
      ],
      recipientPubkeys: [
        ...state.value.counterpartyPubkeys,
        ...addedParticipants,
      ],
    );
  });

  Future<Message> replyTextAndWait(String content) =>
      logger.span('replyTextAndWait', () async {
        return messaging.broadcastTextAndAwait(
          content: content.trim(),
          tags: [
            [kThreadRefTag, anchor],
          ],
          recipientPubkeys: [
            ...state.value.counterpartyPubkeys,
            ...addedParticipants,
          ],
        );
      });

  Future<List<Future<List<RelayBroadcastResponse>>>>
  replyEvent<T extends Nip01Event>(
    T event, {
    List<List<String>> tags = const [],
  }) => logger.span('replyEvent', () async {
    return messaging.broadcastEvent(
      event: event,
      tags: [
        [kThreadRefTag, anchor],
        ...tags,
      ],
      recipientPubkeys: [
        ...state.value.counterpartyPubkeys,
        ...addedParticipants,
      ],
    );
  });

  Future<void> close() => logger.span('close', () async {
    for (final s in _stateSubscriptions) {
      await s.cancel();
    }
    await state.close();
    await messages.close();
  });
}
