import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr/presentation/component/widgets/zap/zap_list.dart';
import 'package:hostr/presentation/component/widgets/zap/zap_receipt.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class ZapUsWidget extends StatelessWidget {
  const ZapUsWidget({super.key});

  static const _tipsAddress = 'tips@lnbits1.hostr.development';

  @override
  Widget build(BuildContext context) {
    return CustomPadding(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: HelpText(
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  'Hostr is open source software maintained by the community with ❤️',
                ),
              ),
              Gap.horizontal.md(),

              FilledButton(
                child: Text(AppLocalizations.of(context)!.zapUs),
                onPressed: () {
                  final params = ZapPayParameters(
                    to: _tipsAddress,
                    amount: BitcoinAmount.fromInt(BitcoinUnit.sat, 10000),
                  );
                  showAppModal(
                    context,
                    builder: (_) => PaymentFlowWidget(
                      cubit: getIt<Hostr>().payments.pay(params)..resolve(),
                    ),
                  );
                },
              ),
            ],
          ),
          Gap.vertical.md(),
          Row(
            children: [
              ZapListWidget(
                lud16: _tipsAddress,
                builder: (p0) => ZapReceiptWidget(zap: p0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
