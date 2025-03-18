import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import 'escrow_selector.dart';

class PaymentMethodWidget extends StatelessWidget {
  final Metadata counterparty;
  final ReservationRequest r;
  const PaymentMethodWidget(
      {super.key, required this.counterparty, required this.r});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: CustomPadding(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
              style: Theme.of(context).textTheme.titleLarge!,
              'Would you like to use an escrow to settle this transfer?'),
          CustomPadding(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: FilledButton(
                      onPressed: () async {
                        Navigator.of(context).pop();

                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return EscrowSelectorWidget(
                                  r: r, counterparty: counterparty);
                            });
                      },
                      child: Text(AppLocalizations.of(context)!.useEscrow))),
              CustomPadding(),
              Expanded(
                  child: FilledButton(
                      key: ValueKey('pay_upfront'),
                      onPressed: () {
                        Navigator.of(context).pop();

                        // getIt<Ndk>().zaps.createZapRequest(amountSats: amountSats, signer: signer, pubKey: pubKey, relays: relays)

                        /// First check if user supports zap receipts
                        /// If zap receipting as payment proof, the zap-request must include the signed metadata event with the lud address of the user
                        /// This is because the zap receipt can hypo be published by anyone
                        /// So we must in the signed event include commitment of host to the tipped address
                        /// include an a tag to commit to this reservation request
                        /// P (sender) should be blank to keep anonymous
                        /// relay should be specified as hoster relay
                        ///
                        ///
                        /// If the hoster changes their lud16 address, it would break the implementation so these should not be considered final or proof
                        /// Only used to visually show hoster and guest that a payment was made
                        ///
                        /// Clients SHOULD consider Reservations published by non-author as valid if LUD nostr event was signed by currently correct address
                        /// But guest MUST not consider this reservation final until signed by hoster

                        BlocProvider.of<PaymentsManager>(context).create(
                            LnUrlPaymentParameters(
                                to: counterparty.lud16 ?? counterparty.lud06!,
                                amount: r.parsedContent.amount));
                      },
                      child: Text(AppLocalizations.of(context)!.payUpfront)))
            ],
          )
        ],
      ),
    ));
  }
}
