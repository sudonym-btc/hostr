import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/screens/shared/listing/image_picker.dart';
import 'package:hostr/presentation/screens/shared/profile/edit_profile.controller.dart';

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
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final EditProfileController controller = EditProfileController();
  bool loading = false;

  List<Widget> buildFormFields() {
    return [
      Expanded(
        child: CustomPadding(
          child: ImageUpload(
            controller: controller.imageController,
            pubkey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
          ),
        ),
      ),
      TextFormField(
        controller: controller.nameController,
        decoration: const InputDecoration(labelText: 'Name', hintText: 'Name'),
      ),
      TextFormField(
        controller: controller.aboutMeController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'About me',
          hintText: 'About me',
        ),
      ),
      TextFormField(
        controller: controller.nip05Controller,
        decoration: const InputDecoration(
          labelText: 'NIP 05',
          hintText: 'NIP 05',
        ),
      ),
      TextFormField(
        controller: controller.lightningAddressController,
        decoration: const InputDecoration(
          labelText: 'Lightning address',
          hintText: 'Lightning address',
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.editProfile)),
        body: ProfileProvider(
          pubkey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
          onDone: (metadata) => controller.setState(metadata),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (snapshot.connectionState == ConnectionState.done) {
              return CustomPadding(child: Column(children: buildFormFields()));
            }
            return const Text('Error');
          },
        ),
        bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          child: CustomPadding(
            top: 0,
            bottom: 0,
            child: FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      await controller.save();
                      context.router.back();
                      setState(() => loading = false);
                    },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ),
        ),
      ),
    );
  }
}
