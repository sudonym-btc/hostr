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
  late final ThreadContext context;
  late final ThreadSubscriptions subscriptions;
  late final ThreadPaymentProofOrchestrator paymentProofOrchestrator;
  final BehaviorSubject<ThreadState> state;
  final List<StreamSubscription> _stateSubscriptions = [];
  Future<void>? _inFlightWatch;
  bool _watching = false;

  final String anchor;
  final StreamWithStatus<Message> messages = StreamWithStatus<Message>();
  String get tradeId => anchor;
  String? get salt => messages.list.value
      .map((message) => message.child)
      .whereType<ReservationRequest>()
      .firstOrNull
      ?.parsedContent
      .salt;

  String getListingAnchor() {
    ReservationRequest? r =
        (messages.list.value.firstWhere((element) {
              return element.child is ReservationRequest;
            }).child
            as ReservationRequest);
    return r.parsedTags.listingAnchor;
  }

  Thread(
    @factoryParam this.anchor, {
    required this.logger,
    required this.auth,
    required this.messaging,
  }) : state = BehaviorSubject<ThreadState>.seeded(
         ThreadState.initial(
           ourPubkey: auth.activeKeyPair!.publicKey,
           anchor: anchor,
           tradeId: anchor,
         ),
       ) {
    context = ThreadContext(
      thread: this,
      listings: getIt<Listings>(),
      metadata: getIt<MetadataUseCase>(),
    );
    subscriptions = ThreadSubscriptions(
      thread: this,
      logger: logger,
      reservations: getIt<Reservations>(),
      zaps: getIt<Zaps>(),
      escrow: getIt<EscrowUseCase>(),
    );
    paymentProofOrchestrator = ThreadPaymentProofOrchestrator(
      thread: this,
      subscriptions: subscriptions,
      context: context,
      reservations: getIt<Reservations>(),
      logger: logger,
    );

    _stateSubscriptions.add(messages.stream.listen((_) => _emitState()));
    _stateSubscriptions.add(subscriptions.state.listen((_) => _emitState()));
  }

  Future<Listing?> getListing() => context.getListing();
  Future<ProfileMetadata?> getListingProfile() => context.getListingProfile();

  Future<void> watch() {
    if (_inFlightWatch != null) {
      return _inFlightWatch!;
    }

    _inFlightWatch = _doWatch();
    return _inFlightWatch!.whenComplete(() {
      _inFlightWatch = null;
    });
  }

  Future<void> _doWatch() async {
    if (_watching) {
      return;
    }
    _watching = true;
    await context.load();
    await subscriptions.sync();
    await paymentProofOrchestrator.syncAndPublishProofs();
    _emitState();
  }

  Future<void> unwatch() async {
    if (!_watching) {
      return;
    }
    _watching = false;
    await subscriptions.unwatch();
    _emitState();
  }

  void _emitState() {
    if (state.isClosed) return;
    state.add(
      state.value.copyWith(
        salt: salt,
        messages: messages.list.value,
        subscriptions: subscriptions.state.value,
        counterpartyPubkeys: state.value.participantPubkeys
            .where((pubkey) => pubkey != auth.activeKeyPair!.publicKey)
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
    await unwatch();
    for (final s in _stateSubscriptions) {
      await s.cancel();
    }
    await state.close();
    await messages.close();
  }
}
