import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/messaging/thread.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/requests/requests.dart';
import 'package:hostr/logic/cubit/entity/entity.cubit.dart';
import 'package:hostr/logic/cubit/profile.cubit.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:models/main.dart';

import 'message/reservation_request/reservation_request.dart';

class ThreadContent extends StatelessWidget {
  const ThreadContent({super.key});

  @override
  Widget build(BuildContext context) {
    final thread = context.read<Thread>();
    final reservationsResponse = context.read<CustomNdkResponse<Reservation>>();

    return Expanded(
      child: FutureBuilder<List<Reservation>>(
        future: reservationsResponse.future,
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
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context,
    Thread thread,
    Message message,
    List<Reservation> reservations,
  ) {
    final profile = context.read<ProfileCubit>();
    final listing = context.read<EntityCubit<Listing>>();

    if (message.child == null) {
      return ThreadMessageWidget(
        counterpartyPubkey: thread.counterpartyPubkey(),
        item: message,
      );
    } else if (message.child is ReservationRequest) {
      return ThreadReservationRequestWidget(
        counterparty: profile.state.data!.metadata,
        item: message,
        listing: listing.state.data!,
        reservations: reservations,
      );
    }
    return Text('Unknown message type');
  }
}
