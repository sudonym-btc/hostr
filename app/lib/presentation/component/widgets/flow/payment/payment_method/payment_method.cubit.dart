import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/nostr/profile_metadata.dart';

class PaymentMethodCubit extends Cubit<PaymentMethodState> {
  ProfileMetadata profileMetadata;
  PaymentMethodCubit({required this.profileMetadata})
    : super(PaymentMethodState());

  void load() async {
    emit(PaymentMethodLoading());

    // // // Find this profiles metadata and LUD16 link
    // // final p = await getIt<Hostr>().metadata.loadMetadata(
    // //   profileMetadata.pubKey,
    // // );
    ///// First check if user supports zap receipts
    ///// If zap receipting as payment proof, the zap-request must include the signed metadata event with the lud address of the user
    ///// This is because the zap receipt can hypo be published by anyone
    ///// So we must in the signed event include commitment of host to the tipped address
    ///// include an a tag to commit to this reservation request
    ///// P (sender) should be blank to keep anonymous
    ///// relay should be specified as hoster relay
    /////
    /////
    ///// If the hoster changes their lud16 address, it would break the implementation so these should not be considered final or proof
    ///// Only used to visually show hoster and guest that a payment was made
    /////
    ///// Clients SHOULD consider Reservations published by non-author as valid if LUD nostr event was signed by currently correct address
    ///// But guest MUST not consider this reservation final until signed by hoster

    // Check wether allowNostr is true so that ZapReceipt will be created

    emit(PaymentMethodCannotZap());
  }
}

class PaymentMethodState {}

class PaymentMethodLoading extends PaymentMethodState {}

class PaymentMethodError extends PaymentMethodState {}

class PaymentMethodCanZap extends PaymentMethodState {}

class PaymentMethodCannotZap extends PaymentMethodState {}
