import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
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
    return BlocBuilder<ThreadCubit, ThreadCubitState>(
      builder: (context, state) {
        return ListView.builder(
          itemCount: state.messages.length,
          itemBuilder: (listContext, index) {
            final message = state.messages[index];
            return _buildMessage(
              context,
              message: message,
              reservations: state.reservations,
            );
          },
        );
      },
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required Message message,
    required List<Reservation> reservations,
  }) {
    final counterparty = participants.firstWhere(
      (counterparty) => counterparty.pubKey == message.pubKey,
    );

    if (message.child == null) {
      return ThreadMessageWidget(counterparty: counterparty, item: message);
    } else if (message.child is EscrowServiceSelected) {
      return Container();
    } else if (message.child is ReservationRequest) {
      return ThreadReservationRequestWidget(
        counterparty: counterparty,
        item: message,
        listing: listing,
        reservations: reservations,
      );
    }
    return Text('Unknown message type');
  }
}
