import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/app.controller.dart';
import 'package:hostr/logic/main.dart';

class GlobalProviderWidget extends StatefulWidget {
  final Widget child;

  const GlobalProviderWidget({required this.child});

  @override
  _GlobalProviderWidgetState createState() => _GlobalProviderWidgetState();
}

class _GlobalProviderWidgetState extends State<GlobalProviderWidget> {
  late AppController appController;

  @override
  void initState() {
    super.initState();
    appController = AppController();
  }

  @override
  void dispose() {
    appController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (context) => appController.authCubit),
        BlocProvider<GlobalGiftWrapCubit>(
            create: (context) => appController.giftWrapListCubit),
        BlocProvider<ThreadOrganizerCubit>(
            create: (context) => appController.threadOrganizerCubit),
        BlocProvider<ModeCubit>(create: (context) => ModeCubit()..get()),
        BlocProvider<NwcCubit>(create: (_) => NwcCubit()),
        BlocProvider<PaymentsManager>(
            create: (context) => appController.paymentsManager),
        BlocProvider<SwapManager>(
            create: (context) => appController.swapManager),
      ],
      child: widget.child,
    );
  }
}
