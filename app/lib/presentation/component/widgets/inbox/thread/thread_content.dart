import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

Set<Type> kHiddenMessageTypes = {EscrowServiceSelected, Reservation};

class ThreadContent extends StatefulWidget {
  final List<ProfileMetadata> participants;
  const ThreadContent({super.key, required this.participants});

  @override
  State<ThreadContent> createState() => _ThreadContentState();
}

class _ThreadContentState extends State<ThreadContent> {
  final ScrollController _scrollController = ScrollController();

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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Returns the pubkeys that appear for the first time at [index].
  /// Index 0 is skipped — the first message establishes initial participants
  /// and does not count as a "join" event.
  List<String> _newParticipantsAt(int index, List<Message> messages) {
    if (index == 0) return const [];
    final seenBefore = <String>{};
    for (var i = 0; i < index; i++) {
      seenBefore.add(messages[i].pubKey);
      seenBefore.addAll(messages[i].pTags);
    }
    final current = {messages[index].pubKey, ...messages[index].pTags};
    return current.difference(seenBefore).toList();
  }

  /// Resolves a human-readable display name for [pubkey].
  /// Returns "You" for the active user, the profile name if available,
  /// or a truncated pubkey as fallback.
  String _displayName(String pubkey) {
    final activePubKey = getIt<Hostr>().auth.getActiveKey().publicKey;
    if (pubkey == activePubKey) return 'You';
    ProfileMetadata? profile;
    try {
      profile = widget.participants.firstWhere((p) => p.pubKey == pubkey);
    } catch (_) {
      // Not yet loaded or escrow bot — fall back to truncated key.
    }
    final name = profile?.metadata.name ?? profile?.metadata.displayName;
    return (name != null && name.isNotEmpty)
        ? name
        : '${pubkey.substring(0, 8)}…';
  }

  /// Whether [message] is a visible text message (i.e. would be rendered
  /// by [_buildMessage]).
  bool _isVisibleMessage(Message message) {
    if (message.child == null) return true; // plain text

    // Structured messages still depend on sender/profile-specific rendering.
    final hasSender = widget.participants.any(
      (p) => p.pubKey == message.pubKey,
    );
    if (!hasSender) return false;

    if (message.child is EscrowServiceSelected) return false;
    if (message.child is Reservation &&
        (message.child as Reservation).isNegotiation)
      return false;
    return true; // unknown type still renders
  }

  /// Whether [message] should show a profile header (avatar + timestamp).
  ///
  /// In group threads with more than two participants, always show it so the
  /// sender is unambiguous. Otherwise, show it when it's the first visible
  /// message or more than 1 hour after the previous *visible* message.
  bool _showProfileHeader(
    Message message,
    List<Message> reversed,
    int index, {
    required bool alwaysShow,
  }) {
    // Walk backwards (older) through the reversed list to find the previous
    // visible message.
    Message? previous;
    for (var i = index + 1; i < reversed.length; i++) {
      if (_isVisibleMessage(reversed[i])) {
        previous = reversed[i];
        break;
      }
    }
    if (previous == null) return true;

    if (alwaysShow) {
      return previous.pubKey != message.pubKey;
    }

    final currentTime = DateTime.fromMillisecondsSinceEpoch(
      message.createdAt * 1000,
    );
    final previousTime = DateTime.fromMillisecondsSinceEpoch(
      previous.createdAt * 1000,
    );
    return currentTime.difference(previousTime).inHours >= 1;
  }

