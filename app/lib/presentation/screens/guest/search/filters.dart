import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/presentation/forms/main.dart';

@RoutePage()
class FiltersScreen extends StatelessWidget {
  final bool asBottomSheet;

  const FiltersScreen({super.key, this.asBottomSheet = false});

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: SearchForm(
        onSubmit: (state) {
          Navigator.pop(context);
        },
      ),
    );

    if (asBottomSheet) {
      return content;
    }

    return Scaffold(body: content);
  }
}
