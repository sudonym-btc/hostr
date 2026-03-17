import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class GlobalProviderWidget extends StatefulWidget {
  final Widget child;

  const GlobalProviderWidget({super.key, required this.child});

  @override
  GlobalProviderWidgetState createState() => GlobalProviderWidgetState();
}

class GlobalProviderWidgetState extends State<GlobalProviderWidget> {
  @override
  void dispose() {
    getIt<Hostr>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(
          value: AuthCubit(initialState: getIt<Hostr>().auth.authState.value),
        ),
        BlocProvider<ModeCubit>(
          create: (context) =>
              ModeCubit(configStore: getIt<Hostr>().userConfig)..load(),
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
