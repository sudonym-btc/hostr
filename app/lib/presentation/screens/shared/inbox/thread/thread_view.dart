import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/screens/shared/inbox/thread/giftwraps/message.dart';
import 'package:ndk/ndk.dart';
import 'package:models/main.dart';

import 'giftwraps/reservation_request.dart';

class ThreadView extends StatefulWidget {
  final String a;
  const ThreadView({required this.a});
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
    ThreadCubit threadCubit = BlocProvider.of<ThreadOrganizerCubit>(context)
        .state
        .threads
        .firstWhere((element) => element.getAnchor() == widget.a);

    return BlocProvider.value(
        value: threadCubit,
        child: BlocBuilder<ThreadCubit, ThreadCubitState>(
            builder: (context, state) {
          return ProfileProvider(
              pubkey: threadCubit.getCounterpartyPubkey(),
              builder: (context, profileState) {
                if (profileState is EntityCubitStateError) {
                  return Scaffold(
                      appBar: AppBar(
                          title: Text(
                              'Error: ${(profileState as EntityCubitStateError).error}')));
                }
                if (profileState == null) {
                  return Scaffold(appBar: AppBar(title: Text('Loading')));
                }
                return ListingProvider(
                    a: threadCubit.getListingAnchor(),
                    child: Scaffold(
                        appBar: AppBar(
                            title: ThreadHeaderWidget(
                                title: profileState.name ?? 'Loading',
                                image: profileState.picture,
                                subtitle: profileState.cleanNip05 ??
                                    profileState.lud06 ??
                                    profileState.lud16 ??
                                    profileState.pubKey)),
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
                                            item: state.messages[index]);
                                      } else if (state.messages[index].child
                                          is ReservationRequest) {
                                        return ThreadReservationRequestWidget(
                                            counterparty: profileState,
                                            item: state.messages[index]);
                                      }
                                      return Text('Unknown message type');
                                    })),
                            CustomPadding(
                                child: BlocProvider(
                                    create: (context) => EventPublisherCubit(),
                                    child:
                                        BlocConsumer<EventPublisherCubit,
                                                EventPublisherState>(
                                            listener: (context, state) => {
                                                  if (state.status ==
                                                      EventPublisherStatus
                                                          .success)
                                                    {_replyController.clear()}
                                                },
                                            builder: (context, state) {
                                              return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Expanded(
                                                        child: TextField(
                                                      onChanged: (text) {
                                                        setState(
                                                            () {}); // Trigger rebuild
                                                      },
                                                      controller:
                                                          _replyController,
                                                      maxLines: 3,
                                                      minLines: 1,
                                                      autofocus: true,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: 'Reply',
                                                        errorText: state
                                                                    .status ==
                                                                EventPublisherStatus
                                                                    .error
                                                            ? state.error
                                                            : null,
                                                      ),
                                                    )),
                                                    SizedBox(
                                                        width: DEFAULT_PADDING
                                                            .toDouble()), // Add space here

                                                    FilledButton(
                                                        onPressed: state.status ==
                                                                    EventPublisherStatus
                                                                        .loading ||
                                                                _replyController
                                                                    .text
                                                                    .trim()
                                                                    .isEmpty
                                                            ? null
                                                            : () {
                                                                context
                                                                    .read<
                                                                        EventPublisherCubit>()
                                                                    .publishEvents([
                                                                  giftWrapAndSeal(
                                                                          threadCubit
                                                                              .getCounterpartyPubkey(),
                                                                          getIt<KeyStorage>()
                                                                              .getActiveKeyPairSync()!,
                                                                          Nip01Event(
                                                                              pubKey: getIt<KeyStorage>().getActiveKeyPairSync()!.publicKey,
                                                                              kind: NOSTR_KIND_DM,
                                                                              tags: [
                                                                                [
                                                                                  'a',
                                                                                  threadCubit.getAnchor()
                                                                                ]
                                                                              ],
                                                                              content: _replyController.text.trim()),
                                                                          null)
                                                                      .nip01Event,
                                                                  giftWrapAndSeal(
                                                                          getIt<KeyStorage>()
                                                                              .getActiveKeyPairSync()!
                                                                              .publicKey,
                                                                          getIt<KeyStorage>()
                                                                              .getActiveKeyPairSync()!,
                                                                          Nip01Event(
                                                                              pubKey: getIt<KeyStorage>().getActiveKeyPairSync()!.publicKey,
                                                                              kind: NOSTR_KIND_DM,
                                                                              tags: [
                                                                                [
                                                                                  'a',
                                                                                  threadCubit.getAnchor()
                                                                                ]
                                                                              ],
                                                                              content: _replyController.text.trim()),
                                                                          null)
                                                                      .nip01Event
                                                                ]);
                                                              },
                                                        child: Text('Send'))
                                                  ]);
                                            })))
                          ],
                        ))));
              });
        }));
  }
}
