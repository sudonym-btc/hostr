import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class E2eImagePickerPlatform extends ImagePickerPlatform {
  E2eImagePickerPlatform(this.files);

  final List<XFile> files;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    if (files.isEmpty) return null;
    return files.first;
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    return files;
  }

  @override
  Future<List<XFile>> getMedia({required MediaOptions options}) async {
    return files;
  }

  @override
  Future<LostDataResponse> getLostData() async {
    return LostDataResponse.empty();
  }
}
