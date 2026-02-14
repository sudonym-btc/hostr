import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/profile.cubit.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import '../entity/entity.cubit.dart';

class ThreadCubit extends Cubit<ThreadCubitState> {
  CustomLogger logger = CustomLogger();
  final Thread thread;
  final Map<String, ProfileCubit> participantCubits = {};
  final Map<String, ProfileCubit> counterpartyCubits = {};
  final List<StreamSubscription> _subscriptions = [];

  ThreadCubit({required this.thread})
    : super(
        ThreadCubitState(
          reservationsStreamStatus: StreamStatusIdle(),
          listing: null,
          listingProfile: null,
          counterpartyStates: [],
          participantStates: [],
          reservations: [],
          paymentEvents: [],
          paymentEventsStreamStatus: StreamStatusIdle(),
          messages: [],
          isCancellingReservation: false,
          reservationActionError: null,
        ),
      ) {
    // Build counterparty cubits from participantCubits but ignore our own key
    for (final pubkey in thread.participantPubkeys) {
      addParticipant(pubkey);
    }
    _emitParticipantStates();

    // Add a new participant cubit for the message and it's recipients if not already added
    _subscriptions.add(
      thread.messages.stream.listen((message) {
        emit(state.copyWith(messages: thread.sortedMessages));
        addParticipant(message.pubKey);
        for (final pubKey in message.pTags) {
          addParticipant(pubKey);
        }
      }),
    );
  }

  String? get _ourPubkey => getIt<Hostr>().auth.activeKeyPair?.publicKey;

  void _emitParticipantStates() {
    emit(
      state.copyWith(
        participantStates: participantCubits.values
            .map((element) => element.state)
            .toList(),
        counterpartyStates: counterpartyCubits.values
            .map((element) => element.state)
            .toList(),
      ),
    );
  }

  void addParticipant(String pubkey) {
    if (participantCubits.containsKey(pubkey)) {
      return;
    }
    if (!thread.addedParticipants.contains(pubkey)) {
      thread.addedParticipants.add(pubkey);
    }

    // Load should come before adding the emitParticipantState, so that we miss the original "loading" sate
    final cubit = ProfileCubit(metadataUseCase: getIt<Hostr>().metadata);
    cubit.load(pubkey);
    _subscriptions.add(cubit.stream.listen((_) => _emitParticipantStates()));
    participantCubits[pubkey] = cubit;

    if (pubkey != _ourPubkey) {
      counterpartyCubits[pubkey] = cubit;
    }
  }

  Future<void> cancelMyReservation() async {
    print('Attempting to cancel reservation for thread ${thread}');
    final hostr = getIt<Hostr>();
    final activePubkey = hostr.auth.activeKeyPair?.publicKey;

    if (activePubkey == null) {
      emit(
        state.copyWith(
          reservationActionError: 'No active key found',
          isCancellingReservation: false,
        ),
      );
      return;
    }

    // @todo: emitting a new reservation with copied self-signed proof is data-heavy, just reveal that I know the salt
    final mine =
        state.reservations
            .where((reservation) => reservation.pubKey != state.listing!.pubKey)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mine.isEmpty) {
      emit(
        state.copyWith(
          reservationActionError: 'No reservation found to cancel',
          isCancellingReservation: false,
        ),
      );
      return;
    }

    final latest = mine.first;
    if (latest.parsedContent.cancelled) {
      return;
    }

    emit(
      state.copyWith(
        isCancellingReservation: true,
        clearReservationActionError: true,
      ),
    );

