import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_content.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_reply.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_popup.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:hostr/presentation/main.dart';
import 'package:models/main.dart';

class ThreadView extends StatelessWidget {
  const ThreadView({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThreadCubit, ThreadCubitState>(
      builder: (context, state) {
        final participantsReady = state.participantStates.every(
          (p) => p.data != null,
        );

        if (!participantsReady) {
          return Scaffold(
            body: SafeArea(child: Center(child: AppLoadingIndicator.large())),
          );
        }

        return ThreadReadyWidget(
          participants: state.participantStates.map((e) => e.data!).toList(),
          counterparties: state.counterpartyStates.map((e) => e.data!).toList(),
        );
      },
    );
  }
}

class ThreadReadyWidget extends StatelessWidget {
  final List<ProfileMetadata> participants;
  final List<ProfileMetadata> counterparties;

  const ThreadReadyWidget({
    super.key,
    required this.participants,
    required this.counterparties,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        appBar: AppBar(
          titleSpacing: 0,
          title: ThreadHeaderWidget(
            counterparties: counterparties,
            onCounterpartyTap: (profile) =>
                ProfilePopup.show(context, profile.pubKey),
          ),
        ),
        bottomNavigationBar: AnimatedPadding(
          duration: const Duration(milliseconds: 0),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            child: CustomPadding(top: 1, bottom: 1, child: ThreadReplyWidget()),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: ThreadContent(participants: participants)),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.82),
                    child: const TradeHeader(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
