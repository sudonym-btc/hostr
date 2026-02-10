import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import 'message/reservation_request/reservation_request.dart';

class ThreadContent extends StatelessWidget {
  final List<ProfileMetadata> counterparties;
  final Listing listing;
  const ThreadContent({
    super.key,
    required this.counterparties,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    final thread = context.read<Thread>();
    final reservationsResponse = context.read<StreamWithStatus<Reservation>>();

    return StreamBuilder<List<Reservation>>(
      stream: reservationsResponse.list,
      builder: (context, reservationsSnapshot) {
        return StreamBuilder<List<Message>>(
          stream: thread.outputStream,
          builder: (context, s) {
            return ListView.builder(
              itemCount: thread.messages.length,
              itemBuilder: (listContext, index) {
                final message = thread.messages[index];
                return _buildMessage(
                  context,
                  thread,
                  message,
                  reservationsSnapshot.data ?? [],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMessage(
    BuildContext context,
    Thread thread,
    Message message,
    List<Reservation> reservations,
  ) {
    final counterparty = counterparties.firstWhere(
      (counterparty) => counterparty.pubKey == message.pubKey,
    );

    if (message.child == null) {
      return ThreadMessageWidget(counterparty: counterparty, item: message);
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
