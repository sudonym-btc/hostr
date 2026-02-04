import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/image_picker.cubit.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class EditProfileController {
  final ImagePickerCubit imageController = ImagePickerCubit(maxImages: 1);
  final TextEditingController nameController = TextEditingController();
  final TextEditingController aboutMeController = TextEditingController();
  final TextEditingController nip05Controller = TextEditingController();
  final TextEditingController lightningAddressController =
      TextEditingController();

  void setState(ProfileMetadata? profile) {
    imageController.setImages(
      profile?.metadata.picture != null
          ? [CustomImage.path(profile?.metadata.picture)]
          : [],
    );
    nameController.text = profile?.metadata.name ?? '';
    aboutMeController.text = profile?.metadata.about ?? '';
    nip05Controller.text = profile?.metadata.nip05 ?? '';
    lightningAddressController.text = profile?.metadata.lud16 ?? '';
  }

  Future<void> save() async {
    var image = imageController.images.isNotEmpty
        ? imageController.images.first.path
        : null;
    final name = nameController.text;
    final aboutMe = aboutMeController.text;
    final nip05 = nip05Controller.text;
    final lightningAddress = lightningAddressController.text;

    if (imageController.images.isNotEmpty &&
        imageController.images.first.file != null) {
      var data = await imageController.images.first.file!.readAsBytes();
      await getIt<Ndk>().blossom.uploadBlob(data: data);
      image = sha256.convert(data).toString();
    }

    await getIt<Ndk>().metadata.broadcastMetadata(
      Metadata(
        name: name,
        about: aboutMe,
        nip05: nip05,
        lud16: lightningAddress,
        picture: image,
      ),
    );
  }
}
