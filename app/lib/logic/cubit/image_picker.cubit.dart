import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

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

class ImagePickerCubit extends Cubit<ImagePickerState> {
  final ImagePicker _picker = ImagePicker();
  final List<CustomImage> images = [];
  final int? maxImages;
  final List<String> blossom = [];

  ImagePickerCubit({this.maxImages}) : super(ImageInitial());

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
      final XFile? capturedImage =
          await _picker.pickImage(source: ImageSource.camera);
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
    if (state is ImageLoaded) {
      images.removeAt(index);
      return emit(ImageLoaded());
    }
    emit(ImageLoaded());
  }

  void setImages(List<CustomImage> images) {
    this.images.clear();
    this.images.addAll(images);
    emit(ImageLoaded());
  }

  void addImages(List<CustomImage> images) {
    this.images.addAll(images);

    /// Strip first images away if maxImages is reached
    if (maxImages != null && this.images.length > maxImages!) {
      this.images.removeRange(0, this.images.length - maxImages!);
    }
    emit(ImageLoaded());
  }

  void setBlossom(List<String> blossom) {
    this.blossom.clear();
    this.blossom.addAll(blossom);
  }
}
