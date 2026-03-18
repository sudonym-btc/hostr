import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

ModalBottomSheet logoutModal(BuildContext context) {
  final router = AutoRouter.of(context);
  return ModalBottomSheet(
    title: AppLocalizations.of(context)!.logout,
    subtitle: AppLocalizations.of(context)!.areYouSure,
    content: const SizedBox.shrink(),
    buttons: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () async {
            Navigator.of(context).pop();
            await getIt<Hostr>().auth.logout();
            await router.replaceAll([
              SearchRoute(),
            ], onFailure: (failure) => throw failure);
          },
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    ),
  );
}
