import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class ConversationScreen extends StatelessWidget {
  final String id;
  // ignore: use_key_in_widget_constructors
  const ConversationScreen({@pathParam required this.id});

  @override
  Widget build(BuildContext context) {
    return Text('I\'m a conversation screen $id');
  }
}
