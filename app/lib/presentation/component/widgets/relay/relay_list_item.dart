import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/data/sources/local/relay_storage.dart';
import 'package:hostr/injection.dart';
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
    Uri uri = Uri.parse(widget.connectivity.url);
    String displayHost = uri.host;
    return ListTile(
      contentPadding: EdgeInsets.all(0),
      leading: CircleAvatar(
        backgroundColor: widget.connectivity.relayTransport?.isOpen() == true
            ? Colors.green
            : Colors.orange,
        foregroundImage: widget.relay?.icon != null
            ? Image.network(widget.relay!.icon).image
            : null,
      ),
      trailing: IconButton(
        icon: Icon(Icons.close),
        onPressed: () async {
          widget.connectivity.close();
          getIt<RelayStorage>().set([
            ...await getIt<RelayStorage>().get().then((value) {
              value.remove(widget.connectivity.url);
              return value;
            }),
          ]);
        },
      ),
      //         Container(
      //   width: 10,
      //   height: 10,
      //   decoration: BoxDecoration(
      title: Text(widget.relay?.name ?? displayHost),
      subtitle: Text(widget.connectivity.relayTransport?.isOpen() == true
          ? "Connected"
          : "Disconnected"),
    );
  }
}
