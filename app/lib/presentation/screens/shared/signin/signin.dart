import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';

@RoutePage()
class SignInScreen extends StatelessWidget {
  final Function onSuccess;
  const SignInScreen({required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Sign In'),
        ),
        body: BlocProvider(
          create: (context) => AuthCubit()..get(),
          child: BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
            return Center(
                child: FilledButton(
                    onPressed: () async {
                      await context.read<AuthCubit>().signup();
                      onSuccess();
                    },
                    child: Text(
                      'Sign in',
                    )));
          }),
        ));
  }
}
