import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/providers/nostr/thread.provider.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_view.dart';

@RoutePage()
class ThreadScreen extends StatelessWidget {
  final String anchor;
  // ignore: use_key_in_widget_constructors
  const ThreadScreen({@pathParam required this.anchor});

  @override
  Widget build(BuildContext context) {
    print('Building ThreadScreen with tag: $anchor');
    return ThreadProvider(threadId: anchor, child: ThreadView());
  }
}
