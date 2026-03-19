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
  final VoidCallback? onBack;

  const ThreadView({super.key, this.embedded = false, this.onBack});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThreadCubit, ThreadCubitState>(
      builder: (context, state) {
        return ThreadReadyWidget(
          embedded: embedded,
          onBack: onBack,
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
  final VoidCallback? onBack;

  const ThreadReadyWidget({
    super.key,
    required this.participants,
    required this.counterparties,
    this.embedded = false,
    this.onBack,
  });

  Widget _buildContent(BuildContext context, Color appBarColor) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          AppSurface(
            child: SafeArea(
              top: false,
              bottom: false,
              child: AppBar(
                automaticallyImplyLeading: false,
                leading: onBack != null ? BackButton(onPressed: onBack) : null,
                // leadingWidth: onBack == null ? null : null,
                titleSpacing: onBack == null
                    ? AppSpacing.of(context).lg
                    : AppSpacing.of(context).xs,
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
            AppSurface(
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
    final appBarColor = AppSurface.of(context);
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
