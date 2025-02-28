import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';

class ImageUpload extends StatelessWidget {
  const ImageUpload({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ImagePickerCubit(),
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
          final images = context.watch<ImagePickerCubit>().images;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<ImagePickerCubit>().pickMultipleImages();
                      },
                      icon: Icon(Icons.photo_library, color: Colors.white),
                      label: Text(
                        "Browse Gallery",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<ImagePickerCubit>()
                            .captureImageWithCamera();
                      },
                      icon: Icon(Icons.camera_alt, color: Colors.white),
                      label: Text(
                        "Capture Image with Camera",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Expanded(
                  child: images.isNotEmpty
                      ? GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            final image = images[index];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(image.path),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
