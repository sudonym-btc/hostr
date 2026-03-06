import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr/presentation/component/widgets/zap/zap_list.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/stubs/keypairs.dart';

class ZapUsWidget extends StatelessWidget {
  const ZapUsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Section(
      body: CustomPadding(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: HelpText(
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      'Hostr is open source software maintained by the community with ❤️',
                    ),
                  ),
                ),
                Gap.horizontal.md(),

                FilledButton(
                  child: Text(AppLocalizations.of(context)!.zapUs),
                  onPressed: () {
                    final params = ZapPayParameters(
                      to: 'tips@lnbits1.hostr.development',
                      amount: BitcoinAmount.fromInt(BitcoinUnit.sat, 10000),
                    );
                    showAppModal(
                      context,
                      child: PaymentFlowWidget(
                        cubit: getIt<Hostr>().payments.pay(params)..resolve(),
                      ),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                ZapListWidget(
                  pubkey: MockKeys.hoster.publicKey,
                  builder: (p0) => Text(p0.pubKey!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
