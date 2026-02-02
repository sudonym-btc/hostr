import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
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
        BlocProvider<AuthCubit>.value(value: appController.authCubit..get()),
        BlocProvider<Threads>.value(value: appController.threads),
        BlocProvider<EventPublisherCubit>.value(
          value: appController.eventPublisherCubit,
        ),
        BlocProvider<ModeCubit>(
          create: (context) => ModeCubit(modeStorage: getIt())..get(),
        ),
      ],
      child: widget.child,
    );
  }
}
