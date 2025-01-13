import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

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
  @override
  initState() {
    super.initState();
    keyStorage.getActiveKeyPair().then((value) {
      r.getBalance(getEthCredentials(value!.private).address).then(
        (val) {
          setState(() {
            balance = val;
          });
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Money in flight: ${balance ?? 'loading'}'),
    );
  }
}
