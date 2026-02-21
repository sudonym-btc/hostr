import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/app.controller.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

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
        BlocProvider<AuthCubit>.value(value: AuthCubit()),
        BlocProvider<ModeCubit>(
          create: (context) => ModeCubit(modeStorage: getIt())..get(),
        ),
        BlocProvider<RelayConnectivityCubit>(
          create: (context) => RelayConnectivityCubit(hostr: getIt<Hostr>()),
        ),
        BlocProvider<NwcConnectivityCubit>(
          create: (context) => NwcConnectivityCubit(hostr: getIt<Hostr>()),
        ),
      ],
      child: widget.child,
    );
  }
}
