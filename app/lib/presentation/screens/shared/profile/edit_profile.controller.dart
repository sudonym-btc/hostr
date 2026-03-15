import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/image_picker.cubit.dart';
import 'package:hostr/logic/forms/image_field_controller.dart';
import 'package:hostr/logic/forms/text_field_controller.dart';
import 'package:hostr/logic/forms/upsert_form_controller.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class EditProfileController extends UpsertFormController {
  // ── Sub-controllers ─────────────────────────────────────────────
  final ImageFieldController imageField = ImageFieldController(maxImages: 1);
  final TextFieldController nameField = TextFieldController();
  final TextFieldController aboutMeField = TextFieldController();
  final TextFieldController nip05Field = TextFieldController(
    validator: (v) => _validateEmailLike(v, label: 'NIP 05'),
  );
  final TextFieldController lightningAddressField = TextFieldController(
    validator: (v) => _validateEmailLike(v, label: 'Lightning address'),
  );

  /// Validity signals set by the input widgets themselves.
  final ValueNotifier<bool> nip05Valid = ValueNotifier(true);
  final ValueNotifier<bool> lnurlValid = ValueNotifier(true);

  EditProfileController() {
    registerField(imageField);
    registerField(nameField);
    registerField(aboutMeField);
    registerField(nip05Field);
    registerField(lightningAddressField);
    registerListenable(nip05Valid);
    registerListenable(lnurlValid);
  }

  @override
  bool get canSubmit => super.canSubmit && nip05Valid.value && lnurlValid.value;

  void setState(ProfileMetadata? profile) {
    imageField.setImages(
      profile?.metadata.picture != null
          ? [CustomImage.path(profile?.metadata.picture)]
          : [],
    );
    nameField.setState(profile?.metadata.name ?? '');
    aboutMeField.setState(profile?.metadata.about ?? '');
    nip05Field.setState(profile?.metadata.nip05 ?? '');
    lightningAddressField.setState(profile?.metadata.lud16 ?? '');
  }

  @override
  Future<void> upsert() async {
    final image = imageField.resolvedPaths.isNotEmpty
        ? imageField.resolvedPaths.first
        : (imageField.images.isNotEmpty ? imageField.images.first.path : null);
    final name = nameField.text;
    final aboutMe = aboutMeField.text;
    final nip05 = nip05Field.text;
    final lightningAddress = lightningAddressField.text;

    final metadata = Metadata(
      name: name,
      about: aboutMe,
      nip05: nip05,
      lud16: lightningAddress,
      picture: image,
    );
    metadata.pubKey = getIt<Hostr>().auth.getActiveKey().publicKey;
    final profile = ProfileMetadata.fromNostrEvent(metadata.toEvent())
        .withEvmAddress(
          (await getIt<Hostr>().auth.hd.getActiveEvmKey()).address.eip55With0x,
        );

    await getIt<Hostr>().metadata.upsert(profile);

    // Notify listeners (e.g. ProfileProvider) that metadata was updated.
    final updated = await getIt<Hostr>().metadata.loadMetadata(
      getIt<Hostr>().auth.activeKeyPair!.publicKey,
    );
    if (updated != null) {
      getIt<Hostr>().metadata.notifyUpdate(updated);
    }
  }

  static String? _validateEmailLike(String? value, {required String label}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
    if (!valid) return '$label must look like name@example.com';
    return null;
  }
}
