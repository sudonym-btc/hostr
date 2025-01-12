import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

import 'relay_list_item.dart';

class RelayList extends StatefulWidget {
  const RelayList({Key? key}) : super(key: key);

  @override
  _RelayListState createState() => _RelayListState();
}

class _RelayListState extends State<RelayList> {
  RelayStorage relayStorage = getIt<RelayStorage>();
  List<String>? relays;

  @override
  void initState() {
    super.initState();
    relayStorage.get().then((r) {
      print("Relays: $r");
      setState(() {
        relays = r;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (relays == null)
          CircularProgressIndicator()
        else
          for (var relay in relays!) RelayListItem(relay: relay),
      ],
    );
  }
}
