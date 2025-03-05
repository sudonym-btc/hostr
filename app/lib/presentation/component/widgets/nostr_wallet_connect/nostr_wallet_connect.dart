import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/nostr_wallet_connect/qr_scanner.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';

import 'nostr_wallet_auth.dart';

class NostrWalletConnectWidget extends StatefulWidget {
  final CustomLogger logger = CustomLogger();

  NostrWalletConnectWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _NostrWalletConnectWidgetState();
  }
}

class _NostrWalletConnectWidgetState extends State<NostrWalletConnectWidget> {
  Config config = getIt<Config>();
  Uri? nostrWalletAuth;
  bool shouldShowQrScanner = false;
  final TextEditingController controller = TextEditingController();

  @override
  initState() {
    super.initState();
    nostrWalletAuth = NostrWalletAuth().generateUri(
        keyPair: Bip340.generatePrivateKey(), // @todo import keyService
        budget: config.defaultBudgetMonthly,
        budgetPeriod: BudgetPeriod.monthly,
        relay: config.hostrRelay,
        secret: 'secret');
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
        child: CustomPadding(
            child: Column(
      children: [
        NostrWalletAuthWidget(),
        Column(
          children: [
            // Text('Connect wallet to app'),
            if (shouldShowQrScanner) NwcQrScannerWidget(),

            BlocBuilder<NwcCubit, NwcCubitState>(builder: (context, state) {
              if (state is Success) {
                return Text('Connected to ${state.content.alias}');
              } else if (state is Error) {
                return Text('Could not connect to NWC provider: ${state.e}');
              }
              return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: TextField(
                      controller: controller,
                    )),
                    FilledButton(
                        onPressed: () {
                          setState(() {
                            shouldShowQrScanner = !shouldShowQrScanner;
                          });
                        },
                        child: Text(!shouldShowQrScanner ? 'Scan' : 'Stop')),
                    FilledButton(
                        onPressed: () {
                          context.read<NwcCubit>().connect(controller.text);
                        },
                        child: Text('Connect'))
                  ]);
            })
          ],
        )
      ],
    )));
  }
}
