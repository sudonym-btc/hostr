import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/profile.cubit.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
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
          listing: null,
          listingProfile: null,
          counterpartyStates: [],
          participantStates: [],
          threadState: thread.state.value,
          isCancellingReservation: false,
          isClaimingEscrow: false,
          reservationActionError: null,
        ),
      ) {
    // Build counterparty cubits from participantCubits but ignore our own key
    for (final pubkey in thread.state.value.participantPubkeys) {
      addParticipant(pubkey);
    }
    _emitParticipantStates();

    _subscriptions.add(
      thread.state.listen((threadState) {
        for (final message in threadState.messages) {
          addParticipant(message.pubKey);
          for (final pubKey in message.pTags) {
            addParticipant(pubKey);
          }
        }
        emit(state.copyWith(threadState: threadState));
      }),
    );
  }

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

    if (pubkey != getIt<Hostr>().auth.activeKeyPair?.publicKey) {
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
        state.threadState.subscriptions.reservations
            .where((reservation) => reservation.pubKey != state.listing!.pubKey)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mine.any((reservation) => reservation.parsedContent.cancelled)) {
      emit(
        state.copyWith(
          reservationActionError: 'Reservation is already cancelled',
          isCancellingReservation: false,
        ),
      );
      return;
    }

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
      final cancelledReservation = latest.copy(
        pubKey: tempKeyPair.publicKey,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        content: latest.parsedContent.copyWith(cancelled: true),
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

  Future<void> claimEscrow({
    required String tradeId,
    required EscrowService escrowService,
  }) async {
    emit(
      state.copyWith(isClaimingEscrow: true, clearReservationActionError: true),
    );

    try {
      final hostr = getIt<Hostr>();
      final contract = hostr.evm
          .getChainForEscrowService(escrowService)
          .getSupportedEscrowContract(escrowService);
      final claimParams = ContractClaimEscrowParams(
        tradeId: tradeId,
        ethKey: hostr.auth.getActiveEvmKey(),
      );

      final canClaim = await contract.canClaim(claimParams);
      if (!canClaim) {
        emit(
          state.copyWith(
            isClaimingEscrow: false,
            reservationActionError:
                'Claim is not available yet (timelock may not have passed).',
          ),
        );
        return;
      }

      await contract.claim(claimParams);
      emit(state.copyWith(isClaimingEscrow: false));
    } catch (e) {
      emit(
        state.copyWith(
          isClaimingEscrow: false,
          reservationActionError: e.toString(),
        ),
      );
    }
  }

  void watch() {
    thread.watch();
    thread
        .getListing()
        .then((listing) {
          emit(state.copyWith(listing: listing));
        })
        .catchError((e) {
          logger.e('Failed to watch listing for thread', error: e);
        });

    thread
        .getListingProfile()
        .then((listingProfile) {
          emit(state.copyWith(listingProfile: listingProfile));
        })
        .catchError((e) {
          logger.e('Failed to watch listing profile for thread', error: e);
        });
  }

  @override
  close() async {
    await thread.unwatch();
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
  final Listing? listing;
  final ProfileMetadata? listingProfile;
  final List<EntityCubitState<ProfileMetadata>> participantStates;
  final List<EntityCubitState<ProfileMetadata>> counterpartyStates;

  final ThreadState threadState;

  final bool isCancellingReservation;
  final bool isClaimingEscrow;
  final String? reservationActionError;

  ThreadCubitState({
    required this.listing,
    required this.listingProfile,
    required this.participantStates,
    required this.counterpartyStates,
    required this.threadState,
    required this.isCancellingReservation,
    required this.isClaimingEscrow,
    required this.reservationActionError,
  });

  ThreadCubitState copyWith({
    Listing? listing,
    ProfileMetadata? listingProfile,
    List<EntityCubitState<ProfileMetadata>>? participantStates,
    List<EntityCubitState<ProfileMetadata>>? counterpartyStates,
    ThreadState? threadState,
    bool? isCancellingReservation,
    bool? isClaimingEscrow,
    String? reservationActionError,
    bool clearReservationActionError = false,
  }) {
    return ThreadCubitState(
      listing: listing ?? this.listing,
      listingProfile: listingProfile ?? this.listingProfile,
      participantStates: participantStates ?? this.participantStates,
      counterpartyStates: counterpartyStates ?? this.counterpartyStates,
      threadState: threadState ?? this.threadState,
      isCancellingReservation:
          isCancellingReservation ?? this.isCancellingReservation,
      isClaimingEscrow: isClaimingEscrow ?? this.isClaimingEscrow,
      reservationActionError: clearReservationActionError
          ? null
          : (reservationActionError ?? this.reservationActionError),
    );
  }
}
