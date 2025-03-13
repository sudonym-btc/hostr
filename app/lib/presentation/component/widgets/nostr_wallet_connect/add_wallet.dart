import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';

import 'qr_scanner.dart';

class AddWalletWidget extends StatefulWidget {
  createState() => AddWalletWidgetState();
}

class AddWalletWidgetState extends State<AddWalletWidget> {
  bool shouldShowQrScanner = false;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: CustomPadding(
            child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Wallet Connection',
          style: Theme.of(context).textTheme.titleLarge!,
        ),
        NostrWalletAuthWidget(),
        CustomPadding(),
        BlocProvider<NwcCubit>(
            create: (context) => NwcCubit(),
            child:
                BlocBuilder<NwcCubit, NwcCubitState>(builder: (context, state) {
              if (state is Loading) {
                return CircularProgressIndicator();
              } else if (state is Success) {
                return Text('Connected to ${state.content.alias}');
              } else if (state is Error) {
                return Text('Could not connect to NWC provider: ${state.e}');
              }
              return Column(children: [
                if (shouldShowQrScanner) NwcQrScannerWidget(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            shouldShowQrScanner = !shouldShowQrScanner;
                          });
                        },
                        child: Text(!shouldShowQrScanner ? 'Scan' : 'Stop'),
                      ),
                    ),
                    SizedBox(width: 10), // Add some spacing between buttons
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final clipboardData =
                              await Clipboard.getData('text/plain');
                          if (clipboardData != null) {
                            NwcCubit x = BlocProvider.of<NwcCubit>(context);
                            await x.connect(clipboardData.text!);
                            await getIt<NwcService>().add(x);
                          }
                        },
                        child: Text('Paste'),
                      ),
                    ),
                    SizedBox(width: 10), // Add some spacing between buttons
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          // todo: open in wallet app
                        },
                        child: Text('Wallet'),
                      ),
                    ),
                  ],
                ),
              ]);
            })),
      ],
    )));
  }
}
