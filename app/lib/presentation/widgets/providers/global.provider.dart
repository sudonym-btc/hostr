import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/widgets/main.dart';

class GlobalProviderWidget extends StatelessWidget {
  final Widget child;
  // ignore: use_key_in_widget_constructors
  const GlobalProviderWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
              create: (context) => AuthCubit()..checkKeyLoggedIn()),
          BlocProvider<PaymentsManager>(
            create: (context) => PaymentsManager(),
          ),
          BlocProvider<SwapManager>(
            create: (context) =>
                SwapManager(paymentsManager: context.read<PaymentsManager>()),
          ),
          BlocProvider<EscrowDepositManager>(
            create: (context) => EscrowDepositManager(
                swapManager: context.read<SwapManager>(),
                paymentsManager: context.read<PaymentsManager>()),
          ),
        ],
        child: MultiBlocListener(listeners: [
          BlocListener<PaymentsManager, PaymentCubit?>(
            listener: (context, state) {
              // Handle PaymentsManager state changes
              showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return ZapInput();
                  });
            },
          ),
          // BlocListener<SwapManager, SwapState>(
          //   listener: (context, state) {
          //     // Handle SwapManager state changes
          //   },
          // ),
          // BlocListener<EscrowDepositManager, EscrowDepositState>(
          //   listener: (context, state) {
          //     // Handle EscrowDepositManager state changes
          //   },
          // ),
        ], child: child));
  }
}
