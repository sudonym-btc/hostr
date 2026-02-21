import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:ndk/entities.dart';

class RelayListItemView extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? iconUrl;
  final bool isConnected;
  final bool canRemove;
  final VoidCallback? onRemove;

  const RelayListItemView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconUrl,
    required this.isConnected,
    required this.canRemove,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.all(0),
      leading: CircleAvatar(
        backgroundColor: isConnected ? Colors.green : Colors.orange,
        foregroundImage: iconUrl != null ? Image.network(iconUrl!).image : null,
      ),
      trailing: canRemove
          ? IconButton(icon: Icon(Icons.close), onPressed: onRemove)
          : null,
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class RelayListItemWidget extends StatefulWidget {
  final RelayInfo? relay;
  final RelayConnectivity connectivity;
  const RelayListItemWidget({
    super.key,
    required this.relay,
    required this.connectivity,
  });

  @override
  RelayListItemWidgetState createState() => RelayListItemWidgetState();
}

class RelayListItemWidgetState extends State<RelayListItemWidget> {
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
    final isConnected = widget.connectivity.relayTransport?.isOpen() == true;
    final canRemove = !getIt<Hostr>().config.bootstrapRelays.contains(
      widget.connectivity.url,
    );
    return RelayListItemView(
      title: widget.relay?.name ?? displayHost,
      subtitle: isConnected ? 'Connected' : 'Disconnected',
      iconUrl: widget.relay?.icon,
      isConnected: isConnected,
      canRemove: canRemove,
      onRemove: canRemove
          ? () async {
              await getIt<Hostr>().relays.remove(widget.connectivity.url);
            }
          : null,
    );
  }
}
