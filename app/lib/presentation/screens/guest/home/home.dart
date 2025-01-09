import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/widgets/main.dart';
import 'package:hostr/router.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => AuthCubit()..checkKeyLoggedIn(),
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            return MultiBlocProvider(
                providers: [
                  BlocProvider<PaymentsManager>(
                    create: (context) => PaymentsManager(),
                  ),
                  BlocProvider<SwapManager>(
                    create: (context) => SwapManager(
                        paymentsManager: context.read<PaymentsManager>()),
                  ),
                  BlocProvider<EscrowDepositManager>(
                    create: (context) => EscrowDepositManager(
                        swapManager: context.read<SwapManager>(),
                        paymentsManager: context.read<PaymentsManager>()),
                  ),
                ],
                child: MultiBlocListener(
                    listeners: [
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
                    ],
                    child: AutoTabsScaffold(
                      routes: [SearchRoute(), InboxRoute(), ProfileRoute()],
                      bottomNavigationBuilder: (context, tabsRouter) =>
                          SalomonBottomBar(
                              currentIndex: tabsRouter.activeIndex,
                              onTap: tabsRouter.setActiveIndex,
                              margin: EdgeInsets.symmetric(
                                  vertical: 40, horizontal: 20),
                              items: [
                            SalomonBottomBarItem(
                                icon: Icon(Icons.search, size: 30),
                                title: const Text('Search')),
                            SalomonBottomBarItem(
                                icon: Icon(Icons.inbox, size: 30),
                                title: const Text('Inbox')),
                            SalomonBottomBarItem(
                                icon: Icon(Icons.person, size: 30),
                                title: const Text('Settings'))
                          ]),
                    )));
          },
        ));
  }
}
