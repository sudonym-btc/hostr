import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import '../flow/payment/swap/out/swap_out.dart';

class MoneyInFlightWidget extends StatefulWidget {
  const MoneyInFlightWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MoneyInFlightWidgetState();
  }
}

class _MoneyInFlightWidgetState extends State<MoneyInFlightWidget> {
  late final Stream<List<TokenAmount>> _balanceStream;

  @override
  void initState() {
    super.initState();
    _balanceStream = getIt<Hostr>().fundsMonitor.displayBalance$;
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      key: Key('money-in-flight-widget-key'),
      maintainState: false,
      child: Column(
        children: [
          Gap.vertical.md(),

          StreamBuilder<List<TokenAmount>>(
            stream: _balanceStream,
            builder: (context, snapshot) {
              return AnimatedSwitcher(
                duration: kAnimationDuration,
                switchInCurve: kAnimationCurve,
                switchOutCurve: kAnimationCurve,
                child: !snapshot.hasData
                    ? const AppLoadingIndicator.medium(key: ValueKey('loading'))
                    : _BalanceList(
                        key: const ValueKey('ready'),
                        balances: snapshot.data!,
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BalanceList extends StatelessWidget {
  final List<TokenAmount> balances;

  const _BalanceList({super.key, required this.balances});

  @override
  Widget build(BuildContext context) {
    final hasAnyBalance = balances.any((b) => b.value > BigInt.zero);

    if (balances.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final balance in balances)
          if (balance.value > BigInt.zero)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    formatAmount(balance.toDenominated(), exact: false),
                  ),
                  if (hasAnyBalance)
                    FilledButton.tonal(
                      onPressed: () async {
                        final ops = await getIt<Hostr>().evm.swapOutAll();
                        if (!context.mounted) return;
                        if (ops.isNotEmpty) {
                          showAppModal(
                            context,
                            builder: (_) => SwapOutFlowWidget(cubit: ops.first),
                          );
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.withdraw),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}
