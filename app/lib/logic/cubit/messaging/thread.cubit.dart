import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/profile.cubit.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import '../entity/entity.cubit.dart';

class ThreadCubit extends Cubit<ThreadCubitState> {
  CustomLogger logger = CustomLogger();
  final Thread thread;
  final Map<String, ProfileCubit> participantCubits;
  late final Map<String, ProfileCubit> counterpartyCubits;
  final List<StreamSubscription> _subscriptions = [];

  ThreadCubit({required this.thread})
    : participantCubits = Map.fromEntries(
        thread.participantPubkeys
            .map(
              (pubkey) => MapEntry(
                pubkey,
                ProfileCubit(metadataUseCase: getIt<Hostr>().metadata),
              ),
            )
            .toList(),
      ),
      super(
        ThreadCubitState(
          reservationsStreamStatus: StreamStatusIdle(),
          listing: null,
          listingProfile: null,
          counterpartyStates: [],
          participantStates: [],
          reservations: [],
          paymentProofs: [],
          paymentProofsStreamStatus: StreamStatusIdle(),
          messages: [],
        ),
      ) {
    // Build counterparty cubits from participantCubits but ignore our own key
    final ourPubkey = getIt<Hostr>().auth.activeKeyPair?.publicKey;
    counterpartyCubits = Map<String, ProfileCubit>.from(participantCubits);
    if (ourPubkey != null) {
      counterpartyCubits.remove(ourPubkey);
    }

    // Subscribe to counterparty cubit streams
    for (final cubit in participantCubits.values) {
      _subscriptions.add(
        cubit.stream.listen(
          (_) => emit(
            state.copyWith(
              participantStates: participantCubits.values
                  .map((element) => element.state)
                  .toList(),
              counterpartyStates: counterpartyCubits.values
                  .map((element) => element.state)
                  .toList(),
            ),
          ),
        ),
      );
    }

    for (final entry in participantCubits.entries) {
      entry.value.load(entry.key);
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
        thread.messages.stream.map((event) => null),
        thread.watcher.paymentStream.status.map((event) => null),
        thread.watcher.paymentStream.stream.map((event) => null),
        thread.watcher.reservationStream.status.map((event) => null),
        thread.watcher.reservationStream.stream.map((event) => null),
      ]).listen((_) {
        emit(
          state.copyWith(
            messages: thread.sortedMessages,
            paymentProofs: thread.watcher.paymentStream.list.value,
            paymentProofsStreamStatus:
                thread.watcher.paymentStream.status.value,
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

  final List<SelfSignedProof> paymentProofs;
  final StreamStatus paymentProofsStreamStatus;

  ThreadCubitState({
    required this.reservations,
    required this.listing,
    required this.listingProfile,
    required this.participantStates,
    required this.counterpartyStates,
    required this.reservationsStreamStatus,
    required this.paymentProofs,
    required this.paymentProofsStreamStatus,
    required this.messages,
  });

  ThreadCubitState copyWith({
    List<Message>? messages,
    StreamStatus? reservationsStreamStatus,
    List<Reservation>? reservations,
    Listing? listing,
    ProfileMetadata? listingProfile,
    List<EntityCubitState<ProfileMetadata>>? participantStates,
    List<EntityCubitState<ProfileMetadata>>? counterpartyStates,
    List<SelfSignedProof>? paymentProofs,
    StreamStatus? paymentProofsStreamStatus,
  }) {
    return ThreadCubitState(
      reservations: reservations ?? this.reservations,
      listing: listing ?? this.listing,
      listingProfile: listingProfile ?? this.listingProfile,
      participantStates: participantStates ?? this.participantStates,
      counterpartyStates: counterpartyStates ?? this.counterpartyStates,
      reservationsStreamStatus:
          reservationsStreamStatus ?? this.reservationsStreamStatus,
      paymentProofs: paymentProofs ?? this.paymentProofs,
      paymentProofsStreamStatus:
          paymentProofsStreamStatus ?? this.paymentProofsStreamStatus,
      messages: messages ?? this.messages,
    );
  }
}
