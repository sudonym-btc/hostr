import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:image_picker/image_picker.dart';

import 'image_picker_web_gallery_stub.dart'
    if (dart.library.js_interop) 'image_picker_web_gallery_web.dart'
    as web_gallery;

final _logger = CustomLogger();

class CustomImage {
  final String? path;
  final XFile? file;
  final Uint8List? previewBytes;

  CustomImage({this.path, this.file, this.previewBytes});
  CustomImage.file(this.file, {this.previewBytes}) : path = null;
  CustomImage.path(this.path) : file = null, previewBytes = null;

  CustomImage copyWith({
    String? path,
    XFile? file,
    Uint8List? previewBytes,
    bool clearPath = false,
    bool clearFile = false,
    bool clearPreviewBytes = false,
  }) {
    return CustomImage(
      path: clearPath ? null : (path ?? this.path),
      file: clearFile ? null : (file ?? this.file),
      previewBytes: clearPreviewBytes
          ? null
          : (previewBytes ?? this.previewBytes),
    );
  }
}

abstract class ImagePickerState {}

class ImageInitial extends ImagePickerState {}

class ImageLoading extends ImagePickerState {}

class ImageLoaded extends ImagePickerState {}

class ImageError extends ImagePickerState {
  final String message;
  ImageError({required this.message});
}

/// Cubit that manages image picking and automatic Blossom uploads.
///
/// Images are uploaded eagerly as soon as they are picked. Each image's upload
/// status is tracked individually so the UI can show a shimmer overlay on
/// images that are still uploading.
///
/// Exposes a [notifier] ([ChangeNotifier]) that fires whenever [canSubmit]
/// changes, allowing form controllers to merge it into their submit listenable.
class ImagePickerCubit extends Cubit<ImagePickerState> {
  static const List<String> defaultAllowedFileTypes = ['png', 'jpg'];

  final ImagePicker _picker = ImagePicker();
  final List<CustomImage> images = [];
  final int? maxImages;
  final Map<String, Future<Uint8List>> _inFlightByteReads = {};

  /// Indices currently being uploaded.
  final Set<int> _uploadingIndices = {};

  /// Indices that failed to upload, mapped to their error message.
  final Map<int, String> _failedIndices = {};

  /// A [ChangeNotifier] that fires whenever [canSubmit] changes.
  /// Form controllers can merge this into their submit listenable.
  final ChangeNotifier notifier = ChangeNotifier();

  ImagePickerCubit({this.maxImages}) : super(ImageInitial());

  /// Whether the image state allows form submission: no uploads in progress
  /// and no failed uploads.
  bool get canSubmit => _uploadingIndices.isEmpty && _failedIndices.isEmpty;

  /// Whether a specific image index is currently uploading.
  bool isImageUploading(int index) => _uploadingIndices.contains(index);

  /// Returns the error message for a failed upload at [index], or null.
  String? imageError(int index) => _failedIndices[index];

  /// Whether any upload is currently in progress.
  bool get isUploading => _uploadingIndices.isNotEmpty;

  /// Returns the resolved blossom paths (SHA-256 hashes or URLs) for all
  /// images that have been successfully uploaded.
  List<String> get resolvedPaths =>
      images.where((img) => img.path != null).map((img) => img.path!).toList();