  /// Finds the [ProfileMetadata] for a given pubkey from the participants list.
  ProfileMetadata? _findProfile(String pubkey) {
    try {
      return widget.participants.firstWhere((p) => p.pubKey == pubkey);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPadding(
      bottom: 0,
      top: 0,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: BlocConsumer<ThreadCubit, ThreadCubitState>(
              listenWhen: (previous, current) {
                return current.threadState.sortedMessages.length >
                    previous.threadState.sortedMessages.length;
              },
              listener: (context, state) {
                _scrollToBottom();
              },
              builder: (context, state) {
                final messages = state.threadState.sortedMessages;
                final reversed = messages.reversed.toList();
                final alwaysShowProfileHeader =
                    state.threadState.participantPubkeys.length > 2;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(vertical: kSpace4),
                  itemCount: reversed.length,
                  itemBuilder: (listContext, index) {
                    final message = reversed[index];
                    final showHeader = _showProfileHeader(
                      message,
                      reversed,
                      index,
                      alwaysShow: alwaysShowProfileHeader,
                    );
                    // Map back to the chronological index for join-banner logic.
                    final chronoIndex = messages.length - 1 - index;
                    final newPubkeys = _newParticipantsAt(
                      chronoIndex,
                      messages,
                    );
                    final messageWidget = _buildMessage(
                      context,
                      message: message,
                    );
                    if (messageWidget == null) {
                      return Container();
                    }
                    final activePubKey = getIt<Hostr>().auth
                        .getActiveKey()
                        .publicKey;
                    final isSentByMe = message.pubKey == activePubKey;
                    return Column(
                      children: [
                        if (index != reversed.length - 1) Gap.vertical.md(),
                        for (final pubkey in newPubkeys)
                          _JoinedBanner(name: _displayName(pubkey)),
                        if (showHeader)
                          _MessageProfileHeader(
                            profile: _findProfile(message.pubKey),
                            name: _displayName(message.pubKey),
                            timestamp: DateTime.fromMillisecondsSinceEpoch(
                              message.createdAt * 1000,
                            ),
                            isSentByMe: isSentByMe,
                          ),
                        messageWidget,
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

  Widget? _buildMessage(
    BuildContext context, {
    required Message message,
    bool showSenderLabel = false,
  }) {
    final sender = _findProfile(message.pubKey);
    final activePubKey = getIt<Hostr>().auth.getActiveKey().publicKey;
    final isSentByMe = message.pubKey == activePubKey;

    if (message.child is EscrowServiceSelected) {
      return null;
    } else if (message.child is Reservation &&
        (message.child as Reservation).isNegotiation) {
      return null;
      // return ThreadReservationRequestWidget(
      //   sender: sender,
      //   item: message,
      //   isSentByMe: isSentByMe,
      // );
    }

    if (message.content.trim().isNotEmpty) {
      return ThreadMessageWidget(
        sender: sender,
        item: message,
        isSentByMe: isSentByMe,
        showSenderLabel: showSenderLabel && !isSentByMe,
      );
    }

    return Text(AppLocalizations.of(context)!.unknownMessageType);
  }
}

/// Profile avatar + timestamp shown when > 1 hour has passed since the
/// previous message.
class _MessageProfileHeader extends StatelessWidget {
  final ProfileMetadata? profile;
  final String name;
  final DateTime timestamp;
  final bool isSentByMe;

  const _MessageProfileHeader({
    required this.profile,
    required this.name,
    required this.timestamp,
    required this.isSentByMe,
  });

  @override
  Widget build(BuildContext context) {
    final picture = profile?.metadata.picture;
    final avatar = CircleAvatar(
      radius: 14,
      backgroundImage: picture != null ? NetworkImage(picture) : null,
      child: picture == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: Theme.of(context).textTheme.labelSmall,
            )
          : null,
    );
    final label = Text(
      '$name · ${formatDateLong(timestamp)}',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: kSpace4, bottom: kSpace2),
      child: Row(
        mainAxisAlignment: isSentByMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: isSentByMe
            ? [label, const SizedBox(width: 8), avatar]
            : [avatar, const SizedBox(width: 8), label],
      ),
    );
  }
}

/// A centred divider row shown when a new participant joins the thread.
class _JoinedBanner extends StatelessWidget {
  final String name;
  const _JoinedBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return CustomPadding.vertical.md(
      child: Row(
        children: [
          Expanded(child: Container()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$name joined',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }
}
