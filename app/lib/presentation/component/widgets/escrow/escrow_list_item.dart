import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';

class EscrowListItemWidget extends StatefulWidget {
  final Escrow entity;
  const EscrowListItemWidget({super.key, required this.entity});

  @override
  _EscrowListItemWidgetState createState() => _EscrowListItemWidgetState();
}

class _EscrowListItemWidgetState extends State<EscrowListItemWidget> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.handshake),
      title: Text('Escrow x'),
      subtitle: Text('Escrow description'),
      trailing: Checkbox(
        value: _isChecked,
        onChanged: (bool? value) {
          setState(() {
            _isChecked = value ?? false;
          });
        },
      ),
    );
  }
}