  Future<void> pickMultipleImages({
    int limit = 10,
    List<String>? allowedFileTypes,
  }) => _logger.span('pickMultipleImages', () async {
    emit(ImageLoading());
    try {
      final allowedExtensions = _normalizeAllowedFileTypes(allowedFileTypes);
      final remainingSlots = maxImages == null
          ? null
          : (maxImages! - images.length).clamp(0, maxImages!);
      final effectiveLimit = remainingSlots == null
          ? limit
          : limit.clamp(0, remainingSlots);

      if (effectiveLimit <= 0) {
        emit(ImageLoaded());
        return;
      }

      final webPickedImages = await web_gallery.pickAllowedImagesFromGallery(
        allowedFileTypes: allowedExtensions.toList(),
        limit: effectiveLimit,
      );
      if (webPickedImages != null) {
        if (webPickedImages.isNotEmpty) {
          addImages(webPickedImages.map(CustomImage.file).toList());
        } else {
          emit(ImageLoaded());
        }
        return;
      }

      if (effectiveLimit == 1) {
        final XFile? pickedImage = await _logger.span(
          'pickSingleImageFromGallery',
          () => _picker.pickImage(source: ImageSource.gallery),
        );
        if (pickedImage != null) {
          final supportedImages = _supportedFiles([
            pickedImage,
          ], allowedExtensions);
          if (supportedImages.isNotEmpty) {
            addImages(supportedImages.map(CustomImage.file).toList());
          } else {
            emit(ImageLoaded());
          }
          _emitUnsupportedFileTypeError(
            allFiles: [pickedImage],
            supportedFiles: supportedImages,
            allowedExtensions: allowedExtensions,
          );
        } else {
          emit(ImageLoaded());
        }
        return;
      }

      final List<XFile> pickedImages = await _logger.span(
        'pickMultiImageFromGallery',
        () => _picker.pickMultiImage(limit: effectiveLimit),
      );
      final supportedImages = _supportedFiles(pickedImages, allowedExtensions);
      if (supportedImages.isNotEmpty) {
        addImages(supportedImages.map(CustomImage.file).toList());
      } else {
        emit(ImageLoaded());
      }
      _emitUnsupportedFileTypeError(
        allFiles: pickedImages,
        supportedFiles: supportedImages,
        allowedExtensions: allowedExtensions,
      );
    } catch (e) {
      emit(ImageError(message: "Failed to pick images: $e"));
    }
  });

  Future<void> captureImageWithCamera({List<String>? allowedFileTypes}) =>
      _logger.span('captureImageWithCamera', () async {
        emit(ImageLoading());
        try {
          final allowedExtensions = _normalizeAllowedFileTypes(
            allowedFileTypes,
          );
          final XFile? capturedImage = await _logger.span(
            'pickSingleImageFromCamera',
            () => _picker.pickImage(source: ImageSource.camera),
          );
          if (capturedImage != null) {
            final supportedImages = _supportedFiles([
              capturedImage,
            ], allowedExtensions);
            if (supportedImages.isNotEmpty) {
              addImages(supportedImages.map(CustomImage.file).toList());
            } else {
              emit(ImageLoaded());
            }
            _emitUnsupportedFileTypeError(
              allFiles: [capturedImage],
              supportedFiles: supportedImages,
              allowedExtensions: allowedExtensions,
            );
          } else {
            emit(ImageError(message: "No image captured"));
          }
        } catch (e) {
          emit(ImageError(message: "Failed to capture image: $e"));
        }
      });

  void removeImage(int index) {
    _uploadingIndices.remove(index);
    _failedIndices.remove(index);
    images.removeAt(index);
    // Shift uploading indices down for items after the removed one.
    final shiftedUploading = _uploadingIndices.where((i) => i > index).toList();
    for (final i in shiftedUploading) {
      _uploadingIndices.remove(i);
      _uploadingIndices.add(i - 1);
    }
    // Shift failed indices down too.
    final shiftedFailed = _failedIndices.entries
        .where((e) => e.key > index)
        .toList();
    for (final e in shiftedFailed) {
      _failedIndices.remove(e.key);
      _failedIndices[e.key - 1] = e.value;
    }
    _notifySubmitChanged();
    emit(ImageLoaded());
  }

  void setImages(List<CustomImage> images) => _logger.spanSync('setImages', () {
    _uploadingIndices.clear();
    _failedIndices.clear();
    this.images.clear();
    this.images.addAll(images);
    for (var i = 0; i < this.images.length; i++) {
      _ensurePreviewBytes(i);
    }
    _notifySubmitChanged();
    emit(ImageLoaded());
  });

