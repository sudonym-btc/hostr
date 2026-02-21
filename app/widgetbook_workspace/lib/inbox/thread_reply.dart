import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_reply.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Initial', type: ThreadReplyView)
Widget threadReplyInitial(BuildContext context) {
  final controller = TextEditingController(
    text: context.knobs.string(label: 'Draft', initialValue: ''),
  );

  return Padding(
    padding: const EdgeInsets.all(16),
    child: ThreadReplyView(
      controller: controller,
      isLoading: false,
      errorText: null,
      sendLabel: context.knobs.string(
        label: 'Send label',
        initialValue: 'Send',
      ),
      onChanged: (_) {},
      onSend: () {},
    ),
  );
}

@widgetbook.UseCase(name: 'Loading', type: ThreadReplyView)
Widget threadReplyLoading(BuildContext context) {
  final controller = TextEditingController(
    text: context.knobs.string(label: 'Draft', initialValue: 'Hello there'),
  );

  return Padding(
    padding: const EdgeInsets.all(16),
    child: ThreadReplyView(
      controller: controller,
      isLoading: true,
      errorText: null,
      sendLabel: context.knobs.string(
        label: 'Send label',
        initialValue: 'Sending to Alice, Bob',
      ),
      onChanged: (_) {},
      onSend: () {},
    ),
  );
}

@widgetbook.UseCase(name: 'Error', type: ThreadReplyView)
Widget threadReplyError(BuildContext context) {
  final controller = TextEditingController(
    text: context.knobs.string(
      label: 'Draft',
      initialValue: 'Retry this message',
    ),
  );

  return Padding(
    padding: const EdgeInsets.all(16),
    child: ThreadReplyView(
      controller: controller,
      isLoading: false,
      errorText: context.knobs.string(
        label: 'Error text',
        initialValue: 'Failed to send message',
      ),
      sendLabel: context.knobs.string(
        label: 'Send label',
        initialValue: 'Send',
      ),
      onChanged: (_) {},
      onSend: () {},
    ),
  );
}
