import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import 'signup.dart';

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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.signIn)),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return Center(
            child: CustomPadding(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    key: ValueKey('key'),
                    onChanged: (value) {
                      setState(() {
                        _private = value;
                      });
                    },
                    maxLines: null, // Allow multiple lines
                    decoration: InputDecoration(hintText: 'nsec...'),
                  ),
                  SizedBox(height: 20), // Spacing above the buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          key: ValueKey('login'),
                          onPressed: () async {
                            var router = AutoRouter.of(context);
                            await context.read<AuthCubit>().signin(_private);
                            final metadata = await getIt<Hostr>().metadata
                                .loadMetadata(
                                  getIt<Hostr>().auth.getActiveKey().publicKey,
                                );

                            if (metadata == null) {
                              router.replaceAll([
                                HomeRoute(children: [ProfileRoute()]),
                              ]);
                              return;
                            }

                            if (widget.onSuccess != null) {
                              widget.onSuccess!();
                              return;
                            }

                            router.replaceAll([HomeRoute()]);
                          },
                          child: Text(AppLocalizations.of(context)!.signIn),
                        ),
                      ),
                      SizedBox(width: 10), // Spacing between the buttons
                      Expanded(
                        child: FilledButton(
                          onPressed: _private.isEmpty
                              ? () async {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return SignUpWidget();
                                    },
                                  );
                                  if (widget.onSuccess != null) {
                                    widget.onSuccess!();
                                  }
                                }
                              : null,
                          child: Text(AppLocalizations.of(context)!.signUp),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