  void addImages(List<CustomImage> newImages) => _logger.spanSync(
    'addImages',
    () {
      images.addAll(newImages);

      // Strip first images away if maxImages is reached.
      if (maxImages != null && images.length > maxImages!) {
        final removeCount = images.length - maxImages!;
        images.removeRange(0, removeCount);
        // Shift all uploading indices by removeCount.
        final shifted = _uploadingIndices.map((i) => i - removeCount).toList();
        _uploadingIndices.clear();
        _uploadingIndices.addAll(shifted.where((i) => i >= 0));
        // Shift failed indices too.
        final shiftedFailed = _failedIndices.entries
            .map((e) => MapEntry(e.key - removeCount, e.value))
            .where((e) => e.key >= 0);
        _failedIndices.clear();
        _failedIndices.addEntries(shiftedFailed);
      }

      emit(ImageLoaded());

      for (var i = 0; i < images.length; i++) {
        _ensurePreviewBytes(i);
      }

      // Kick off uploads for any newly added local files.
      for (var i = 0; i < images.length; i++) {
        if (images[i].file != null && !_uploadingIndices.contains(i)) {
          _uploadSingle(i);
        }
      }
    },
  );

  /// Uploads a single image at [index] to Blossom in the background.
  Future<void> _uploadSingle(
    int index,
  ) => _logger.span('_uploadSingle[$index]', () async {
    final image = images[index];
    if (image.file == null) return;

    _uploadingIndices.add(index);
    _notifySubmitChanged();
    emit(ImageLoaded());

    try {
      _logger.d('Uploading image $index to Blossom: ${image.file!.path}');
      final Uint8List data =
          image.previewBytes ??
          await _getImageBytes(
            image,
            index,
            spanName: '_readImageBytes[$index]',
          );

      if (index < images.length &&
          images[index].file?.path == image.file!.path &&
          images[index].previewBytes == null) {
        images[index] = images[index].copyWith(previewBytes: data);
        if (!isClosed) emit(ImageLoaded());
      }

      _logger.d('Image data size: ${data.length} bytes');
      final results = await _logger.span(
        '_uploadSingle[$index].uploadBlob',
        () => getIt<Hostr>().blossom.uploadBlob(data: data),
      );
      _logger.d('Blossom upload returned ${results.length} result(s)');

      var anySuccess = false;
      String? uploadedPath;
      for (final result in results) {
        if (result.success) {
          anySuccess = true;
          uploadedPath ??= result.descriptor?.sha256;
          _logger.d('Blossom upload succeeded: ${result.descriptor?.url}');
        } else {
          _logger.w('Blossom upload failed for a server', error: result.error);
        }
      }
      if (!anySuccess) {
        throw Exception('All Blossom servers rejected the upload');
      }
      if (uploadedPath == null || uploadedPath.isEmpty) {
        throw Exception('Blossom upload succeeded but no sha256 was returned');
      }
      _logger.d('Image SHA-256: $uploadedPath');

      // Guard: the image list may have been mutated while we were uploading.
      if (index < images.length &&
          images[index].file?.path == image.file!.path) {
        images[index] = images[index].copyWith(path: uploadedPath);
      }
    } catch (e, st) {
      _logger.e('Failed to upload image $index', error: e, stackTrace: st);
      _failedIndices[index] = e.toString();
    } finally {
      _uploadingIndices.remove(index);
      _notifySubmitChanged();
      if (!isClosed) emit(ImageLoaded());
    }
  });

  /// Retries a previously failed upload at [index].
  void retryUpload(int index) {
    if (!_failedIndices.containsKey(index)) return;
    _failedIndices.remove(index);
    _uploadSingle(index);
  }

  Future<void> _ensurePreviewBytes(int index) =>
      _logger.span('_ensurePreviewBytes[$index]', () async {
        if (index >= images.length) return;
        final image = images[index];
        if (image.file == null || image.previewBytes != null) return;

        try {
          final Uint8List bytes = await _getImageBytes(
            image,
            index,
            spanName: '_readImageBytes[$index]',
          );
          if (index < images.length &&
              images[index].file?.path == image.file!.path) {
            images[index] = image.copyWith(previewBytes: bytes);
            if (!isClosed) emit(ImageLoaded());
          }
        } catch (e, st) {
          _logger.w(
            'Failed to read image preview bytes for ${image.file!.path}',
            error: e,
            stackTrace: st,
          );
        }
      });

