import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/logic/thread/thread_header_resolver.dart';
import 'package:hostr/presentation/component/widgets/reservation/reservation_list_item.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class ReservationStatusWidget extends StatelessWidget {
  const ReservationStatusWidget({super.key});

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
      listingProfile: threadCubitState.listingProfile!,
    );
  }
}
