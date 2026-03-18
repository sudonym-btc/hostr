import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/keys/backup_key.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';
import 'package:hostr/presentation/screens/shared/profile/logout_modal.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import 'edit_profile.dart';
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
          AutoRouter.of(context).push(EditProfileRoute());
        },
      ),
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: AppLocalizations.of(context)!.logout,
        color: Theme.of(context).colorScheme.error,
        onPressed: () {
          showAppModal(context, child: logoutModal(context));
        },
      ),
    ];
  }

  SliverAppBar _buildAppBar(BuildContext context, ProfileMetadata? profile) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      stretch: true,
      expandedHeight: 240,
      title: Text(profile?.metadata.getName() ?? ''),
      actions: _buildActions(context),
      flexibleSpace: FlexibleSpaceBar(
        background:
            (profile?.metadata.picture != null &&
                profile!.metadata.picture!.isNotEmpty)
            ? BlossomImage(
                image: profile.metadata.picture!,
                pubkey: profile.metadata.pubKey,
                fit: BoxFit.cover,
              )
            : noImageSetPlaceholder(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageGutter(
      maxWidth: kAppWideContentMaxWidth,
      child: ProfileProvider(
        pubkey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
        builder: (context, snapshot) {
          final profile = snapshot.data;

          return AppPaneLayout(
            panes: [
              AppPane(
                flex: 2,
                panelTone: AppPanelTone.primary,
                sliverAppBarBuilder: (context) =>
                    _buildAppBar(context, profile),
                child: ProfileSummarySection(profile: profile),
              ),
              const AppPane(flex: 3, child: ProfileSettingsSection()),
            ],
          );
        },
      ),
    );
  }
}