  Future<Uint8List> _getImageBytes(
    CustomImage image,
    int index, {
    required String spanName,
  }) async {
    final previewBytes = image.previewBytes;
    if (previewBytes != null) {
      return previewBytes;
    }

    final file = image.file;
    if (file == null) {
      throw StateError('Cannot read bytes for image $index without a file');
    }

    final cacheKey = file.path;
    final existing = _inFlightByteReads[cacheKey];
    if (existing != null) {
      return existing;
    }

    final future = _logger.span<Uint8List>(spanName, () => file.readAsBytes());
    _inFlightByteReads[cacheKey] = future;

    try {
      return await future;
    } finally {
      if (identical(_inFlightByteReads[cacheKey], future)) {
        _inFlightByteReads.remove(cacheKey);
      }
    }
  }

  Set<String> _normalizeAllowedFileTypes(List<String>? allowedFileTypes) {
    final normalized = <String>{};
    for (final extension
        in (allowedFileTypes == null || allowedFileTypes.isEmpty)
            ? defaultAllowedFileTypes
            : allowedFileTypes) {
      final cleaned = extension.trim().toLowerCase().replaceFirst('.', '');
      if (cleaned.isEmpty) continue;
      normalized.add(cleaned);
      if (cleaned == 'jpg') normalized.add('jpeg');
      if (cleaned == 'jpeg') normalized.add('jpg');
    }
    if (normalized.isEmpty) {
      normalized.addAll(const {'png', 'jpg', 'jpeg'});
    }
    return normalized;
  }

  List<XFile> _supportedFiles(
    List<XFile> files,
    Set<String> allowedExtensions,
  ) {
    return files
        .where((file) => _isAllowedFileType(file, allowedExtensions))
        .toList();
  }

  bool _isAllowedFileType(XFile file, Set<String> allowedExtensions) {
    final fileName = _fileNameFor(file);
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < fileName.length - 1) {
      final extension = fileName.substring(dotIndex + 1).toLowerCase();
      if (allowedExtensions.contains(extension)) {
        return true;
      }
    }

    final mimeType = file.mimeType?.trim().toLowerCase();
    if (mimeType == null || mimeType.isEmpty) {
      return false;
    }

    return _allowedMimeTypesForExtensions(allowedExtensions).contains(mimeType);
  }

  String _fileNameFor(XFile file) {
    final name = file.name.trim();
    if (name.isNotEmpty) {
      return name;
    }
    final path = file.path;
    final slashIndex = path.lastIndexOf('/');
    return slashIndex == -1 ? path : path.substring(slashIndex + 1);
  }

  void _emitUnsupportedFileTypeError({
    required List<XFile> allFiles,
    required List<XFile> supportedFiles,
    required Set<String> allowedExtensions,
  }) {
    if (supportedFiles.length == allFiles.length) {
      return;
    }

    final rejectedFiles = allFiles
        .where((file) => !supportedFiles.contains(file))
        .map(_fileNameFor)
        .toList();
    if (rejectedFiles.isEmpty) {
      return;
    }

    final allowedLabel = allowedExtensions.toList()..sort();
    emit(
      ImageError(
        message:
            'Unsupported image type for ${rejectedFiles.join(', ')}. Allowed: ${allowedLabel.join(', ')}.',
      ),
    );
  }

  Set<String> _allowedMimeTypesForExtensions(Set<String> allowedExtensions) {
    final mimeTypes = <String>{};
    for (final extension in allowedExtensions) {
      switch (extension) {
        case 'png':
          mimeTypes.add('image/png');
        case 'jpg':
        case 'jpeg':
          mimeTypes.add('image/jpeg');
      }
    }
    return mimeTypes;
  }

  /// Notifies the [notifier] so form controllers can react to submit-ability
  /// changes.
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  void _notifySubmitChanged() => notifier.notifyListeners();

  @override
  Future<void> close() {
    notifier.dispose();
    return super.close();
  }
}
