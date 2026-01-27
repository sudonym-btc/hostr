import 'dart:math';

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
        BlocListener<PaymentsManager, PaymentsState>(
          listener: (c, state) {
            if (state.payments.isEmpty) return;
            final latest = state.payments.reduce(
              (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
            );
            final cubit = context.read<PaymentsManager>().cubitFor(latest.id);
            if (cubit == null) return;
            showModalBottomSheet(
              context: context,
              builder: (c) {
                return SafeArea(child: PaymentWidget(paymentCubit: cubit));
              },
            );
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
      child: BlocBuilder<ModeCubit, ModeCubitState>(
        builder: (context, state) {
          if (state is HostMode) {
            const hostTabs = [
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'My Listings',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Inbox'),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ];
            return AutoTabsScaffold(
              key: const ValueKey('hostTabs'),
              routes: [MyListingsRoute(), InboxRoute(), ProfileRoute()],
              bottomNavigationBuilder: (context, tabsRouter) =>
                  BottomNavigationBar(
                    currentIndex: min(
                      hostTabs.length - 1,
                      tabsRouter.activeIndex,
                    ),
                    onTap: tabsRouter.setActiveIndex,
                    items: hostTabs,
                  ),
            );
          }
          const otherTabs = [
            BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 30),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.travel_explore),
              label: 'Trips',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Inbox'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ];
          return AutoTabsScaffold(
            key: const ValueKey('guestTabs'),
            routes: [SearchRoute(), TripsRoute(), InboxRoute(), ProfileRoute()],
            bottomNavigationBuilder: (context, tabsRouter) =>
                BottomNavigationBar(
                  currentIndex: min(
                    otherTabs.length - 1,
                    tabsRouter.activeIndex,
                  ),
                  onTap: tabsRouter.setActiveIndex,
                  items: otherTabs,
                ),
          );
        },
      ),
    );
  }
}
