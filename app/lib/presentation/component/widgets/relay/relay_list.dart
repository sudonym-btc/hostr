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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: DEFAULT_PADDING.toDouble() / 2),
        StreamBuilder(
          stream: getIt<Hostr>().relays.connectivity(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData) {
              return const SizedBox();
            }

            final connectivityList = snapshot.data;
            return Column(
              children: (connectivityList?.values ?? []).map((connectivity) {
                return RelayListItemWidget(
                  relay: connectivity.relayInfo,
                  connectivity: connectivity,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
