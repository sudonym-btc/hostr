import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/logic/cubit/messaging/thread_reply.cubit.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr/presentation/screens/shared/inbox/thread/giftwraps/message.dart';
import 'package:hostr/presentation/screens/shared/inbox/thread/giftwraps/reservation_request.dart';
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
  final _replyController = TextEditingController();

  // ignore: use_key_in_widget_constructors
  ThreadViewState();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThreadCubit threadCubit = context.read<ThreadCubit>();

    return BlocBuilder<ThreadCubit, ThreadCubitState>(
      builder: (context, state) {
        return ProfileProvider(
          pubkey: threadCubit.getCounterpartyPubkey(),
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
                a: threadCubit.getListingAnchor(),
                child: Scaffold(
                  appBar: AppBar(
                    title: ThreadHeaderWidget(
                      title:
                          snapshot.data!.name ??
                          AppLocalizations.of(context)!.loading,
                      image: snapshot.data!.picture,
                      subtitle:
                          snapshot.data!.cleanNip05 ??
                          snapshot.data!.lud06 ??
                          snapshot.data!.lud16 ??
                          snapshot.data!.pubKey,
                    ),
                  ),
                  body: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.messages.length,
                            itemBuilder: (listContext, index) {
                              if (state.messages[index].child == null) {
                                return ThreadMessageWidget(
                                  counterpartyPubkey: threadCubit
                                      .getCounterpartyPubkey(),
                                  item: state.messages[index],
                                );
                              } else if (state.messages[index].child
                                  is ReservationRequest) {
                                return ThreadReservationRequestWidget(
                                  counterparty: snapshot.data!,
                                  item: state.messages[index],
                                );
                              }
                              return Text('Unknown message type');
                            },
                          ),
                        ),
                        CustomPadding(
                          child: BlocProvider(
                            // Inject dependencies
                            create: (context) =>
                                ThreadReplyCubit(thread: threadCubit.thread),
                            child: BlocConsumer<ThreadReplyCubit, ThreadReplyState>(
                              listener: (context, state) => {
                                if (state.status == ThreadReplyStatus.success)
                                  {_replyController.clear()},
                              },
                              builder: (context, state) {
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        onChanged: (text) {
                                          setState(() {}); // Trigger rebuild
                                        },
                                        controller: _replyController,
                                        maxLines: 3,
                                        minLines: 1,
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          labelText: 'Reply',
                                          errorText:
                                              state.status ==
                                                  ThreadReplyStatus.error
                                              ? state.error
                                              : null,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: DEFAULT_PADDING.toDouble(),
                                    ), // Add space here

                                    FilledButton(
                                      onPressed:
                                          state.status ==
                                                  ThreadReplyStatus.loading ||
                                              _replyController.text
                                                  .trim()
                                                  .isEmpty
                                          ? null
                                          : () {
                                              context
                                                  .read<ThreadReplyCubit>()
                                                  .sendReply(
                                                    message:
                                                        _replyController.text,
                                                    threadAnchor: threadCubit
                                                        .getAnchor(),
                                                    counterpartyPubkey: threadCubit
                                                        .getCounterpartyPubkey(),
                                                  );
                                            },
                                      child: Text(
                                        AppLocalizations.of(context)!.send,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
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
