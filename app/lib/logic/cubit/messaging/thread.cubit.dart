import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/profile.cubit.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

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
          counterpartyStates: [],
          participantStates: [],
          threadState: thread.state.value,
        ),
      ) {
    // Build counterparty cubits from participantCubits but ignore our own key
    for (final pubkey in thread.state.value.participantPubkeys) {
      addParticipant(pubkey);
    }
    _emitParticipantStates();

    _subscriptions.add(
      thread.state.listen((threadState) {
        for (final pubkey in threadState.participantPubkeys) {
          addParticipant(pubkey);
        }
        emit(state.copyWith(threadState: threadState));
      }),
    );
  }

  void _emitParticipantStates() {
    if (isClosed) return;
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
    if (isClosed) return;
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

    if (pubkey != getIt<Hostr>().auth.getActiveKey().publicKey) {
      counterpartyCubits[pubkey] = cubit;
    }
  }

  void watch() {
    thread.trade!.start();
  }

  @override
  close() async {
    await thread.trade?.deactivate();
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
  final List<EntityCubitState<ProfileMetadata>> participantStates;
  final List<EntityCubitState<ProfileMetadata>> counterpartyStates;
  final ThreadState threadState;

  ThreadCubitState({
    required this.participantStates,
    required this.counterpartyStates,
    required this.threadState,
  });

  ThreadCubitState copyWith({
    List<EntityCubitState<ProfileMetadata>>? participantStates,
    List<EntityCubitState<ProfileMetadata>>? counterpartyStates,
    ThreadState? threadState,
  }) {
    return ThreadCubitState(
      participantStates: participantStates ?? this.participantStates,
      counterpartyStates: counterpartyStates ?? this.counterpartyStates,
      threadState: threadState ?? this.threadState,
    );
  }
}
