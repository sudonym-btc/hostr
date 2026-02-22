import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import 'message/reservation_request/reservation_request.dart';

class ThreadContent extends StatefulWidget {
  final List<ProfileMetadata> participants;
  final Listing listing;
  const ThreadContent({
    super.key,
    required this.participants,
    required this.listing,
  });

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

      final offset = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          offset,
          duration: kAnimationDuration,
          curve: kAnimationCurve,
        );
      } else {
        _scrollController.jumpTo(offset);
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
                return ListView.builder(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                  itemCount: state.threadState.sortedMessages.length,
                  itemBuilder: (listContext, index) {
                    final message = state.threadState.sortedMessages[index];
                    return Column(
                      children: [
                        if (index != 0) SizedBox(height: kDefaultPadding / 2),
                        _buildMessage(context, message: message),
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

  Widget _buildMessage(BuildContext context, {required Message message}) {
    final sender = widget.participants.firstWhere(
      (participant) => participant.pubKey == message.pubKey,
    );
    final activePubKey = getIt<Hostr>().auth.getActiveKey().publicKey;
    final isSentByMe = message.pubKey == activePubKey;

    if (message.child == null) {
      return ThreadMessageWidget(
        sender: sender,
        item: message,
        isSentByMe: isSentByMe,
      );
    } else if (message.child is EscrowServiceSelected) {
      return Container();
    } else if (message.child is ReservationRequest) {
      return ThreadReservationRequestWidget(
        sender: sender,
        item: message,
        isSentByMe: isSentByMe,
      );
    }
    return Text('Unknown message type');
  }
}
