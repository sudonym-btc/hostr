import 'package:flutter/material.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:ndk/domain_layer/usecases/nwc/nostr_wallet_connect_uri.dart';

class NostrWalletConnectConnectionWidget extends StatelessWidget {
  final CustomLogger logger = CustomLogger();
  final bool canClose;

  NostrWalletConnectConnectionWidget({super.key, this.canClose = false});

  @override
  build(BuildContext context) {
    return StreamBuilder(
        stream: getIt<NwcService>().connectionsStream,
        builder: (context, connections) {
          if (connections.data == null) {
            return ListTile(
              leading: CircularProgressIndicator(),
            );
          }
          return Column(
              children: connections.data!.map((connection) {
            Widget closeButton = IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                getIt<NwcService>().remove(connection);
                connection.close();
              },
            );
            if (connection.state is Success) {
              Success s = connection.state as Success;
              return ListTile(
                contentPadding: EdgeInsets.all(0),
                leading: CircleAvatar(
                  backgroundColor: s.content.color != null
                      ? Color(int.parse(s.content.color.substring(1, 7),
                              radix: 16) +
                          0xFF000000)
                      : Colors.orange,
                ),
                trailing: canClose ? closeButton : null,
                title: Text(s.content.alias ?? 'NWC Wallet'),
                subtitle: Text(
                  'Connected',
                  maxLines: 1,
                  style: TextStyle(overflow: TextOverflow.ellipsis),
                ),
              );
            }
            if (connection.state is Error) {
              Error state = connection.state as Error;
              return ListTile(
                  leading: Icon(Icons.error),
                  trailing: closeButton,
                  contentPadding: EdgeInsets.all(0),
                  title: Text(
                    NostrWalletConnectUri.parseConnectionUri(connection.url!)
                        .relay,
                    style: TextStyle(overflow: TextOverflow.ellipsis),
                  ),
                  subtitle: Text(state.e.toString(),
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: Theme.of(context).colorScheme.error,
                      )));
            }
            return ListTile(
              leading: CircularProgressIndicator(),
            );
          }).toList());
        });

    // nwcInfo = FutureBuilder(future: getIt<NwcCubit>()., builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {  return NwcProvider(pubkey: );});
  }
}
