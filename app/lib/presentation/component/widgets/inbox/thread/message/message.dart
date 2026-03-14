import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:models/main.dart';

class ThreadMessageWidget extends StatelessWidget {
  final ProfileMetadata? sender;
  final Message item;
  final bool isSentByMe;

  /// When true, shows the sender's display name above the message bubble.
  /// Intended for group chats with more than two participants.
  final bool showSenderLabel;

  const ThreadMessageWidget({
    super.key,
    required this.sender,
    required this.item,
    required this.isSentByMe,
    this.showSenderLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final senderName =
        sender?.metadata.name ?? sender?.metadata.displayName ?? '';
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isSentByMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSenderLabel && senderName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2, left: 4, right: 4),
              child: Text(
                senderName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          MessageContainer(
            isSentByMe: isSentByMe,
            child: Text(
              item.content,
              style: TextStyle(
                color: isSentByMe
                    ? colorScheme.onSecondary
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(kDefaultPadding / 3),
      decoration: BoxDecoration(
        color: isSentByMe
            ? colorScheme.secondary
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(kDefaultPadding / 3),
      ),
      child: child,
    );
  }
}
