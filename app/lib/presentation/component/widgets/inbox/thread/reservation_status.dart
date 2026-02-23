import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/constants.dart';
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
        final child = snapshot.hasData
            ? TradeHeader(
                key: const ValueKey('trade-header'),
                actions: snapshot.data!.availableActions,
                listingProfile: threadCubitState.listingProfile!,
              )
            : const SizedBox.shrink(key: ValueKey('empty'));

        return AnimatedSwitcher(
          duration: kAnimationDuration,
          switchInCurve: kAnimationCurve,
          switchOutCurve: kAnimationCurve,
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: child,
        );
      },
    );
  }
}
