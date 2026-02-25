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

  String _originalName = '';
  String _originalAbout = '';
  String _originalNip05 = '';
  String _originalLud16 = '';
  String? _originalPicture;

  @override
  bool get isDirty {
    if (nameController.text != _originalName) return true;
    if (aboutMeController.text != _originalAbout) return true;
    if (nip05Controller.text != _originalNip05) return true;
    if (lightningAddressController.text != _originalLud16) return true;
    final currentPicture = imageController.images.isNotEmpty
        ? imageController.images.first.path
        : null;
    if (currentPicture != _originalPicture) return true;
    return false;
  }

  @override
  bool get canSubmit => super.canSubmit && imageController.canSubmit;

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

    _originalName = nameController.text;
    _originalAbout = aboutMeController.text;
    _originalNip05 = nip05Controller.text;
    _originalLud16 = lightningAddressController.text;
    _originalPicture = profile?.metadata.picture;
  }

  @override
  Future<void> upsert() async {
    final image = imageController.resolvedPaths.isNotEmpty
        ? imageController.resolvedPaths.first
        : (imageController.images.isNotEmpty
              ? imageController.images.first.path
              : null);
    final name = nameController.text;
    final aboutMe = aboutMeController.text;
    final nip05 = nip05Controller.text;
    final lightningAddress = lightningAddressController.text;

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

    await getIt<Hostr>().metadata.upsert(profile);

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
