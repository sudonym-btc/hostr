import 'package:flutter/material.dart';

class RelayListItem extends StatelessWidget {
  final String relay;
  const RelayListItem({super.key, required this.relay});

  @override
  Widget build(BuildContext context) {
    return Text(relay);
  }
}
