import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:provider/provider.dart';

class ThreadContent extends StatefulWidget {
  const ThreadContent({super.key});

  @override
  State<ThreadContent> createState() => _ThreadContentState();
}

class _ThreadContentState extends State<ThreadContent> {
  final ScrollController _scrollController = ScrollController();
  int _prevEventCount = 0;

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      // reverse:true means 0 is the visual bottom (newest messages).
      if (animated) {
        _scrollController.animateTo(
          0,
          duration: kAnimationDuration,
          curve: kAnimationCurve,
        );
      } else {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollToBottom(animated: false);
    // Mark the conversation as read when it's opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<Thread>().markAsRead();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Returns the pubkeys that appear for the first time at [index].
  /// Index 0 is skipped — the first event establishes initial participants
  /// and does not count as a "join" event.
  List<String> _newParticipantsAt(int index, List<Event> events) {
    if (index == 0) return const [];
    final seenBefore = <String>{};
    for (var i = 0; i < index; i++) {
      seenBefore.add(events[i].pubKey);
      seenBefore.addAll(events[i].pTags);
    }
    final current = {events[index].pubKey, ...events[index].pTags};
    return current.difference(seenBefore).toList();
  }

  /// Whether [event] is a visible event (i.e. would be rendered
  /// by [_buildEvent]).
  bool _isVisibleEvent(Event event) {
    return event is Message && event.child == null;
  }

  /// Whether [message] should show a profile header (avatar + timestamp).
  ///
  /// In group threads with more than two participants, always show it so the
  /// sender is unambiguous. Otherwise, show it when it's the first visible
  /// message or more than 1 hour after the previous *visible* message.
  bool _showProfileHeader(
    Event event,
    List<Event> reversed,
    int index, {
    required bool alwaysShow,
  }) {
    Event? previous;
    for (var i = index + 1; i < reversed.length; i++) {
      if (_isVisibleEvent(reversed[i])) {
        previous = reversed[i];
        break;
      }
    }
    if (previous == null) return true;

    if (alwaysShow) {
      return previous.pubKey != event.pubKey;
    }

    final currentTime = DateTime.fromMillisecondsSinceEpoch(
      event.createdAt * 1000,
    );
    final previousTime = DateTime.fromMillisecondsSinceEpoch(
      previous.createdAt * 1000,
    );
    return currentTime.difference(previousTime).inHours >= 1;
  }

  @override
  Widget build(BuildContext context) {
    final thread = context.read<Thread>();
    return CustomPadding(
      bottom: 0,
      top: 0,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: StreamBuilder<ThreadState>(
              stream: thread.state,
              initialData: thread.state.value,
              builder: (context, snapshot) {
                final state = snapshot.data!;
                final prevLength = _prevEventCount;
                final currentLength = state.events.length;
                if (currentLength > prevLength) {
                  _scrollToBottom();
                  thread.markAsRead();
                }
                _prevEventCount = currentLength;

                final events = state.readableEvents;
                final reversed = events.reversed.toList();
                final alwaysShowProfileHeader =
                    state.participantPubkeys.length > 2;

                final myPubKey = getIt<Hostr>().auth.getActiveKey().publicKey;
                final seenUntil = state.seenUntil;
                final counterparties = state.counterpartyPubkeys;
                String? lastReadMessageId;
                if (counterparties.isNotEmpty) {
                  int? minSeen;
                  for (final cp in counterparties) {
                    final seen = seenUntil[cp];
                    if (seen == null) {
                      minSeen = null;
                      break;
                    }
                    if (minSeen == null || seen < minSeen) {
                      minSeen = seen;
                    }
                  }
                  if (minSeen != null) {
                    for (final evt in events.reversed) {
                      if (evt.pubKey == myPubKey && evt.createdAt <= minSeen) {
                        lastReadMessageId = evt.id;
                        break;
                      }
                    }
                  }
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(vertical: kSpace4),
                  itemCount: reversed.length,
                  itemBuilder: (listContext, index) {
                    final event = reversed[index];
                    final showHeader = _showProfileHeader(
                      event,
                      reversed,
                      index,
                      alwaysShow: alwaysShowProfileHeader,
                    );
                    final chronoIndex = events.length - 1 - index;
                    final newPubkeys = _newParticipantsAt(chronoIndex, events);
                    final messageWidget = _buildEvent(context, event: event);
                    if (messageWidget == null) {
                      return Container();
                    }
                    final activePubKey = getIt<Hostr>().auth
                        .getActiveKey()
                        .publicKey;
                    final isSentByMe = event.pubKey == activePubKey;
                    return Column(
                      children: [
                        if (index != reversed.length - 1) Gap.vertical.md(),
                        for (final pubkey in newPubkeys)
                          _JoinedBanner(pubkey: pubkey),
                        if (showHeader)
                          _MessageProfileHeader(
                            pubkey: event.pubKey,
                            timestamp: DateTime.fromMillisecondsSinceEpoch(
                              event.createdAt * 1000,
                            ),
                            isSentByMe: isSentByMe,
                          ),
                        messageWidget,
                        if (isSentByMe && event.id == lastReadMessageId)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2, right: 4),
                              child: Icon(
                                Icons.done_all,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildEvent(
    BuildContext context, {
    required Event event,
    bool showSenderLabel = false,
  }) {
    final activePubKey = getIt<Hostr>().auth.getActiveKey().publicKey;
    final isSentByMe = event.pubKey == activePubKey;

    if (event is Message && event.child == null) {
      if (event.content.trim().isNotEmpty) {
        return ThreadMessageWidget(
          item: event,
          isSentByMe: isSentByMe,
          showSenderLabel: showSenderLabel && !isSentByMe,
        );
      }
      return Text(AppLocalizations.of(context)!.unknownMessageType);
    }
    // Reservation, EscrowServiceSelected, SeenStatus — not rendered.
    return null;
  }
}

/// Profile avatar + timestamp shown when > 1 hour has passed since the
/// previous message.
class _MessageProfileHeader extends StatelessWidget {
  final String pubkey;
  final DateTime timestamp;
  final bool isSentByMe;

  const _MessageProfileHeader({
    required this.pubkey,
    required this.timestamp,
    required this.isSentByMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: kSpace4, bottom: kSpace2),
      child: ProfileProvider(
        pubkey: pubkey,
        builder: (context, profile) {
          if (profile.data == null) return SizedBox.shrink();
          final picture = profile.data!.metadata.picture;
          final name = profile.data!.metadata.getName();
          final avatar = AppAvatar.xs(
            image: picture,
            pubkey: profile.data!.pubKey,
            label: name.isNotEmpty ? name : '?',
          );
          final label = Text(
            '$name · ${formatDateLong(timestamp)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
          return Row(
            mainAxisAlignment: isSentByMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: isSentByMe
                ? [label, const SizedBox(width: 8), avatar]
                : [avatar, const SizedBox(width: 8), label],
          );
        },
      ),
    );
  }
}

/// A centred divider row shown when a new participant joins the thread.
class _JoinedBanner extends StatelessWidget {
  final String pubkey;
  const _JoinedBanner({required this.pubkey});

  @override
  Widget build(BuildContext context) {
    return CustomPadding.vertical.md(
      child: Row(
        children: [
          Expanded(child: Container()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ProfileProvider(
              pubkey: pubkey,
              builder: (context, profile) {
                if (profile.data == null) return SizedBox.shrink();
                final name = profile.data!.metadata.getName();
                return Text(
                  '$name joined',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                );
              },
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }
}
