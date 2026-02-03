import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/data/sources/nostr/nostr/hostr.dart';
import 'package:hostr/injection.dart';
import 'package:models/main.dart';

abstract class ThreadReservationRequestGuestHostComponents {
  Widget actionButton(BuildContext context);
  Widget statusText(BuildContext context);
}

class ThreadReservationRequestGuestViewWidget
    implements ThreadReservationRequestGuestHostComponents {
  final Message item;
  final ProfileMetadata counterparty;
  final ReservationRequest reservationRequest;
  final Listing listing;
  final List<Reservation> reservations;
  final bool isSentByMe;
  final ReservationRequestStatus reservationStatus;

  ThreadReservationRequestGuestViewWidget({
    required this.counterparty,
    required this.item,
    required this.listing,
    required this.reservations,
  }) : reservationRequest = item.child as ReservationRequest,
       isSentByMe = item.child!.pubKey == counterparty.pubKey,
       reservationStatus = ReservationRequest.resolveStatus(
         request: item.child as ReservationRequest,
         listing: listing,
         reservations: reservations,
         threadAnchor: (item.child as ReservationRequest).anchor!,
         paid: false,
         refunded: false,
       );

  pay(BuildContext context) async {
    final escrows = await getIt<Hostr>().escrows.determineMutualEscrow(
      getIt<Hostr>().auth.activeKeyPair!.publicKey,
      counterparty.pubKey,
    );

    final chain = getIt<Hostr>().evm.supportedEvmChains[0];

    final txId = await getIt<Hostr>().payments.escrow.escrow(
      eventId: reservationRequest.id,
      amount: reservationRequest.parsedContent.amount,
      sellerEvmAddress: counterparty.evmAddress!,
      escrowEvmAddress: escrows.compatibleServices[0].parsedContent.evmAddress,
      escrowContractAddress:
          escrows.compatibleServices[0].parsedContent.contractAddress,
      timelock: 200,
      evmChain: chain,
    );

    getIt<Hostr>().reservations.createSelfSigned(
      threadId: item.reservationRequestAnchor!,
      reservationRequest: reservationRequest,
      listing: listing,
      hoster: counterparty,
      zapProof: null,
      escrowProof: EscrowProof(
        method: 'EVM',
        chainId: (await chain.client.getChainId()).toString(),
        txHash: txId,
        hostsTrustedEscrows: escrows.hostTrust,
        hostsEscrowMethods: escrows.hostMethod,
      ),
    );

    // @Todo: ideally would create a transaction listener on all chains we can handle and then automatically trigger self-signed. Don't want to rely on escrow call completing as app might go into background.

    // showModalBottomSheet(
    //   context: context,
    //   builder: (context) {
    //     return PaymentMethodWidget(
    //       reservationRequest: reservationRequest,
    //       counterparty: counterparty,
    //       listing: listing,
    //     );
    //   },
    // );
  }

  Widget actionButton(BuildContext context) {
    final action = ReservationRequest.resolveGuestAction(
      status: reservationStatus,
    );
    switch (action) {
      case ReservationRequestGuestAction.pay:
        return payButton(context);
      default:
        return Container();
    }
  }

  Widget statusText(BuildContext context) {
    switch (reservationStatus) {
      case ReservationRequestStatus.unconfirmed:
        return Text(
          isSentByMe
              ? AppLocalizations.of(context)!.youSentReservationRequest
              : AppLocalizations.of(context)!.receivedReservationRequest,
          style: Theme.of(context).textTheme.bodyMedium!,
        );
      case ReservationRequestStatus.pendingPublish:
        return Text('Waiting for host to confirm your booking');
      case ReservationRequestStatus.confirmed:
        return Text('Confirmed by host');
      case ReservationRequestStatus.refunded:
        return Text('Refunded by host');
      case ReservationRequestStatus.unavailable:
        return Text('This booking is no longer available');
    }
  }

  payButton(BuildContext context) {
    // todo check payment status here too
    return FilledButton(
      key: ValueKey('pay'),
      onPressed: () => pay(context),
      child: Text(AppLocalizations.of(context)!.pay),
    );
  }
}
