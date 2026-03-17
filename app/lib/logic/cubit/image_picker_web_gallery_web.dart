import 'dart:async';
import 'dart:js_interop';

import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

Future<List<XFile>?> pickAllowedImagesFromGallery({
  required List<String> allowedFileTypes,
  required int limit,
}) async {
  final normalizedExtensions = <String>{};
  for (final extension in allowedFileTypes) {
    final cleaned = extension.trim().toLowerCase().replaceFirst('.', '');
    if (cleaned.isEmpty) continue;
    normalizedExtensions.add(cleaned);
    if (cleaned == 'jpg') normalizedExtensions.add('jpeg');
    if (cleaned == 'jpeg') normalizedExtensions.add('jpg');
  }

  if (normalizedExtensions.isEmpty) {
    normalizedExtensions.addAll(const {'png', 'jpg', 'jpeg'});
  }

  final acceptTokens = <String>{};
  for (final extension in normalizedExtensions) {
    acceptTokens.add('.$extension');
    switch (extension) {
      case 'png':
        acceptTokens.add('image/png');
      case 'jpg':
      case 'jpeg':
        acceptTokens.add('image/jpeg');
    }
  }

  final input = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = limit > 1
    ..accept = acceptTokens.join(',');

  final completer = Completer<List<XFile>>();

  input.onchange = (web.Event event) {
    final currentInput = event.target as web.HTMLInputElement?;
    final fileList = currentInput?.files;
    final files = <web.File>[];
    if (fileList != null) {
      for (var i = 0; i < fileList.length; i++) {
        final file = fileList.item(i);
        if (file != null) {
          files.add(file);
        }
      }
    }
    if (!completer.isCompleted) {
      completer.complete(
        files.take(limit).map((file) {
          return XFile(
            web.URL.createObjectURL(file),
            name: file.name,
            length: file.size,
            lastModified: DateTime.fromMillisecondsSinceEpoch(
              file.lastModified,
            ),
            mimeType: file.type,
          );
        }).toList(),
      );
    }
  }.toJS;

  input.oncancel = (web.Event _) {
    if (!completer.isCompleted) {
      completer.complete(const <XFile>[]);
    }
  }.toJS;

  input.onerror = (web.Event event) {
    if (!completer.isCompleted) {
      completer.completeError(event);
    }
  }.toJS;

  web.document.body?.append(input);
  input.click();

  try {
    return await completer.future;
  } finally {
    input.remove();
  }
}
