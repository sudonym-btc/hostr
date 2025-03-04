import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/router.dart';

@RoutePage()
class SignInScreen extends StatefulWidget {
  final Function? onSuccess;
  // ignore: use_key_in_widget_constructors
  const SignInScreen({this.onSuccess});

  @override
  State<StatefulWidget> createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  String _private = '';
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
                child: Column(children: [
              TextFormField(
                key: ValueKey('key'),
                onChanged: (value) {
                  setState(() {
                    _private = value;
                  });
                },
              ),
              Row(
                children: [
                  FilledButton(
                      key: ValueKey('login'),
                      onPressed: () async {
                        var router = AutoRouter.of(context);
                        await context.read<AuthCubit>().signin(_private);
                        router.replaceAll([HomeRoute()]);
                        if (widget.onSuccess != null) {
                          widget.onSuccess!();
                        }
                      },
                      child: Text(
                        'Sign in',
                      )),
                  FilledButton(
                      onPressed: () async {
                        await context.read<AuthCubit>().signup();
                        if (widget.onSuccess != null) {
                          widget.onSuccess!();
                        }
                        ;
                      },
                      child: Text(
                        'Sign up',
                      ))
                ],
              )
            ]));
          }),
        ));
  }
}
