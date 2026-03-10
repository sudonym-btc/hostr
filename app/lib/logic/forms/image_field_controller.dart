import 'package:collection/collection.dart';
import 'package:hostr/logic/cubit/image_picker.cubit.dart';
import 'package:hostr/logic/forms/form_field_controller.dart';

/// A [FormFieldController] wrapping an [ImagePickerCubit].
///
/// Tracks dirty state by comparing current image paths to the original set.
class ImageFieldController extends FormFieldController {
  final ImagePickerCubit cubit;
  List<String?> _originalPaths = [];

  ImageFieldController({int? maxImages})
    : cubit = ImagePickerCubit(maxImages: maxImages) {
    cubit.notifier.addListener(notifyListeners);
  }

  @override
  bool get isDirty {
    final currentPaths = cubit.images.map((i) => i.path).toList();
    if (_originalPaths.length != currentPaths.length) return true;
    return !const ListEquality<String?>().equals(_originalPaths, currentPaths);
  }

  @override
  bool get canSubmit => cubit.canSubmit;

  void setImages(List<CustomImage> images) {
    cubit.setImages(images);
    _originalPaths = images.map((i) => i.path).toList();
    notifyListeners();
  }

  List<String> get resolvedPaths => cubit.resolvedPaths;
  List<CustomImage> get images => cubit.images;

  @override
  void dispose() {
    cubit.notifier.removeListener(notifyListeners);
    super.dispose();
  }
}
