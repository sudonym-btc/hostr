import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

import 'relay_list_item.dart';

class RelayListWidget extends StatefulWidget {
  const RelayListWidget({super.key});

  @override
  RelayListWidgetState createState() => RelayListWidgetState();
}

class RelayListWidgetState extends State<RelayListWidget> {
  RelayStorage relayStorage = getIt<RelayStorage>();
  List<String>? relays;

  @override
  void initState() {
    super.initState();
    relayStorage.get().then((r) {
      setState(() {
        relays = r;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: DEFAULT_PADDING.toDouble() / 2),
        ...getIt<Hostr>().requests.connectivity().map((connectivity) {
          return RelayListItemWidget(
            relay: connectivity.relayInfo,
            connectivity: connectivity,
          );
        }),
      ],
    );
  }
}
