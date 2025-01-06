import 'package:flutter/material.dart';

class MoneyInFlight extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MoneyInFlightState();
  }
}

class _MoneyInFlightState extends State<MoneyInFlight> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Money in flight'),
    );
  }
}
