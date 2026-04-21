import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_view.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:provider/provider.dart';

@RoutePage()
class ThreadScreen extends StatelessWidget {
  final String anchor;
  // ignore: use_key_in_widget_constructors
  const ThreadScreen({@pathParam required this.anchor});

  @override
  Widget build(BuildContext context) {
    final isExpanded = AppLayoutSpec.of(context).isExpanded;
    final threads = getIt<Hostr>().messaging.threads;
    final onBack = isExpanded
        ? null
        : () {
            context.router.root.navigate(
              TabShellRoute(children: [const InboxRoute()]),
            );
          };

    Widget buildForThread(Thread? thread) {
      if (thread == null) {
        return _MissingThreadView(embedded: isExpanded, onBack: onBack);
      }

      return Provider<Thread>.value(
        key: ValueKey(anchor),
        value: thread,
        child: ThreadView(
          key: ValueKey('${isExpanded ? "embedded" : "standalone"}-$anchor'),
          embedded: isExpanded,
          onBack: onBack,
        ),
      );
    }

    final existingThread = threads.threads[anchor];
    if (existingThread != null) return buildForThread(existingThread);

    return StreamBuilder<Thread>(
      stream: threads.threadStream,
      builder: (context, _) => buildForThread(threads.threads[anchor]),
    );
  }
}

class _MissingThreadView extends StatelessWidget {
  final bool embedded;
  final VoidCallback? onBack;

  const _MissingThreadView({required this.embedded, this.onBack});

  @override
  Widget build(BuildContext context) {
    final body = EmtyResultsWidget(
      leading: Icon(
        Icons.forum_outlined,
        size: kIconHero,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: 'Conversation unavailable',
      subtitle: 'This conversation could not be found on this device.',
      action: onBack == null
          ? null
          : TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to inbox'),
            ),
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: AppSurface.of(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: onBack != null ? BackButton(onPressed: onBack) : null,
      ),
      body: body,
    );
  }
}
