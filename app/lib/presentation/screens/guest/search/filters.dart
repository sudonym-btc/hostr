import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/presentation/forms/main.dart';

@RoutePage()
class FiltersScreen extends StatelessWidget {
  const FiltersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: SearchForm(
      onSubmit: (state) {
        Navigator.pop(context);
      },
    )));
  }
}
