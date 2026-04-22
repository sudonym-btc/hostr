import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/cubit/image_picker.cubit.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';

class ImageUpload extends StatefulWidget {
  final ImagePickerCubit controller;
  final String pubkey;
  final Widget? placeholder;
  final List<String> allowedFileTypes;

  const ImageUpload({
    super.key,
    required this.controller,
    required this.pubkey,
    this.placeholder,
    this.allowedFileTypes = ImagePickerCubit.defaultAllowedFileTypes,
  });

  @override
  State<ImageUpload> createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
  late final PageController _pageController;
  int _currentPage = 0;

  bool get _isSingleImageMode => widget.controller.maxImages == 1;
  static const double _filmstripHeight = 88;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickMultipleImages(BuildContext context) {
    return context.read<ImagePickerCubit>().pickMultipleImages(
      allowedFileTypes: widget.allowedFileTypes,
    );
  }

  void _animateToPage(int page) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _shiftImage(BuildContext context, int from, int to) {
    context.read<ImagePickerCubit>().reorderImage(from, to);
    _animateToPage(to);
  }

  void _removeImage(BuildContext context, int index) {
    context.read<ImagePickerCubit>().removeImage(index);
    final remaining = widget.controller.images.length;
    final target = remaining <= 0
        ? 0
        : (index < _currentPage ? _currentPage - 1 : _currentPage).clamp(
            0,
            remaining - 1,
          );

    if (_currentPage != target) {
      setState(() => _currentPage = target);
    }
    if (remaining > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(target);
      });
    }
  }

  void _clampPage(int itemCount) {
    if (itemCount <= 0) {
      _currentPage = 0;
      return;
    }
    final maxPage = itemCount - 1;
    if (_currentPage <= maxPage) {
      return;
    }

    final targetPage = maxPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      _pageController.jumpToPage(targetPage);
      if (_currentPage != targetPage) {
        setState(() => _currentPage = targetPage);
      }
    });
  }

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
      value: widget.controller,
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
          final images = widget.controller.images;
          final atMax =
              widget.controller.maxImages != null &&
              images.length >= widget.controller.maxImages!;
          final itemCount = images.length;
          final hasImages = images.isNotEmpty;
          _clampPage(itemCount);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    AppCarousel(
                      controller: _pageController,
                      currentIndex: _currentPage,
                      itemCount: itemCount,
                      padEnds: !_isSingleImageMode,
                      showArrows: !_isSingleImageMode,
                      bottomControlsHeight: _isSingleImageMode || !hasImages
                          ? 0
                          : _filmstripHeight,
                      storageKey: const PageStorageKey<String>(
                        'image-upload-carousel',
                      ),
                      placeholder:
                          widget.placeholder ?? _defaultPlaceholder(context),
                      onPlaceholderTap: () => _pickMultipleImages(context),
                      onPageChanged: (page) {
                        if (_currentPage != page) {
                          setState(() => _currentPage = page);
                        }
                      },
                      itemBuilder: (context, index) {
                        final image = images[index];
                        final uploading = widget.controller.isImageUploading(
                          index,
                        );
                        final error = widget.controller.imageError(index);
                        final imageKey =
                            image.file?.path ?? image.path ?? index.toString();
                        return Stack(
                          key: ValueKey<String>(imageKey),
                          fit: StackFit.expand,
                          children: [
                            _ImagePreview(image: image, pubkey: widget.pubkey),
                            if (uploading)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: const _UploadShimmerOverlay(),
                                ),
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
                          ],
                        );
                      },
                    ),
                    if (hasImages && !_isSingleImageMode)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: EditableCarouselFilmstrip<CustomImage>(
                          items: images,
                          currentIndex: _currentPage.clamp(
                            0,
                            images.length - 1,
                          ),
                          atMax: atMax,
                          onAdd: () => _pickMultipleImages(context),
                          onSelect: (index) {
                            if (_currentPage != index) {
                              setState(() => _currentPage = index);
                            }
                            _animateToPage(index);
                          },
                          onDelete: (index) => _removeImage(context, index),
                          onReorder: (from, to) =>
                              _shiftImage(context, from, to),
                          keyBuilder: (image, index) => ValueKey(
                            'image-thumbnail-${image.file?.path ?? image.path ?? index}',
                          ),
                          thumbnailBuilder: (context, image, index) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                _ImagePreview(
                                  image: image,
                                  pubkey: widget.pubkey,
                                ),
                                if (widget.controller.isImageUploading(index))
                                  const _UploadShimmerOverlay(),
                                if (widget.controller.imageError(index) != null)
                                  ColoredBox(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .errorContainer
                                        .withValues(alpha: 0.82),
                                    child: Icon(
                                      Icons.cloud_off_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                      size: kIconMd,
                                    ),
                                  ),
                                // Positioned(
                                //   left: kSpace1,
                                //   top: kSpace1,
                                //   child: _ThumbnailIndexBadge(index: index),
                                // ),
                              ],
                            );
                          },
                        ),
                      ),
                    if (hasImages && _isSingleImageMode)
                      Positioned(
                        top: kSpace2,
                        right: kSpace3,
                        child: SafeArea(
                          bottom: false,
                          left: false,
                          child: AppCarouselIconButton(
                            icon: Icons.close_rounded,
                            tooltip: 'Remove photo',
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.errorContainer,
                            foregroundColor: Colors.white,
                            onPressed: () => _removeImage(context, 0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _defaultPlaceholder(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: () => _pickMultipleImages(context),
        style: AppButtonStyles.secondary(context),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(AppLocalizations.of(context)!.addImage),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final CustomImage image;
  final String pubkey;

  const _ImagePreview({required this.image, required this.pubkey});

  @override
  Widget build(BuildContext context) {
    if (image.previewBytes != null) {
      return _LocalImagePreview(
        bytes: image.previewBytes!,
        filePath: image.file?.path,
        uploadedImageRef: image.path,
        pubkey: pubkey,
      );
    }

    if (image.file != null) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: const Center(child: AppLoadingIndicator.small()),
      );
    }

    if (image.path != null) {
      return BlossomImage(image: image.path!, pubkey: pubkey);
    }

    return const ImageLoadError(message: 'Preview unavailable');
  }
}

class _LocalImagePreview extends StatelessWidget {
  final Uint8List bytes;
  final String? filePath;
  final String? uploadedImageRef;
  final String pubkey;

  const _LocalImagePreview({
    required this.bytes,
    required this.pubkey,
    this.filePath,
    this.uploadedImageRef,
  });

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        final blossomRef = uploadedImageRef;
        if (blossomRef != null && blossomRef.isNotEmpty) {
          return BlossomImage(image: blossomRef, pubkey: pubkey);
        }

        final path = filePath;
        if (path != null && path.isNotEmpty) {
          return Image.network(
            path,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const ImageLoadError(message: 'Preview unavailable'),
          );
        }

        return const ImageLoadError(message: 'Preview unavailable');
      },
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
          FilledButton.icon(
            onPressed: onRetry,
            style: AppButtonStyles.secondary(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
