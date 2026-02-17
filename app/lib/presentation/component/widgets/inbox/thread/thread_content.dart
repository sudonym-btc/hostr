import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:models/main.dart';

import 'message/reservation_request/reservation_request.dart';

class ThreadContent extends StatelessWidget {
  final List<ProfileMetadata> participants;
  final Listing listing;
  const ThreadContent({
    super.key,
    required this.participants,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPadding(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: BlocBuilder<ThreadCubit, ThreadCubitState>(
              builder: (context, state) {
                return ListView.builder(
                  itemCount: state.threadState.sortedMessages.length,
                  itemBuilder: (listContext, index) {
                    final message = state.threadState.sortedMessages[index];
                    return Column(
                      children: [
                        if (index != 0) SizedBox(height: kDefaultPadding / 2),
                        _buildMessage(
                          context,
                          message: message,
                          reservations:
                              state.threadState.subscriptions.reservations,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          FilledButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return SafeArea(
                    child: CustomPadding(
                      child: EditReview(
                        listing: listing,
                        salt: 'thread_salt',
                        // reservation: thread.reservation,
                      ),
                    ),
                  );
                },
              );
            },
            child: Text('Review your stay'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required Message message,
    required List<Reservation> reservations,
  }) {
    final sender = participants.firstWhere(
      (participant) => participant.pubKey == message.pubKey,
    );

    if (message.child == null) {
      return ThreadMessageWidget(sender: sender, item: message);
    } else if (message.child is EscrowServiceSelected) {
      return Container();
    } else if (message.child is ReservationRequest) {
      return ThreadReservationRequestWidget(sender: sender, item: message);
    }
    return Text('Unknown message type');
  }
}
