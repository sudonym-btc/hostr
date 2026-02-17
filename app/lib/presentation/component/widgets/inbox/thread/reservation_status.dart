import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/logic/thread/thread_header_resolver.dart';
import 'package:hostr/presentation/component/widgets/reservation/reservation_list_item.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:models/main.dart';

class ReservationStatusWidget extends StatelessWidget {
  final List<Reservation> reservations;
  final List<ReservationRequest> reservationRequests;
  final List<Reservation> allListingReservations;
  final List<Message> messages;
  final List<PaymentEvent> paymentEvents;
  final ProfileMetadata listingProfile;
  final Listing listing;
  const ReservationStatusWidget({
    super.key,
    required this.reservations,
    required this.reservationRequests,
    required this.allListingReservations,
    required this.messages,
    required this.paymentEvents,
    required this.listingProfile,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    final ourPubkey = getIt<Hostr>().auth.activeKeyPair?.publicKey;
    final threadCubitState = context.read<ThreadCubit>().state;
    final resolution = ThreadHeaderResolver.resolve(
      threadCubitState: threadCubitState,
      hostPubkey: threadCubitState.listingProfile!.pubKey,
      ourPubkey: ourPubkey!,
    );

    return ReservationListItem(
      resolution: resolution,
      listingProfile: listingProfile,
    );
  }
}
