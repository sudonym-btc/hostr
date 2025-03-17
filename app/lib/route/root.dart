import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr/presentation/screens/shared/loading_page.dart';

@RoutePage()
class RootScreen extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const RootScreen();

  @override
  Widget build(BuildContext context) {
    return GlobalProviderWidget(child: LoadingPage(child: AutoRouter()));
  }
}
