import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/nwc/nwc.cubit.dart';

import 'qr_scanner.dart';

class AddWalletWidget extends StatefulWidget {
  const AddWalletWidget({super.key});

  @override
  createState() => AddWalletWidgetState();
}

class AddWalletWidgetState extends State<AddWalletWidget> {
  Future<void> _onInput(BuildContext context, String url) async {
    final cubit = BlocProvider.of<NwcCubit>(context);
    await cubit.connect(url);
    if (cubit.connection != null) {
      await getIt<Hostr>().nwc.add(cubit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NwcCubit>(
      create: (context) =>
          NwcCubit(nwc: getIt<Hostr>().nwc, logger: getIt<Hostr>().logger),
      child: BlocBuilder<NwcCubit, NwcCubitState>(
        builder: (context, state) {
          if (state is Loading) {
            return ModalBottomSheet(
              title: AppLocalizations.of(context)!.connectWallet,
              subtitle: 'Connecting to wallet...',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Gap.vertical.custom(kSpace5),
                  AsymptoticProgressBar(),
                  Gap.vertical.md(),
                ],
              ),
            );
          } else if (state is NwcSuccess) {
            return ModalBottomSheet(
              type: ModalBottomSheetType.success,
              title: AppLocalizations.of(context)!.connectWallet,
              content: Text(
                '${AppLocalizations.of(context)!.connectedTo} ${state.data.alias}',
              ),
            );
          } else if (state is NwcFailure) {
            return ModalBottomSheet(
              type: ModalBottomSheetType.error,
              title: AppLocalizations.of(context)!.connectWallet,
              content: Text(
                AppLocalizations.of(
                  context,
                )!.couldNotConnectNwcProvider(state.e.toString()),
              ),
            );
          }
          return ModalBottomSheet(
            title: AppLocalizations.of(context)!.connectWallet,
            subtitle: 'Connect to your bitcoin wallet via Nostr Wallet Connect',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NostrWalletAuthWidget(),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: NwcQrScannerWidget(
                    onScanned: (url) => _onInput(context, url),
                  ),
                ),
              ],
            ),
            buttons: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () async {
                    final clipboardData = await Clipboard.getData('text/plain');
                    if (clipboardData?.text != null) {
                      await _onInput(context, clipboardData!.text!);
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.paste),
                ),
                // Expanded(
                //   child: FilledButton(
                //     onPressed: () async {
                //       // todo: open in wallet app
                //     },
                //     child: Text(AppLocalizations.of(context)!.wallet),
                //   ),
                // ),
              ],
            ),
          );
        },
      ),
    );
  }
}
