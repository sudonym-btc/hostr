import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/cubit/image_picker.cubit.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';

class ImageUpload extends StatelessWidget {
  final ImagePickerCubit controller;
  final String pubkey;
  final Widget? placeholder;

  const ImageUpload({
    super.key,
    required this.controller,
    required this.pubkey,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    // Widget buildButtons(BuildContext context) {
    //   return Row(
    //     children: [
    //       Expanded(
    //         child: FilledButton.tonal(
    //           onPressed: () {
    //             context.read<ImagePickerCubit>().pickMultipleImages();
    //           },
    //           child: Text("Gallery"),
    //         ),
    //       ),
    //       SizedBox(width: kDefaultPadding.toDouble()),
    //       Expanded(
    //         child: FilledButton.tonal(
    //           onPressed: () {
    //             context.read<ImagePickerCubit>().captureImageWithCamera();
    //           },
    //           child: Text("Camera"),
    //         ),
    //       ),
    //     ],
    //   );
    // }

    return BlocProvider.value(
      value: controller,
      child: BlocConsumer<ImagePickerCubit, ImagePickerState>(
        listener: (context, state) {
          if (state is ImageError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final images = controller.images;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.9),
                    pageSnapping: true,
                    itemCount: images.length + 1,
                    itemBuilder: (context, index) {
                      if (index >= images.length) {
                        return CustomPadding.horizontal.xs(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Material(
                              color: Theme.of(context).colorScheme.surface,
                              child: InkWell(
                                onTap: () => context
                                    .read<ImagePickerCubit>()
                                    .pickMultipleImages(),
                                child: Container(
                                  alignment: Alignment.center,
                                  child:
                                      placeholder ??
                                      _defaultPlaceholder(context),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final image = images[index];
                      return CustomPadding.horizontal.xs(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: image.path != null
                                  ? BlossomImage(
                                      image: image.path!,
                                      pubkey: pubkey,
                                    )
                                  : Image.file(
                                      File(image.file!.path),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 7,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => context
                                    .read<ImagePickerCubit>()
                                    .removeImage(index),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  child: Icon(
                                    Icons.close,
                                    size: kIconSm,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // SizedBox(height: kDefaultPadding.toDouble()),
                // buildButtons(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _defaultPlaceholder(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          color: Theme.of(context).colorScheme.onSurface,
          size: kIconXl,
        ),
        Gap.vertical.sm(),
        Text('Add Image', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
