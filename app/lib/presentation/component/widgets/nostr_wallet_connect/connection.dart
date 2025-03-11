import 'package:flutter/material.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';

class NostrWalletConnectConnectionWidget extends StatelessWidget {
  final CustomLogger logger = CustomLogger();

  NostrWalletConnectConnectionWidget({super.key});

  @override
  build(BuildContext context) {
    return Column(
        children: getIt<NwcService>().connections.map((connection) {
      if (connection.state is Success) {
        Success s = connection.state as Success;
        return CustomPadding(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: s.content.color != null
                  ? Color(
                      int.parse(s.content.color!.substring(1, 7), radix: 16) +
                          0xFF000000)
                  : Colors.orange,
            ),
            title: Text(s.content.alias ?? 'NWC Wallet'),
            subtitle: Text(s.content.pubkey ?? 'No pubkey'),
          ),
          // Text(state.content.methods.join(', ')),
          // Text(state.content.notifications.join(', ')),
        );
      }
      if (connection.state is Error) {
        Error error = connection.state as Error;
        return Text('Could not connect to NWC provider: ${error}');
      }
      return CircularProgressIndicator();
    }).toList());
    // nwcInfo = FutureBuilder(future: getIt<NwcCubit>()., builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {  return NwcProvider(pubkey: );});
  }
}
