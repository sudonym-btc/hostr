import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:models/main.dart';

class EscrowListItemWidget extends StatefulWidget {
  final EscrowService entity;
  const EscrowListItemWidget({super.key, required this.entity});

  @override
  EscrowListItemWidgetState createState() => EscrowListItemWidgetState();
}

class EscrowListItemWidgetState extends State<EscrowListItemWidget> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.all(0),
      leading: Icon(Icons.handshake),
      title: Text(AppLocalizations.of(context)!.escrow),
      subtitle: Text(AppLocalizations.of(context)!.escrow),
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
