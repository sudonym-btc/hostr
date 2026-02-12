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
  StreamWithStatus<Reservation> get reservations => thread.reservationStream;
  StreamWithStatus<SelfSignedProof> get paymentStatus => thread.paymentStream;
  final List<StreamSubscription> _subscriptions = [];
  Listing? _listing;
  ProfileMetadata? _listingProfile;

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
          listing: null,
          listingProfile: null,
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

    for (final entry in participantCubits.entries) {
      entry.value.load(entry.key);
    }

    _emitNewState();

    _loadListing();
    _loadListingProfile();

    // Subscribe to reservations status + list and emit on any change
    final reservationsUpdates = Rx.merge<void>([
      reservations.status.map((_) => null),
      reservations.list.map((_) => null),
    ]);
    _subscriptions.add(
      reservationsUpdates.listen(
        (_) => _emitNewState(reservations: reservations.list.value),
      ),
    );
  }

  Future<void> _loadListing() async {
    try {
      _listing = await thread.getListing();
      _emitNewState();
    } catch (e) {
      logger.e('Failed to load listing for thread', error: e);
    }
  }

  Future<void> _loadListingProfile() async {
    try {
      _listingProfile = await thread.getListingProfile();
      _emitNewState();
    } catch (e) {
      logger.e('Failed to load listing profile for thread', error: e);
    }
  }

  // emit helper
  void _emitNewState({List<Reservation>? reservations}) {
    emit(
      ThreadCubitState(
        listing: _listing,
        listingProfile: _listingProfile,
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
    await thread.removeSubscriptions();
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
  final List<Reservation> reservations;
  final Listing? listing;
  final ProfileMetadata? listingProfile;
  final List<EntityCubitState<ProfileMetadata>> participantStates;
  final List<EntityCubitState<ProfileMetadata>> counterpartyStates;

  ThreadCubitState({
    required this.reservations,
    required this.listing,
    required this.listingProfile,
    required this.participantStates,
    required this.counterpartyStates,
  });
}
