import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';

class NostrWalletConnectConnectionWidget extends StatelessWidget {
  final CustomLogger logger = CustomLogger();

  NostrWalletConnectConnectionWidget({super.key});

  @override
  build(BuildContext context) {
    return BlocProvider<NwcCubit>(create: (context) {
      return NwcCubit()..checkInfo();
    }, child: BlocBuilder<NwcCubit, NwcCubitState>(builder: (context, state) {
      if (state is Success) {
        return CustomPadding(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: state.content.color != null
                  ? Color(int.parse(state.content.color!.substring(1, 7),
                          radix: 16) +
                      0xFF000000)
                  : Colors.orange,
            ),
            title: Text(state.content.alias ?? 'NWC Wallet'),
            subtitle: Text(state.content.pubkey ?? 'No pubkey'),
          ),
          // Text(state.content.methods.join(', ')),
          // Text(state.content.notifications.join(', ')),
        );
      }
      if (state is Error) {
        return Text('Could not connect to NWC provider: ${state.e}');
      }
      return CircularProgressIndicator();
    }));
    // nwcInfo = FutureBuilder(future: getIt<NwcCubit>()., builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {  return NwcProvider(pubkey: );});
  }
}
