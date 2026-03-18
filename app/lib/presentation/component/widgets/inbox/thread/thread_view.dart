import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_content.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_reply.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_popup.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/presentation/main.dart';
import 'package:models/main.dart';

class ThreadView extends StatelessWidget {
  final bool embedded;

  const ThreadView({super.key, this.embedded = false});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThreadCubit, ThreadCubitState>(
      builder: (context, state) {
        return ThreadReadyWidget(
          embedded: embedded,
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
  final bool embedded;

  const ThreadReadyWidget({
    super.key,
    required this.participants,
    required this.counterparties,
    this.embedded = false,
  });

  bool _hasImpliedBackAction(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route?.impliesAppBarDismissal ?? false) {
      return true;
    }

    return Navigator.maybeOf(context)?.canPop() ?? false;
  }

  Widget _buildContent(BuildContext context, Color appBarColor) {
    final theme = Theme.of(context);
    final hasImpliedBackAction = _hasImpliedBackAction(context);
    final reservedLeadingWidth =
        theme.appBarTheme.leadingWidth ?? AppSpacing.of(context).sm;

    final appBarColor = AppPaneTheme.stepped(context, 2);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          Material(
            color: appBarColor,
            child: SafeArea(
              top: false,
              bottom: false,
              child: AppBar(
                automaticallyImplyLeading: hasImpliedBackAction,
                leading: hasImpliedBackAction
                    ? null
                    : SizedBox(width: reservedLeadingWidth),
                leadingWidth: reservedLeadingWidth,
                titleSpacing: 0,
                surfaceTintColor: Colors.transparent,
                backgroundColor: appBarColor,
                title: ThreadHeaderWidget(
                  counterparties: counterparties,
                  onCounterpartyTap: (profile) =>
                      ProfilePopup.show(context, profile.pubKey),
                ),
              ),
            ),
          ),
          if (context.read<ThreadCubit>().thread.isTradeCandidate)
            Material(
              color: appBarColor,
              child: TradeHeader(
                tradeId: context.read<ThreadCubit>().thread.anchor,
              ),
            ),
          Expanded(child: ThreadContent(participants: participants)),
          Padding(
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = AppPaneTheme.of(context);
    if (embedded) {
      return ColoredBox(
        color: Colors.transparent,
        child: _buildContent(context, appBarColor),
      );
    }

    return Scaffold(
      backgroundColor: appBarColor,
      body: _buildContent(context, appBarColor),
    );
  }
}
