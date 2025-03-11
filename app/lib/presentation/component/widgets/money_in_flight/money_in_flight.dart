import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:models/main.dart';

class MoneyInFlightWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MoneyInFlightWidgetState();
  }
}

class _MoneyInFlightWidgetState extends State<MoneyInFlightWidget> {
  Rootstock r = getIt<Rootstock>();
  KeyStorage keyStorage = getIt<KeyStorage>();
  num? balance;
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    Timer.periodic(Duration(seconds: 30), (timer) => _fetchBalance());
  }

  void _fetchBalance() {
    setState(() {
      isLoading = true;
      error = null;
    });
    keyStorage.getActiveKeyPair().then((value) {
      r.getBalance(getEthCredentials(value!.privateKey!).address).then((val) {
        setState(() {
          balance = val;
          isLoading = false;
        });
      }).catchError((e) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      });
    }).catchError((e) {
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
    return Container(
      child: Text(
          '${formatAmount(Amount(value: balance!.toDouble(), currency: Currency.BTC), exact: false) ?? 'loading'}'),
    );
  }
}
