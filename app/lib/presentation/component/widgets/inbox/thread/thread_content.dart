import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

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
                final isGroupChat = widget.participants.length > 2;
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
                    // Map back to the chronological index for join-banner logic.
                    final chronoIndex = messages.length - 1 - index;
                    final newPubkeys = _newParticipantsAt(
                      chronoIndex,
                      messages,
                    );
                    return Column(
                      children: [
                        Gap.vertical.md(),
                        for (final pubkey in newPubkeys)
                          _JoinedBanner(name: _displayName(pubkey)),
                        _buildMessage(
                          context,
                          message: message,
                          showSenderLabel: isGroupChat,
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

  Widget _buildMessage(
    BuildContext context, {
    required Message message,
    bool showSenderLabel = false,
  }) {
    ProfileMetadata? sender;
    try {
      sender = widget.participants.firstWhere(
        (participant) => participant.pubKey == message.pubKey,
      );
    } catch (_) {
      // Sender not yet resolved (e.g. escrow service); skip rendering.
      return const SizedBox.shrink();
    }
    final activePubKey = getIt<Hostr>().auth.getActiveKey().publicKey;
    final isSentByMe = message.pubKey == activePubKey;

    if (message.child == null) {
      return ThreadMessageWidget(
        sender: sender,
        item: message,
        isSentByMe: isSentByMe,
        showSenderLabel: showSenderLabel && !isSentByMe,
      );
    } else if (message.child is EscrowServiceSelected) {
      return Container();
    } else if (message.child is Reservation &&
        (message.child as Reservation).parsedContent.isNegotiation) {
      return Container();
      // return ThreadReservationRequestWidget(
      //   sender: sender,
      //   item: message,
      //   isSentByMe: isSentByMe,
      // );
    }
    return Text(AppLocalizations.of(context)!.unknownMessageType);
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
