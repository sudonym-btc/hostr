import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:models/main.dart';

import '../../modal_bottom_sheet.dart';
import '../escrow/fund/escrow_fund.dart';

/// Simplified payment method widget.
/// Escrow selection is now handled directly inside [EscrowFundWidget].
class PaymentMethodWidget extends StatelessWidget {
  final ProfileMetadata counterparty;
  final ReservationRequest reservationRequest;
  const PaymentMethodWidget({
    super.key,
    required this.counterparty,
    required this.reservationRequest,
  });

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      title: AppLocalizations.of(context)!.paymentMethodTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  showAppModal(
                    context,
                    child: PaymentFlowWidget(
                      cubit: getIt<Hostr>().payments.pay(
                        ZapPayParameters(
                          to: counterparty.metadata.lud16!,
                          amount: BitcoinAmount.fromInt(BitcoinUnit.sat, 10000),
                          event: reservationRequest,
                        ),
                      )..resolve(),
                    ),
                  );
                },
                child: Text(AppLocalizations.of(context)!.payDirectly),
              ),
              Gap.horizontal.md(),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  showAppModal(
                    context,
                    child: EscrowFundWidget(
                      counterparty: counterparty,
                      reservationRequest: reservationRequest,
                    ),
                  );
                },
                child: Text(AppLocalizations.of(context)!.useEscrow),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
