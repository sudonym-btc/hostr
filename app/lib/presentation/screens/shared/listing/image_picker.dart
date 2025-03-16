import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/logic/cubit/image_picker.cubit.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';

class ImageUpload extends StatelessWidget {
  final ImagePickerCubit controller;
  final String pubkey;

  const ImageUpload(
      {super.key, required this.controller, required this.pubkey});

  @override
  Widget build(BuildContext context) {
    Widget buildButtons(BuildContext context) {
      return Row(
        children: [
          Expanded(
              child: FilledButton.tonal(
            onPressed: () {
              context.read<ImagePickerCubit>().pickMultipleImages();
            },
            child: Text(
              "Gallery",
            ),
          )),
          SizedBox(width: DEFAULT_PADDING.toDouble()),
          Expanded(
              child: FilledButton.tonal(
            onPressed: () {
              context.read<ImagePickerCubit>().captureImageWithCamera();
            },
            child: Text(
              "Camera",
            ),
          )),
        ],
      );
    }

    return BlocProvider.value(
      value: controller,
      child: BlocConsumer<ImagePickerCubit, ImagePickerState>(
        listener: (context, state) {
          if (state is ImageError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: controller.images.isNotEmpty
                      ? GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: min(3, controller.maxImages ?? 3),
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: controller.images.length,
                          itemBuilder: (context, index) {
                            final image = controller.images[index];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: image.path != null
                                      ? BlossomImage(
                                          image: image.path!,
                                          pubkey: pubkey,
                                        )
                                      : Image.file(File(image.file!.path),
                                          fit: BoxFit.cover),
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
                                      backgroundColor: Colors.red,
                                      child: Icon(Icons.close,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      : Text(
                          "No images selected yet",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                ),
                SizedBox(height: DEFAULT_PADDING.toDouble()),
                buildButtons(context),
              ],
            ),
          );
        },
      ),
    );
  }
}
