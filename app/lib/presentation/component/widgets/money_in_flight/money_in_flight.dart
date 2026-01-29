import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/evm/evm_chain.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:models/main.dart';

class MoneyInFlightWidget extends StatefulWidget {
  const MoneyInFlightWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MoneyInFlightWidgetState();
  }
}

class _MoneyInFlightWidgetState extends State<MoneyInFlightWidget> {
  num? balance;
  bool isLoading = false;
  String? error;
  Timer? _timer;
  Duration refreshAfter = Duration(seconds: 100);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(refreshAfter, (timer) => _fetchBalance());
    _fetchBalance();
  }

  void _fetchBalance() {
    setState(() {
      isLoading = true;
      error = null;
    });
    getIt<Hostr>().evm
        .getBalance()
        .then((value) {
          setState(() {
            balance = value;
            isLoading = false;
          });
        })
        .catchError((e) {
          setState(() {
            error = e.toString();
            isLoading = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return CircularProgressIndicator();
    }
    if (error != null) {
      return Text('Error: $error', style: TextStyle(color: Colors.red));
    }
    return Visibility(
      key: Key('money-in-flight-widget-key'),
      maintainState: false,
      child: Column(
        children: [
          SizedBox(height: DEFAULT_PADDING.toDouble() / 2),
          Text(
            '${formatAmount(Amount(value: convertWeiToSatoshi(balance!.toDouble()), currency: Currency.BTC), exact: false) ?? 'loading'}',
          ),
        ],
      ),
    );
  }
}
