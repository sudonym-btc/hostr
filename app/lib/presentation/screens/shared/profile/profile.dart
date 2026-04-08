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
            builder: (_) => BackupKeyWidget(
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
          showAppModal(
            context,
            builder: (modalContext) =>
                logoutModal(context, modalContext: modalContext),
          );
        },
      ),
    ];
  }

  SliverAppBar _buildAppBar(BuildContext context, ProfileMetadata? profile) {
    bool hasPicture =
        profile?.metadata.picture != null &&
        profile!.metadata.picture!.isNotEmpty;
    final surfaceColor = AppSurface.of(context);
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      stretch: true,
      expandedHeight: hasPicture ? 240 : null,
      title: Text(profile?.metadata.getName() ?? ''),
      actions: _buildActions(context),
      surfaceTintColor: Colors.transparent,
      backgroundColor: surfaceColor.withValues(alpha: 0.90),
      flexibleSpace: hasPicture
          ? FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  BlossomImage(
                    image: profile.metadata.picture!,
                    pubkey: profile.metadata.pubKey,
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          surfaceColor.withValues(alpha: 0.7),
                          surfaceColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null, // : noImageSetPlaceholder(context)
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
