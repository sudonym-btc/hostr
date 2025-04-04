import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/app.controller.dart';
import 'package:hostr/logic/main.dart';

class GlobalProviderWidget extends StatefulWidget {
  final Widget child;

  const GlobalProviderWidget({super.key, required this.child});

  @override
  GlobalProviderWidgetState createState() => GlobalProviderWidgetState();
}

class GlobalProviderWidgetState extends State<GlobalProviderWidget> {
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
        BlocProvider<AuthCubit>(
            lazy: false, create: (context) => appController.authCubit..get()),
        BlocProvider<GlobalGiftWrapCubit>(
            lazy: false, create: (context) => appController.giftWrapListCubit),
        BlocProvider<ThreadOrganizerCubit>(
            lazy: false,
            create: (context) => appController.threadOrganizerCubit),
        BlocProvider<ModeCubit>(
            lazy: false, create: (context) => ModeCubit()..get()),
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
