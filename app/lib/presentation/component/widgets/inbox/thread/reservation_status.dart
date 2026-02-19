import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';

class ReservationStatusWidget extends StatelessWidget {
  const ReservationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final threadCubitState = context.read<ThreadCubit>().state;
    return StreamBuilder(
      stream: context.read<ThreadCubit>().thread.trade!.state,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        return TradeHeader(
          actions: snapshot.data!.availableActions,
          listingProfile: threadCubitState.listingProfile!,
        );
      },
    );
  }
}
