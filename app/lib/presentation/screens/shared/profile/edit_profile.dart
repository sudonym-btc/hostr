import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/ui/form_label.dart';
import 'package:hostr/presentation/screens/shared/listing/edit_listing_inputs.dart';
import 'package:hostr/presentation/screens/shared/profile/edit_profile.controller.dart';
import 'package:hostr/presentation/screens/shared/profile/edit_profile_inputs.dart';
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
  bool loading = false;
  late final Listenable _submitListenable;

  @override
  void initState() {
    super.initState();
    _submitListenable = Listenable.merge([
      controller,
      // @todo: profile image upload must only allow one file selected
      controller.imageController.notifier,
      controller.nameController,
      controller.aboutMeController,
      controller.nip05Controller,
      controller.lightningAddressController,
      controller.nip05Valid,
      controller.lnurlValid,
    ]);
  }

  Future<void> _onPopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    if (!controller.isDirty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text(
          'You have unsaved changes. Discard them and leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if ((shouldLeave ?? false) && mounted) {
      Navigator.of(context).pop();
    }
  }

  List<Widget> buildFormFields() {
    return [
      AspectRatio(
        aspectRatio: 16 / 9,
        child: ImageUpload(
          placeholder: Stack(
            fit: StackFit.expand,
            children: [
              BlurredImage(
                child: Image.network(
                  'https://randomuser.me/api/portraits/men/1.jpg',
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
                      controller.imageController.pickMultipleImages(limit: 1),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(AppLocalizations.of(context)!.addImage),
                ),
              ),
            ],
          ),
          controller: controller.imageController,
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
              controller: controller.nameController,
              decoration: const InputDecoration(hintText: 'John Doe'),
            ),
            Gap.vertical.md(),
            FormLabel(label: 'About me'),
            TextFormField(
              controller: controller.aboutMeController,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                hintMaxLines: 1,
                hintText:
                    'I\'m an avid traveler who loves local neighborhoods, great coffee, and easy check-ins.',
              ),
            ),
            Gap.vertical.md(),
            FormLabel(label: 'Nostr address'),
            Nip05Input(
              controller: controller.nip05Controller,
              validator: controller.validateNip05,
              validNotifier: controller.nip05Valid,
              pubkey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
            ),
            Gap.vertical.md(),
            FormLabel(label: 'Lightning address'),
            LnurlInput(
              controller: controller.lightningAddressController,
              validator: controller.validateLightningAddress,
              validNotifier: controller.lnurlValid,
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Form(
        key: controller.formKey,
        child: Scaffold(
          appBar: AppBar(title: Text(AppLocalizations.of(context)!.profile)),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: ProfileProvider(
              pubkey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
              onDone: (metadata) => controller.setState(metadata),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoadingIndicator.large());
                }
                if (snapshot.connectionState == ConnectionState.done) {
                  return ListView(children: buildFormFields());
                }
                return Text(AppLocalizations.of(context)!.errorLabel);
              },
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            shape: CircularNotchedRectangle(),
            child: CustomPadding(
              top: 0,
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ListenableBuilder(
                    listenable: _submitListenable,
                    builder: (context, _) {
                      return FilledButton(
                        onPressed:
                            controller.canSubmit &&
                                controller.isDirty &&
                                !loading
                            ? () async {
                                setState(() => loading = true);
                                final saved = await controller.save();
                                if (saved && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                                if (mounted) setState(() => loading = false);
                              }
                            : null,
                        child: loading
                            ? const AppLoadingIndicator.small()
                            : Text(AppLocalizations.of(context)!.save),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
