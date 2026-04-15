import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_content.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_reply.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_popup.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:provider/provider.dart';

class ThreadView extends StatelessWidget {
  final bool embedded;
  final VoidCallback? onBack;

  const ThreadView({super.key, this.embedded = false, this.onBack});

  @override
  Widget build(BuildContext context) {
    final thread = context.read<Thread>();
    return StreamBuilder<ThreadState>(
      stream: thread.state,
      initialData: thread.state.value,
      builder: (context, snapshot) {
        return ThreadReadyWidget(embedded: embedded, onBack: onBack);
      },
    );
  }
}

class ThreadReadyWidget extends StatelessWidget {
  final bool embedded;
  final VoidCallback? onBack;

  const ThreadReadyWidget({super.key, this.embedded = false, this.onBack});

  Widget _buildContent(BuildContext context, Color appBarColor) {
    final thread = context.read<Thread>();
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
                titleSpacing: onBack == null
                    ? AppSpacing.of(context).lg
                    : AppSpacing.of(context).xs,
                surfaceTintColor: Colors.transparent,
                backgroundColor: appBarColor,
                title: ThreadHeaderWidget(
                  onCounterpartyTap: (profile) =>
                      ProfilePopup.show(context, profile.pubKey),
                ),
              ),
            ),
          ),
          if (thread.isTradeCandidate)
            AppSurface(child: TradeHeader(tradeId: thread.tradeId!)),
          Expanded(child: ThreadContent()),
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
