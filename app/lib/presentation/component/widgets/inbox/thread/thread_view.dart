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
        return ThreadReadyWidget(
          participants: state.participantStates
              .map((e) => e.data)
              .whereType<ProfileMetadata>()
              .toList(),
          counterparties: state.counterpartyStates
              .map((e) => e.data)
              .whereType<ProfileMetadata>()
              .toList(),
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
    final appBarColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        appBar: AppBar(
          titleSpacing: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: appBarColor,
          title: ThreadHeaderWidget(
            counterparties: counterparties,
            onCounterpartyTap: (profile) =>
                ProfilePopup.show(context, profile.pubKey),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(
              context,
            ).bottom.clamp(0, double.infinity),
          ),
          child: SafeArea(
            top: false,
            child: CustomPadding.vertical.sm(
              child: CustomPadding.horizontal.lg(child: ThreadReplyWidget()),
            ),
          ),
        ),
        body: Column(
          children: [
            if (context.read<ThreadCubit>().thread.isTradeCandidate)
              Material(
                color: appBarColor,
                child: TradeHeader(
                  tradeId: context.read<ThreadCubit>().thread.anchor,
                ),
              ),
            Expanded(child: ThreadContent(participants: participants)),
          ],
        ),
      ),
    );
  }
}
