import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:image_picker/image_picker.dart';

final _logger = CustomLogger();

class CustomImage {
  final String? path;
  final XFile? file;

  CustomImage({this.path, this.file});
  CustomImage.file(this.file) : path = null;
  CustomImage.path(this.path) : file = null;
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
  final ImagePicker _picker = ImagePicker();
  final List<CustomImage> images = [];
  final int? maxImages;

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

  Future<void> pickMultipleImages() async {
    emit(ImageLoading());
    try {
      final List<XFile> pickedImages = await _picker.pickMultiImage();
      addImages(pickedImages.map((e) => CustomImage.file(e)).toList());
    } catch (e) {
      emit(ImageError(message: "Failed to pick images: $e"));
    }
  }

  Future<void> captureImageWithCamera() async {
    emit(ImageLoading());
    try {
      final XFile? capturedImage = await _picker.pickImage(
        source: ImageSource.camera,
      );
      if (capturedImage != null) {
        addImages([CustomImage.file(capturedImage)]);
      } else {
        emit(ImageError(message: "No image captured"));
      }
    } catch (e) {
      emit(ImageError(message: "Failed to capture image: $e"));
    }
  }

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

  void setImages(List<CustomImage> images) {
    _uploadingIndices.clear();
    _failedIndices.clear();
    this.images.clear();
    this.images.addAll(images);
    _notifySubmitChanged();
    emit(ImageLoaded());
  }

  void addImages(List<CustomImage> newImages) {
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

    // Kick off uploads for any newly added local files.
    for (var i = 0; i < images.length; i++) {
      if (images[i].file != null && !_uploadingIndices.contains(i)) {
        _uploadSingle(i);
      }
    }
  }

  /// Uploads a single image at [index] to Blossom in the background.
  Future<void> _uploadSingle(int index) async {
    final image = images[index];
    if (image.file == null) return;

    _uploadingIndices.add(index);
    _notifySubmitChanged();
    emit(ImageLoaded());

    try {
      _logger.d('Uploading image $index to Blossom: ${image.file!.path}');
      final data = await image.file!.readAsBytes();
      _logger.d('Image data size: ${data.length} bytes');
      final results = await getIt<Hostr>().blossom.uploadBlob(data: data);
      _logger.d('Blossom upload returned ${results.length} result(s)');

      var anySuccess = false;
      for (final result in results) {
        if (result.success) {
          anySuccess = true;
          _logger.d('Blossom upload succeeded: ${result.descriptor?.url}');
        } else {
          _logger.w('Blossom upload failed for a server', error: result.error);
        }
      }
      if (!anySuccess) {
        throw Exception('All Blossom servers rejected the upload');
      }

      final hash = sha256.convert(data).toString();
      _logger.d('Image SHA-256: $hash');

      // Guard: the image list may have been mutated while we were uploading.
      if (index < images.length &&
          images[index].file?.path == image.file!.path) {
        images[index] = CustomImage.path(hash);
      }
    } catch (e, st) {
      _logger.e('Failed to upload image $index', error: e, stackTrace: st);
      _failedIndices[index] = e.toString();
    } finally {
      _uploadingIndices.remove(index);
      _notifySubmitChanged();
      if (!isClosed) emit(ImageLoaded());
    }
  }

  /// Retries a previously failed upload at [index].
  void retryUpload(int index) {
    if (!_failedIndices.containsKey(index)) return;
    _failedIndices.remove(index);
    _uploadSingle(index);
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
