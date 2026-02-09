import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/amount.dart';

class MoneyInFlightWidget extends StatefulWidget {
  const MoneyInFlightWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MoneyInFlightWidgetState();
  }
}

class _MoneyInFlightWidgetState extends State<MoneyInFlightWidget> {
  late final Stream<BitcoinAmount> _balanceStream;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _balanceStream = getIt<Hostr>().evm.subscribeBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      key: Key('money-in-flight-widget-key'),
      maintainState: false,
      child: Column(
        children: [
          SizedBox(height: kDefaultPadding.toDouble() / 2),

          StreamBuilder(
            stream: _balanceStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }
              return Text(
                formatAmount(
                  Amount(
                    value: snapshot.data!.getInSats,
                    currency: Currency.BTC,
                  ),
                  exact: false,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
