import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_content.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_reply.dart';
import 'package:hostr/presentation/main.dart';
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
            state.listingProfile != null &&
            // state.threadState.subscriptions.reservationStreamStatus
            //     is StreamStatusLive &&
            // state.threadState.subscriptions.paymentStreamStatus
            //     is StreamStatusLive &&
            state.listing != null;

        // print(
        //   'ThreadView build: isReady: $isReady, profilesReady: $profilesReady, listingProfile: ${state.listingProfile != null}, reservationStreamStatus: ${state.threadState.subscriptions.reservationStreamStatus}, paymentStreamStatus: ${state.threadState.subscriptions.paymentStreamStatus}, listing: ${state.listing != null}, ${state.threadState.subscriptions.paymentStreamStatus}',
        // );

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
          listingProfile: state.listingProfile!,
          participants: state.participantStates.map((e) => e.data!).toList(),
          counterparties: state.counterpartyStates.map((e) => e.data!).toList(),
          messages: state.threadState.sortedMessages,
        );
      },
    );
  }
}

class ThreadReadyWidget extends StatelessWidget {
  final Listing listing;
  final ProfileMetadata listingProfile;
  final List<ProfileMetadata> participants;
  final List<ProfileMetadata> counterparties;

  final List<Message> messages;

  const ThreadReadyWidget({
    super.key,
    required this.listing,
    required this.listingProfile,
    required this.participants,
    required this.counterparties,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: ThreadHeaderWidget(counterparties: counterparties),
        ),
        body: Column(
          children: [
            ReservationStatusWidget(),
            Expanded(
              child: ThreadContent(
                participants: participants,
                listing: listing,
              ),
            ),
            Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: SafeArea(
                top: false,
                child: CustomPadding(
                  top: 0.5,
                  bottom: 0.5,
                  child: ThreadReplyWidget(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
