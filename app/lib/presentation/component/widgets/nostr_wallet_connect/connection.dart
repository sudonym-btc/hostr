import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/nwc/nwc.cubit.dart';
import 'package:ndk/domain_layer/usecases/nwc/nostr_wallet_connect_uri.dart';

class NostrWalletConnectConnectionWidget extends StatelessWidget {
  final bool canClose;

  const NostrWalletConnectConnectionWidget({super.key, this.canClose = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: getIt<Hostr>().nwc.connectionsStream,
      builder: (context, connectionsSnapshot) {
        if (!connectionsSnapshot.hasData) {
          return ListTile(leading: CircularProgressIndicator());
        }
        return Column(
          children: connectionsSnapshot.data!.map((reactiveConnection) {
            Widget closeButton = IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                getIt<Hostr>().nwc.remove(reactiveConnection);
              },
            );

            // Use BlocBuilder to listen to each connection's state changes
            return BlocBuilder<NwcCubit, NwcCubitState>(
              bloc: reactiveConnection,
              builder: (context, state) {
                if (state is Idle || state is Loading) {
                  return ListTile(
                    leading: CircularProgressIndicator(),
                    trailing: canClose ? closeButton : null,
                    contentPadding: EdgeInsets.all(0),
                  );
                }

                if (state is Success) {
                  return ListTile(
                    contentPadding: EdgeInsets.all(0),
                    leading: CircleAvatar(
                      backgroundColor: state.content.color != null
                          ? Color(
                              int.parse(
                                    state.content.color!.substring(1, 7),
                                    radix: 16,
                                  ) +
                                  0xFF000000,
                            )
                          : Colors.orange,
                    ),
                    trailing: canClose ? closeButton : null,
                    title: Text(state.content.alias),
                    subtitle: Text(
                      AppLocalizations.of(context)!.connected,
                      maxLines: 1,
                      style: TextStyle(overflow: TextOverflow.ellipsis),
                    ),
                  );
                }

                if (state is Error) {
                  return ListTile(
                    leading: Icon(Icons.error),
                    trailing: canClose ? closeButton : null,
                    contentPadding: EdgeInsets.all(0),
                    title: Text(
                      NostrWalletConnectUri.parseConnectionUri(
                        reactiveConnection.url!,
                      ).relays.first,
                      style: TextStyle(overflow: TextOverflow.ellipsis),
                    ),
                    subtitle: Text(
                      'Error',
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                }

                return ListTile(leading: CircularProgressIndicator());
              },
            );
          }).toList(),
        );
      },
    );
  }
}
