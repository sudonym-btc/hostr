import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/messaging_listings/messaging_listings.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr/presentation/screens/shared/inbox/thread/giftwraps/message.dart';
import 'package:hostr/presentation/screens/shared/inbox/thread/giftwraps/reservation_request.dart';
import 'package:hostr/presentation/screens/shared/inbox/thread/thread_reply.dart';
import 'package:models/main.dart';

class ThreadView extends StatefulWidget {
  final String a;
  const ThreadView({super.key, required this.a});
  @override
  State<StatefulWidget> createState() {
    return ThreadViewState();
  }
}

class ThreadViewState extends State<ThreadView> {
  // ignore: use_key_in_widget_constructors
  ThreadViewState();

  @override
  Widget build(BuildContext context) {
    ThreadCubit threadCubit = context.read<ThreadCubit>();

    return BlocBuilder<ThreadCubit, ThreadCubitState>(
      builder: (context, state) {
        return ProfileProvider(
          pubkey: threadCubit.thread.counterpartyPubkey(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.loading),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.done) {
              return ListingProvider(
                a: MessagingListings.getThreadListing(
                  thread: threadCubit.thread,
                ),
                child: Scaffold(
                  appBar: AppBar(
                    title: ThreadHeaderWidget(metadata: snapshot.data),
                  ),
                  body: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: StreamBuilder<List<Message>>(
                            stream: threadCubit.thread.outputStream,
                            builder: (context, s) {
                              return ListView.builder(
                                itemCount: threadCubit.thread.messages.length,
                                itemBuilder: (listContext, index) {
                                  if (threadCubit
                                          .thread
                                          .messages[index]
                                          .child ==
                                      null) {
                                    return ThreadMessageWidget(
                                      counterpartyPubkey: threadCubit.thread
                                          .counterpartyPubkey(),
                                      item: threadCubit.thread.messages[index],
                                    );
                                  } else if (threadCubit
                                          .thread
                                          .messages[index]
                                          .child
                                      is ReservationRequest) {
                                    return ThreadReservationRequestWidget(
                                      counterparty: snapshot.data!,
                                      item: threadCubit.thread.messages[index],
                                    );
                                  }
                                  return Text('Unknown message type');
                                },
                              );
                            },
                          ),
                        ),
                        CustomPadding(child: ThreadReplyWidget()),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Placeholder();
          },
        );
      },
    );
  }
}
