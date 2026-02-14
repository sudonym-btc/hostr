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
    return BlocBuilder<ThreadCubit, ThreadCubitState>(
      builder: (context, state) {
        final profilesReady = state.participantStates.every(
          (profileCubit) => profileCubit.data != null,
        );
        // print(
        //   'profiles ready: (${state.participantStates.length}) ${state.participantStates.map((e) => e.data != null).toList()}, listing: ${state.listing != null}, reservations status: ${state.reservationsStreamStatus is StreamStatusLive}',
        // );
        final isReady =
            profilesReady &&
            state.reservationsStreamStatus is StreamStatusLive &&
            state.listing != null;

        // When to display loading
        if (!isReady) {
          return Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context)!.loading)),
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        // When loaded successfully
        return ThreadReadyWidget(
          listing: state.listing!,
          participants: state.participantStates.map((e) => e.data!).toList(),
          counterparties: state.counterpartyStates.map((e) => e.data!).toList(),
          reservationsList: state.reservations,
        );
      },
    );
  }
}

class ThreadReadyWidget extends StatelessWidget {
  final Listing listing;
  final List<ProfileMetadata> participants;
  final List<ProfileMetadata> counterparties;
  final List<Reservation> reservationsList;

  const ThreadReadyWidget({
    super.key,
    required this.listing,
    required this.participants,
    required this.counterparties,
    required this.reservationsList,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ThreadHeaderWidget(counterparties: counterparties)),
      body: Column(
        children: [
          ReservationStatusWidget(
            reservations: reservationsList,
            listing: listing,
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
