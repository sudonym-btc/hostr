import 'dart:async';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Nip01Event;
import 'package:rxdart/rxdart.dart';

@Injectable()
class Thread {
  final CustomLogger logger;
  final Messaging messaging;
  final Auth auth;
  ThreadTrade? trade;
  final BehaviorSubject<ThreadState> state;
  final List<StreamSubscription> _stateSubscriptions = [];

  final String anchor;
  final StreamWithStatus<Message> messages = StreamWithStatus<Message>();

  bool _isTradeCandidate(ThreadState current) => current.messages.any(
    (message) => message.child is ReservationRequest,
    // || message.child is EscrowServiceSelected,
  );

  Thread(
    @factoryParam this.anchor, {
    required this.logger,
    required this.auth,
    required this.messaging,
  }) : state = BehaviorSubject<ThreadState>.seeded(
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
      state.stream
          .where(
            (current) =>
                trade == null &&
                _isTradeCandidate(current) &&
                current.reservationRequests.isNotEmpty,
          )
          .take(1)
          .listen((_) {
            print('Thread $anchor is a trade candidate, initializing trade...');
            trade = getIt<ThreadTrade>(param1: this);
            _stateSubscriptions.add(trade!.state.listen((_) => _emitState()));
          }),
    );
  }

  void _emitState() {
    if (state.isClosed) return;
    final keyPair = auth.activeKeyPair;
    if (keyPair == null) return;
    state.add(
      state.value.copyWith(
        messages: messages.list.value,
        counterpartyPubkeys: state.value.participantPubkeys
            .where((pubkey) => pubkey != keyPair.publicKey)
            .toList(),
      ),
    );
  }

  List<String> addedParticipants = [];

  Future<List<Future<List<RelayBroadcastResponse>>>> replyText(String content) {
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
      recipientPubkeys: [
        ...state.value.counterpartyPubkeys,
        ...addedParticipants,
      ],
    );
  }

  Future<void> close() async {
    await trade?.close();
    for (final s in _stateSubscriptions) {
      await s.cancel();
    }
    await state.close();
    await messages.close();
  }
}
