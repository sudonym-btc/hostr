import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/payment/payment.dart';
import 'package:hostr/router.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PaymentsManager, PaymentCubit?>(
          listener: (c, state) {
            if (state == null) return;
            // Handle PaymentsManager state changes
            showModalBottomSheet(
                context: context,
                builder: (c) {
                  return PaymentWidget(
                    paymentCubit: state,
                  );
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
      ],
      child: BlocBuilder<ModeCubit, ModeCubitState>(builder: (context, state) {
        print(state);
        return AutoTabsScaffold(
            routes: [SearchRoute(), TripsRoute(), InboxRoute(), ProfileRoute()],
            bottomNavigationBuilder: (context, tabsRouter) =>
                BottomNavigationBar(
                  currentIndex: tabsRouter.activeIndex,
                  onTap: tabsRouter.setActiveIndex,
                  items: const [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.search, size: 30), label: 'Search'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.travel_explore), label: 'Trips'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.inbox), label: 'Inbox'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.person), label: 'Profile'),
                  ],
                ));
      }),
    );
  }
}
