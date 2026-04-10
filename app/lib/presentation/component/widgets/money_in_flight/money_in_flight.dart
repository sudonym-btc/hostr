import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

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
    return StreamBuilder<List<TokenAmount>>(
      key: Key('money-in-flight-widget-key'),
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
    );
  }
}

class _BalanceList extends StatelessWidget {
  final List<TokenAmount> balances;

  const _BalanceList({super.key, required this.balances});

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group balances by resolved denomination so that, e.g., native RBTC and
    // ERC-20 tBTC both collapse into a single "₿" row.
    final grouped = _groupByDenomination(balances);

    if (grouped.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in grouped)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              formatAmount(entry, exact: false),
              style: Theme.of(
                context,
              ).textTheme.displayMedium!.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  /// Collapse [TokenAmount]s into one [DenominatedAmount] per resolved
  /// denomination (BTC, USD, ETH, …).
  ///
  /// Tokens with different decimal scales (e.g. 8-dec Lightning BTC vs
  /// 18-dec RBTC) are rescaled to the highest precision before summing.
  static List<DenominatedAmount> _groupByDenomination(
    List<TokenAmount> balances,
  ) {
    final resolver = TokenDisplayResolver(
      getIt<Hostr>().evm.configuredChains.map((c) => c.config),
    );

    final map = <String, DenominatedAmount>{};
    for (final balance in balances) {
      if (balance.value <= BigInt.zero) continue;
      final info = resolver.resolve(balance.token);
      final denom = info.denomination.isNotEmpty ? info.denomination : 'BTC';
      final denominated = balance.toDenominated(denomination: denom);
      map.update(denom, (existing) {
        // Align decimal scales before adding.
        final targetDecimals = existing.decimals >= denominated.decimals
            ? existing.decimals
            : denominated.decimals;
        return existing.rescale(targetDecimals) +
            denominated.rescale(targetDecimals);
      }, ifAbsent: () => denominated);
    }
    return map.values.toList();
  }
}