    try {
      final tempKeyPair = Bip340.generatePrivateKey();
      final cancelledReservation = latest
          .copyWithContent(cancelled: true)
          .copyWith(
            pubKey: tempKeyPair.publicKey,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            id: null,
            validSig: false,
            sig: null,
          );

      final signed = cancelledReservation.signAs(
        tempKeyPair,
        Reservation.fromNostrEvent,
      );
      await hostr.reservations.create(signed);
      emit(state.copyWith(isCancellingReservation: false));
    } catch (e) {
      emit(
        state.copyWith(
          isCancellingReservation: false,
          reservationActionError: e.toString(),
        ),
      );
    }
  }

  void watch() {
    thread.watcher.watch();
    thread.watcher
        .getListing()
        .then((listing) {
          emit(state.copyWith(listing: listing));
        })
        .catchError((e) {
          logger.e('Failed to watch listing for thread', error: e);
        });

    thread.watcher
        .getListingProfile()
        .then((listingProfile) {
          emit(state.copyWith(listingProfile: listingProfile));
        })
        .catchError((e) {
          logger.e('Failed to watch listing profile for thread', error: e);
        });

    _subscriptions.add(
      Rx.merge([
        thread.watcher.paymentEvents!.status.map((event) => null),
        thread.watcher.paymentEvents!.stream.map((event) => null),
        thread.watcher.reservationStream.status.map((event) => null),
        thread.watcher.reservationStream.stream.map((event) => null),
      ]).listen((_) {
        emit(
          state.copyWith(
            messages: thread.sortedMessages,
            paymentEvents: thread.watcher.paymentEvents!.list.value,
            paymentEventsStreamStatus:
                thread.watcher.paymentEvents!.status.value,
            reservations: thread.watcher.reservationStream.list.value,
            reservationsStreamStatus:
                thread.watcher.reservationStream.status.value,
          ),
        );
      }),
    );
  }

  @override
  close() async {
    await thread.watcher.removeSubscriptions();
    for (final c in participantCubits.values) {
      await c.close();
    }
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await super.close();
  }
}

class ThreadCubitState {
  final List<Message> messages;
  final StreamStatus reservationsStreamStatus;
  final List<Reservation> reservations;
  final Listing? listing;
  final ProfileMetadata? listingProfile;
  final List<EntityCubitState<ProfileMetadata>> participantStates;
  final List<EntityCubitState<ProfileMetadata>> counterpartyStates;

  final List<PaymentEvent> paymentEvents;
  final StreamStatus paymentEventsStreamStatus;
  final bool isCancellingReservation;
  final String? reservationActionError;

  ThreadCubitState({
    required this.reservations,
    required this.listing,
    required this.listingProfile,
    required this.participantStates,
    required this.counterpartyStates,
    required this.reservationsStreamStatus,
    required this.paymentEvents,
    required this.paymentEventsStreamStatus,
    required this.messages,
    required this.isCancellingReservation,
    required this.reservationActionError,
  });

  ThreadCubitState copyWith({
    List<Message>? messages,
    StreamStatus? reservationsStreamStatus,
    List<Reservation>? reservations,
    Listing? listing,
    ProfileMetadata? listingProfile,
    List<EntityCubitState<ProfileMetadata>>? participantStates,
    List<EntityCubitState<ProfileMetadata>>? counterpartyStates,
    List<PaymentEvent>? paymentEvents,
    StreamStatus? paymentEventsStreamStatus,
    bool? isCancellingReservation,
    String? reservationActionError,
    bool clearReservationActionError = false,
  }) {
    return ThreadCubitState(
      reservations: reservations ?? this.reservations,
      listing: listing ?? this.listing,
      listingProfile: listingProfile ?? this.listingProfile,
      participantStates: participantStates ?? this.participantStates,
      counterpartyStates: counterpartyStates ?? this.counterpartyStates,
      reservationsStreamStatus:
          reservationsStreamStatus ?? this.reservationsStreamStatus,
      paymentEvents: paymentEvents ?? this.paymentEvents,
      paymentEventsStreamStatus:
          paymentEventsStreamStatus ?? this.paymentEventsStreamStatus,
      messages: messages ?? this.messages,
      isCancellingReservation:
          isCancellingReservation ?? this.isCancellingReservation,
      reservationActionError: clearReservationActionError
          ? null
          : (reservationActionError ?? this.reservationActionError),
    );
  }
}
