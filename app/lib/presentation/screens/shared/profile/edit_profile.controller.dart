import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/image_picker.cubit.dart';
import 'package:ndk/ndk.dart';

class EditProfileController {
  final ImagePickerCubit imageController = ImagePickerCubit(maxImages: 1);
  final TextEditingController nameController = TextEditingController();
  final TextEditingController aboutMeController = TextEditingController();
  final TextEditingController nip05Controller = TextEditingController();
  final TextEditingController lightningAddressController =
      TextEditingController();

  setState(Metadata? metadata) {
    imageController.setImages(
        metadata?.picture != null ? [CustomImage.path(metadata?.picture)] : []);
    nameController.text = metadata?.name ?? '';
    aboutMeController.text = metadata?.about ?? '';
    nip05Controller.text = metadata?.nip05 ?? '';
    lightningAddressController.text = metadata?.lud16 ?? '';
  }

  save() async {
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
      List<BlobUploadResult> blob =
          await getIt<Ndk>().blossom.uploadBlob(data: data);
      image = sha256.convert(data).toString();
    }

    await getIt<Ndk>().metadata.broadcastMetadata(Metadata(
        name: name,
        about: aboutMe,
        nip05: nip05,
        lud16: lightningAddress,
        picture: image));
    // ignore: avoid_print
    print('Display Name: $name');
    print('About Me: $aboutMe');
    print('NIP 05: $nip05');
    print('Lightning Address: $lightningAddress');
    print('Image: $image');
  }
}
