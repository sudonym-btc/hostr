import 'package:dart_nostr/dart_nostr.dart';
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

  @override
  initState() {
    super.initState();
    nostrWalletAuth = NostrWalletAuth().generateUri(
        keyPair: NostrKeyPairs.generate(), // @todo import keyService
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
              return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Expanded(child: TextField()),
                    FilledButton(
                        onPressed: () {
                          setState(() {
                            shouldShowQrScanner = !shouldShowQrScanner;
                          });
                        },
                        child: Text(!shouldShowQrScanner ? 'Scan' : 'Stop')),
                    FilledButton(
                        onPressed: () {
                          context.read<NwcCubit>().connect(
                              'nostr+walletconnect://5e269731784388c8894c8e41f781c32baf071009c247b659ca140f9456cb52e1?relay=wss://relay.getalby.com/v1&secret=1a864fb0aabdde78fbceaf2803167e13e36faaa3a218c6d800791447701d3fe2&lud16=frostysun783@getalby.com');
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
