import 'dart:async';

import 'package:models/main.dart';

import 'stream_status.dart';

export 'package:models/main.dart' show Validation, Valid, Invalid, Unvalidated;

StreamWithStatus<Validation<T>> validateStream<T>({
  required StreamWithStatus<T> source,
  required Future<Validation<T>> Function(T item) validator,
  Duration debounce = const Duration(milliseconds: 300),
  bool closeSourceOnClose = false,
}) {
  return source.asyncMap(validator);
}
