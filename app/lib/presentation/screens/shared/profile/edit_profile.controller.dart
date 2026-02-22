import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/image_picker.cubit.dart';
import 'package:hostr/logic/forms/upsert_form_controller.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class EditProfileController extends UpsertFormController {
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

  @override
  Future<void> upsert() async {
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

    final metadata = Metadata(
      name: name,
      about: aboutMe,
      nip05: nip05,
      lud16: lightningAddress,
      picture: image,
    );
    metadata.pubKey = getIt<Hostr>().auth.getActiveKey().publicKey;
    final profile = ProfileMetadata.fromNostrEvent(
      metadata.toEvent(),
    ).withEvmAddress(getIt<Hostr>().auth.getActiveEvmKey().address.eip55With0x);

    await getIt<Hostr>().metadata.create(profile);

    // Notify listeners (e.g. ProfileProvider) that metadata was updated.
    final updated = await getIt<Hostr>().metadata.loadMetadata(
      getIt<Hostr>().auth.activeKeyPair!.publicKey,
    );
    if (updated != null) {
      getIt<Hostr>().metadata.notifyUpdate(updated);
    }
  }

  String? validateNip05(String? value) {
    return _validateEmailLike(value, label: 'NIP 05');
  }

  String? validateLightningAddress(String? value) {
    return _validateEmailLike(value, label: 'Lightning address');
  }

  String? _validateEmailLike(String? value, {required String label}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
    if (!valid) {
      return '$label must look like name@example.com';
    }
    return null;
  }
}
