import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:models/main.dart';

class ThreadMessageWidget extends StatelessWidget {
  final ProfileMetadata sender;
  final Message item;
  final bool isSentByMe;

  const ThreadMessageWidget({
    super.key,
    required this.sender,
    required this.item,
    required this.isSentByMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: MessageContainer(
        isSentByMe: isSentByMe,
        child: Text(
          item.content,
          style: TextStyle(
            color: isSentByMe
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class MessageContainer extends StatelessWidget {
  final Widget child;
  final bool isSentByMe;

  const MessageContainer({
    super.key,
    required this.child,
    required this.isSentByMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(kDefaultPadding / 3),
      decoration: BoxDecoration(
        color: isSentByMe
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(kDefaultPadding / 3),
      ),
      child: child,
    );
  }
}
