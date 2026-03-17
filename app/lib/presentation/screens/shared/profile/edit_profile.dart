import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/profile/verification/verification_input.dart';
import 'package:hostr/presentation/component/widgets/ui/form_label.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/presentation/screens/shared/profile/edit_profile.controller.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../listing/image_picker.dart';

@RoutePage()
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EditProfileView();
  }
}

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<StatefulWidget> createState() => EditProfileViewState();
}

class EditProfileViewState extends State<EditProfileView> {
  final EditProfileController controller = EditProfileController();

  List<Widget> buildFormFields() {
    return [
      AspectRatio(
        aspectRatio: 16 / 9,
        child: ImageUpload(
          placeholder: Stack(
            fit: StackFit.expand,
            children: [
              BlurredImage(
                child: Image.asset(
                  'assets/images/profile_placeholder.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              Center(
                child: FilledButton.tonalIcon(
                  onPressed: () =>
                      controller.imageField.cubit.pickMultipleImages(
                        limit: 1,
                        allowedFileTypes:
                            ImagePickerCubit.defaultAllowedFileTypes,
                      ),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(AppLocalizations.of(context)!.addImage),
                ),
              ),
            ],
          ),
          controller: controller.imageField.cubit,
          pubkey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
        ),
      ),
      Gap.vertical.sm(),
      CustomPadding(
        bottom: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormLabel(label: 'Name'),
            TextFormField(
              controller: controller.nameField.textController,
              decoration: const InputDecoration(hintText: 'John Doe'),
            ),
            Gap.vertical.md(),
            FormLabel(label: 'About me'),
            TextFormField(
              controller: controller.aboutMeField.textController,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                hintMaxLines: 1,
                hintText:
                    'I\'m an avid traveler who loves local neighborhoods, great coffee, and easy check-ins.',
              ),
            ),
            Gap.vertical.md(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: FormLabel(label: 'Nostr address')),
                Text(
                  'Optional',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            VerificationInput.nip05(
              controller: controller.nip05Field.textController,
              validator: controller.nip05Field.validate,
              validNotifier: controller.nip05Valid,
              pubkey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
            ),
            Gap.vertical.md(),
            FormLabel(label: 'Lightning address'),
            VerificationInput.lnurl(
              controller: controller.lightningAddressField.textController,
              validator: controller.lightningAddressField.validate,
              validNotifier: controller.lnurlValid,
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: LayoutBuilder(
        builder: (context, constraints) => ProfileProvider(
          pubkey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
          onDone: (metadata) => controller.setState(metadata),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: AppLoadingIndicator.large());
            }
            if (snapshot.connectionState == ConnectionState.done) {
              final fields = buildFormFields();
              return constraints.hasBoundedHeight
                  ? ListView(children: fields)
                  : Column(mainAxisSize: MainAxisSize.min, children: fields);
            }
            return Text(AppLocalizations.of(context)!.errorLabel);
          },
        ),
      ),
    );
    final bottomBar = SaveBottomBar(
      controller: controller,
      onSave: () async {
        final saved = await controller.save();
        if (saved && context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );

    return UnsavedChangesGuard(
      isDirty: () => controller.isDirty,
      child: Form(
        key: controller.formKey,
        child: AppPageGutter(
          maxWidth: kAppWideContentMaxWidth,
          padding: EdgeInsets.zero,
          child: AppPaneLayout(
            panes: [
              AppPane(
                width: kAppFormMaxWidth,
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.profile),
                  titleSpacing: 0,
                ),
                bottomBar: bottomBar,
                promoteChromeWhenStacked: true,
                child: body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
