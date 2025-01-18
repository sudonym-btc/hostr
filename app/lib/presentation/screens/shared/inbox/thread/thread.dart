import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'thread_view.dart';

@RoutePage()
class ThreadScreen extends StatelessWidget {
  final String id;
  // ignore: use_key_in_widget_constructors
  const ThreadScreen({@pathParam required this.id});

  @override
  Widget build(BuildContext context) {
    return ThreadView(a: id);
  }
}
