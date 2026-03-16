import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/keys/backup_key.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import 'profile_panes.dart';

@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  List<Widget> _buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.key),
        tooltip: 'Back up keys',
        onPressed: () {
          final auth = getIt<Hostr>().auth;
          final keyPair = auth.activeKeyPair!;
          showAppModal(
            context,
            child: BackupKeyWidget(
              publicKeyHex: keyPair.publicKey,
              privateKeyHex: keyPair.privateKey!,
              mnemonic: auth.activeMnemonic,
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          AutoRouter.of(context).navigate(EditProfileRoute());
        },
      ),
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: AppLocalizations.of(context)!.logout,
        color: Theme.of(context).colorScheme.error,
        onPressed: () {
          final router = AutoRouter.of(context);
          final authCubit = BlocProvider.of<AuthCubit>(context);
          showAppModal(
            context,
            child: ModalBottomSheet(
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
                      await authCubit.logout();
                      await router.replaceAll([
                        SignInRoute(),
                      ], onFailure: (failure) => throw failure);
                    },
                    child: Text(AppLocalizations.of(context)!.ok),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }

  VoidCallback _buildEditProfileHandler(BuildContext context) {
    return () {
      AutoRouter.of(context).navigate(EditProfileRoute());
    };
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayoutSpec.of(context);
    final onEditProfile = _buildEditProfileHandler(context);
    final content = CustomScrollView(
      slivers: [
        if (!layout.showsSidebarNavigation)
          SliverAppBar(pinned: true, actions: _buildActions(context)),
        SliverToBoxAdapter(
          child: ProfileSummarySection(onEditProfile: onEditProfile),
        ),
        const SliverToBoxAdapter(child: ProfileDetailsSection()),
      ],
    );

    return Scaffold(
      body: layout.showsSidebarNavigation
          ? AppSplitPage(
              maxWidth: kAppWideContentMaxWidth,
              primaryWidth: kAppProfileMaxWidth,
              primary: AppPanelScaffold(
                appBar: AppBar(actions: _buildActions(context)),
                body: SingleChildScrollView(
                  child: ProfileSummarySection(onEditProfile: onEditProfile),
                ),
              ),
              secondary: const AppPanel(
                child: SingleChildScrollView(child: ProfileDetailsSection()),
              ),
            )
          : AppConstrainedBody(padding: EdgeInsets.zero, child: content),
    );
  }
}
