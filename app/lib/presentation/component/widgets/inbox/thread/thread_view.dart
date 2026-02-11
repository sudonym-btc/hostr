import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
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
      stream: context.read<ThreadCubit>().reservations.status,
      builder: (context, reservationsSnapshot) {
        return Builder(
          builder: (context) {
            final threadCubit = context.read<ThreadCubit>();
            final participants = threadCubit.participantCubits.values.toList();
            final counterparties = threadCubit.counterpartyCubits.values
                .toList();
            final profilesReady = participants.every(
              (profileCubit) => profileCubit.state.data != null,
            );
            final listingState = context.read<ThreadCubit>().listingCubit.state;

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
              participants: participants.map((e) => e.state.data!).toList(),
              counterparties: counterparties.map((e) => e.state.data!).toList(),
              reservationsListStream: threadCubit.reservations.list,
            );
          },
        );
      },
    );
  }
}

class ThreadReadyWidget extends StatelessWidget {
  final Listing listing;
  final List<ProfileMetadata> participants;
  final List<ProfileMetadata> counterparties;
  final Stream<List<Reservation>> reservationsListStream;

  const ThreadReadyWidget({
    super.key,
    required this.listing,
    required this.participants,
    required this.counterparties,
    required this.reservationsListStream,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ThreadHeaderWidget(counterparties: counterparties)),
      body: Column(
        children: [
          StreamBuilder<List<Reservation>>(
            stream: reservationsListStream,
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
            child: ThreadContent(participants: participants, listing: listing),
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
