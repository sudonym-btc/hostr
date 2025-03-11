import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';

class RelayListItemWidget extends StatefulWidget {
  final RelayInfo? relay;
  final RelayConnectivity connectivity;
  const RelayListItemWidget(
      {super.key, required this.relay, required this.connectivity});

  @override
  _RelayListItemWidgetState createState() => _RelayListItemWidgetState();
}

class _RelayListItemWidgetState extends State<RelayListItemWidget> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.connectivity.relayTransport?.isOpen() == true
              ? Colors.green
              : Colors.orange,
          shape: BoxShape.circle,
        ),
      ),
      title: Row(
        children: [
          // widget.relay?.icon != null
          //     ? Image.network(widget.relay!.icon)
          //     : Icon(Icons.wifi),
          // SizedBox(width: 8), // Add some spacing between the icon and the text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.relay?.name ?? "Unnamed"),
              Text(widget.connectivity.url,
                  style: Theme.of(context).textTheme.bodySmall),
              Text(widget.relay?.description ?? 'No description',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
