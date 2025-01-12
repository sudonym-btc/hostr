import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';

class EscrowListItem extends StatefulWidget {
  final Escrow entity;
  const EscrowListItem({super.key, required this.entity});

  @override
  _EscrowListItemState createState() => _EscrowListItemState();
}

class _EscrowListItemState extends State<EscrowListItem> {
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
