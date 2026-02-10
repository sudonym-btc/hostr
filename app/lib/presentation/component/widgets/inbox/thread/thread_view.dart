import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/logic/cubit/profile.cubit.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/providers/nostr/thread.provider.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_content.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_reply.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import 'reservation_status.dart';

class ThreadView extends StatelessWidget {
  const ThreadView({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<StreamWithStatus<Reservation>>().status,
      builder: (context, reservationsSnapshot) {
        return Builder(
          builder: (context) {
            final profileCubits = context
                .read<
                  ProfilesProvider
                >(); // get your list of ProfileCubits from Provider or MultiProvider

            // Collect all profile states using context.select
            final profileStates = profileCubits.profiles
                .map(
                  (cubit) => context.select<ProfileCubit, ProfileCubitState>(
                    (_) => cubit.state,
                  ),
                )
                .toList();

            final profilesReady = profileStates.every(
              (profileState) =>
                  profileState.active || profileState.data == null,
            );
            final listingState = context
                .select<EntityCubit<Listing>, EntityCubitState<Listing>>(
                  (cubit) => cubit.state,
                );
            final _ = context.select<ThreadCubit, ThreadCubitState>(
              (cubit) => cubit.state,
            );

            final isLoading =
                !profilesReady ||
                reservationsSnapshot.data is! StreamStatusLive ||
                listingState.active ||
                listingState.data == null;

            // When to display loading
            if (isLoading) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.loading),
                ),
                body: SafeArea(
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            // When loaded successfully
            return ThreadReadyWidget(
              listing: listingState.data!,
              counterparties: profileStates.map((e) => e.data!).toList(),
            );
          },
        );
      },
    );
  }
}

class ThreadReadyWidget extends StatelessWidget {
  final Listing listing;
  final List<ProfileMetadata> counterparties;

  const ThreadReadyWidget({
    super.key,
    required this.listing,
    required this.counterparties,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ThreadHeaderWidget(counterparties: counterparties)),
      body: Column(
        children: [
          StreamBuilder<List<Reservation>>(
            stream: context.read<StreamWithStatus<Reservation>>().list,
            builder: (context, snapshot) {
              return ReservationStatusWidget(
                reservation: Reservation.getSeniorReservation(
                  reservations: snapshot.data ?? [],
                  listing: listing,
                ),
                listing: listing,
              );
            },
          ),
          Expanded(
            child: ThreadContent(
              counterparties: counterparties,
              listing: listing,
            ),
          ),
          SafeArea(
            top: false,
            child: CustomPadding(child: ThreadReplyWidget()),
          ),
        ],
      ),
    );
  }
}
