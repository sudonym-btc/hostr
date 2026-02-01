import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/providers/nostr/thread.provider.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_view.dart';

@RoutePage()
class ThreadScreen extends StatelessWidget {
  final String id;
  // ignore: use_key_in_widget_constructors
  const ThreadScreen({@pathParam required this.id});

  @override
  Widget build(BuildContext context) {
    return ThreadProvider(threadId: id, child: ThreadView());
  }
}
