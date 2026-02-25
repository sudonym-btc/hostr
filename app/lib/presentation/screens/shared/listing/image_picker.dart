import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
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
          final atMax =
              controller.maxImages != null &&
              images.length >= controller.maxImages!;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 1),
                    pageSnapping: true,
                    itemCount: atMax ? images.length : images.length + 1,
                    itemBuilder: (context, index) {
                      if (index >= images.length) {
                        return CustomPadding.horizontal.xs(
                          child: Material(
                            color: Theme.of(context).colorScheme.surface,
                            child: InkWell(
                              onTap: () => context
                                  .read<ImagePickerCubit>()
                                  .pickMultipleImages(),
                              child: Container(
                                alignment: Alignment.center,
                                child:
                                    placeholder ?? _defaultPlaceholder(context),
                              ),
                            ),
                          ),
                        );
                      }

                      final image = images[index];
                      final uploading = controller.isImageUploading(index);
                      final error = controller.imageError(index);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          image.path != null
                              ? BlossomImage(image: image.path!, pubkey: pubkey)
                              : Image.file(
                                  File(image.file!.path),
                                  fit: BoxFit.cover,
                                ),
                          if (uploading)
                            Positioned.fill(
                              child: const _UploadShimmerOverlay(),
                            ),
                          if (error != null)
                            Positioned.fill(
                              child: _UploadErrorOverlay(
                                error: error,
                                onRetry: () => context
                                    .read<ImagePickerCubit>()
                                    .retryUpload(index),
                              ),
                            ),
                          Positioned(
                            top: kSpace2,
                            right: kSpace3,
                            child: SafeArea(
                              bottom: false,
                              left: false,
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
                          ),
                        ],
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
    return Center(
      child: FilledButton.tonalIcon(
        onPressed: () => context.read<ImagePickerCubit>().pickMultipleImages(),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(AppLocalizations.of(context)!.addImage),
      ),
    );
  }
}

/// Semi-transparent shimmer overlay shown on top of an image while it uploads.
class _UploadShimmerOverlay extends StatefulWidget {
  const _UploadShimmerOverlay();

  @override
  State<_UploadShimmerOverlay> createState() => _UploadShimmerOverlayState();
}

class _UploadShimmerOverlayState extends State<_UploadShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surface.withValues(alpha: 0.4);
    final highlight = Theme.of(
      context,
    ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 - 0.5;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(t - 0.6, -1),
              end: Alignment(t + 0.6, 1),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Error overlay shown on top of an image whose upload failed.
class _UploadErrorOverlay extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _UploadErrorOverlay({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.errorContainer.withValues(alpha: 0.85),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: colorScheme.onErrorContainer,
            size: kIconLg,
          ),
          Gap.vertical.xs(),
          Text(
            'Upload failed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap.vertical.xs(),
          Text(
            error,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
          ),
          Gap.vertical.sm(),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, color: colorScheme.onErrorContainer),
            label: Text(
              'Retry',
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
