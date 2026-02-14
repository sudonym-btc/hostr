import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:timeago/timeago.dart' as timeago;

class InboxItem extends StatelessWidget {
  final Thread thread;

  const InboxItem({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThreadCubit(thread: thread),
      child: BlocBuilder<ThreadCubit, ThreadCubitState>(
        builder: (context, state) {
          final lastDateTime = thread.getLastDateTime;
          final lastMessage = thread.getLatestMessage;
          final subtitle = Text(
            (lastMessage != null &&
                        lastMessage.pubKey ==
                            thread.auth.activeKeyPair!.publicKey
                    ? 'You: '
                    : '') +
                (lastMessage?.child is ReservationRequest
                    ? 'Reservation Request'
                    : lastMessage?.content ?? ''),
          );
          return ListTile(
            leading: ProfileAvatars(
              profiles: state.counterpartyStates
                  .where((c) => c.data != null)
                  .map((c) => c.data!)
                  .toList(),
            ),
            title: Text(
              state.counterpartyStates
                  .where((c) => c.data != null)
                  .map((c) => c.data!.metadata.getName())
                  .toList()
                  .join(', '),
            ),

            subtitle: subtitle,
            trailing: _RelativeTimeText(dateTime: lastDateTime),
            onTap: () {
              AutoRouter.of(context).push(ThreadRoute(anchor: thread.anchor));
            },
          );
        },
      ),
    );
  }
}

class _RelativeTimeText extends StatefulWidget {
  final DateTime dateTime;

  const _RelativeTimeText({required this.dateTime});

  @override
  State<_RelativeTimeText> createState() => _RelativeTimeTextState();
}

class _RelativeTimeTextState extends State<_RelativeTimeText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(timeago.format(widget.dateTime, locale: 'en_short'));
  }
}
