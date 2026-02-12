import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/profile.cubit.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class ThreadCubit extends Cubit<ThreadCubitState> {
  CustomLogger logger = CustomLogger();
  final Thread thread;
  final Map<String, ProfileCubit> participantCubits;
  late final Map<String, ProfileCubit> counterpartyCubits;
  final EntityCubit<Listing> listingCubit;
  StreamWithStatus<Reservation> get reservations => thread.reservationStream;
  StreamWithStatus<SelfSignedProof> get paymentStatus => thread.paymentStream;
  final List<StreamSubscription> _subscriptions = [];

  ThreadCubit({required this.thread})
    : participantCubits = Map.fromEntries(
        thread.participantPubkeys
            .map(
              (pubkey) => MapEntry(
                pubkey,
                ProfileCubit(metadataUseCase: getIt<Hostr>().metadata)
                  ..load(pubkey),
              ),
            )
            .toList(),
      ),
      listingCubit = EntityCubit<Listing>(
        crud: getIt<Hostr>().listings,
        filter: Filter(
          kinds: [Listing.kinds[0]],
          dTags: [
            getDTagFromAnchor(
              MessagingListings.getThreadListing(thread: thread),
            ),
          ],
        ),
      )..get(),
      super(
        ThreadCubitState(
          counterpartyStates: [],
          participantStates: [],
          reservations: [],
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
      _subscriptions.add(cubit.stream.listen((_) => _emitNewState()));
    }

    // Subscribe to listing and reservations
    _subscriptions.add(listingCubit.stream.listen((_) => _emitNewState()));
    _subscriptions.add(
      reservations.list.listen((rs) => _emitNewState(reservations: rs)),
    );
  }

  // emit helper
  void _emitNewState({List<Reservation>? reservations}) {
    print('emitting new state');
    emit(
      ThreadCubitState(
        reservations: reservations ?? state.reservations,
        participantStates: participantCubits.values
            .map((c) => c.state)
            .toList(),
        counterpartyStates: counterpartyCubits.values
            .map((c) => c.state)
            .toList(),
      ),
    );
  }

  @override
  close() async {
    super.close();
    await reservations.close();
    await listingCubit.close();
    for (final c in participantCubits.values) {
      await c.close();
    }
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await paymentStatus?.close();
  }
}

class ThreadCubitState {
  final List<Reservation> reservations;
  final List<ProfileCubitState> participantStates;
  final List<ProfileCubitState> counterpartyStates;

  ThreadCubitState({
    required this.reservations,
    required this.participantStates,
    required this.counterpartyStates,
  });
}
