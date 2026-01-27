import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/image_picker.cubit.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class EditListingController {
  Listing? l;
  final ImagePickerCubit imageController = ImagePickerCubit(maxImages: 12);
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  setState(Listing? data) {
    l = data;
    imageController.setImages(
      (data?.parsedContent.images ?? [])
          .map((i) => CustomImage.path(i))
          .toList(),
    );
    titleController.text = data?.parsedContent.title ?? '';
    descriptionController.text = data?.parsedContent.description ?? '';
  }

  save() async {
    for (var i = 0; i < imageController.images.length; i++) {
      var image = imageController.images[i];
      if (image.file != null) {
        var data = await image.file!.readAsBytes();
        await getIt<Ndk>().blossom.uploadBlob(data: data);
        var imagePath = sha256.convert(data).toString();
        imageController.images[i] = CustomImage.path(imagePath);
      }
    }

    final title = titleController.text;
    final description = descriptionController.text;

    // Use imageController.images as needed
    // await getIt<Ndk>()
    //     .broadcast
    //     .broadcast(
    //         nostrEvent: Nip01Event(
    //             pubKey: getIt<KeyStorage>().getActiveKeyPairSync()!.publicKey,
    //             kind: NOSTR_KIND_LISTING,
    //             tags: [
    //               ['a', l!.anchor]
    //             ],
    //             content: ListingContent(
    //                     title: title,
    //                     description: description,
    //                     price: l!.parsedContent.price,
    //                     minStay: l!.parsedContent.minStay,
    //                     checkIn: l!.parsedContent.checkIn,
    //                     checkOut: l!.parsedContent.checkOut,
    //                     location: l!.parsedContent.location,
    //                     quantity: 1,
    //                     type: l!.parsedContent.type,
    //                     images:
    //                         imageController.images.map((e) => e.path!).toList(),
    //                     amenities: l!.parsedContent.amenities)
    //                 .toString())
    //           ..sign(getIt<KeyStorage>().getActiveKeyPairSync()!.privateKey!))
    //     .broadcastDoneFuture;
  }
}
