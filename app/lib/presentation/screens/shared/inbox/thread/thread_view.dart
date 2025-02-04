import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/screens/shared/inbox/thread/giftwraps/message.dart';

import 'giftwraps/reservation_request.dart';

class ThreadView extends StatelessWidget {
  final String a;
  // ignore: use_key_in_widget_constructors
  const ThreadView({required this.a});

  @override
  Widget build(BuildContext context) {
    ThreadCubit threadCubit = BlocProvider.of<ThreadOrganizerCubit>(context)
        .state
        .threads
        .firstWhere((element) => element.getAnchor() == a);

    return BlocProvider<ThreadCubit>(
        create: (context) => threadCubit,
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
                return Scaffold(
                    appBar: AppBar(
                        title: ThreadHeaderWidget(
                            title: profileState.name ?? 'Loading',
                            subtitle: 'jeremy@nostrplebs.com')),
                    body: SafeArea(
                        child: Column(
                      children: [
                        Expanded(
                            child: ListView.builder(
                                itemCount: state.messages.length,
                                itemBuilder: (listContext, index) {
                                  if ((state.messages[index].child as Seal)
                                      .child is Message) {
                                    return ThreadMessageWidget(
                                        counterpartyPubkey:
                                            threadCubit.getCounterpartyPubkey(),
                                        item: state.messages[index]
                                            as GiftWrap<Seal<Message>>);
                                  } else if ((state.messages[index].child
                                          as Seal)
                                      .child is ReservationRequest) {
                                    return ThreadReservationRequestWidget(
                                        counterparty: profileState,
                                        item: state.messages[index]);
                                  }
                                  return Text('Unknown message type');
                                })),
                        CustomPadding(
                            child: Row(children: [
                          Expanded(
                              child: TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Reply',
                            ),
                          )),
                          FilledButton(onPressed: () {}, child: Text('Send'))
                        ]))
                      ],
                    )));
              });
        }));
  }
}
