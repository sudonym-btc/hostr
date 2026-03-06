import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'stream_status.dart';

abstract class Validation<T> {
  final T event;
  const Validation(this.event);
}

class Valid<T> extends Validation<T> {
  const Valid(super.event);
}

class Invalid<T> extends Validation<T> {
  final String reason;
  const Invalid(super.event, this.reason);
}

StreamWithStatus<Validation<T>> validateStream<T>({
  required StreamWithStatus<T> source,
  required Future<List<Validation<T>>> Function(List<T> snapshot) validator,
  Duration debounce = const Duration(milliseconds: 300),
  bool closeSourceOnClose = false,
}) {
  late final StreamSubscription<StreamStatus> statusSub;
  late final StreamSubscription<List<Validation<T>>> listSub;
  var hasValidatedAtLeastOnce = false;
  StreamStatus? latestSourceStatus;

  final response = StreamWithStatus<Validation<T>>(
    onClose: () async {
      await statusSub.cancel();
      await listSub.cancel();
      if (closeSourceOnClose) {
        await source.close();
      }
    },
  );

  statusSub = source.status.listen((status) {
    latestSourceStatus = status;
    if (status is StreamStatusError) {
      response.addStatus(status);
      return;
    }

    // Avoid advertising source "live" state before first validation
    // snapshot has finished.
    if (hasValidatedAtLeastOnce) {
      response.addStatus(status);
    }
  }, onError: response.addError);

  listSub = source.list
      .debounceTime(debounce)
      .asyncMap((items) async {
        response.addStatus(StreamStatusQuerying());
        return validator(List.unmodifiable(items));
      })
      .listen((validatedSnapshot) {
        response.setSnapshot(validatedSnapshot);
        hasValidatedAtLeastOnce = true;
        if (latestSourceStatus != null) {
          response.addStatus(latestSourceStatus!);
        }
      }, onError: response.addError);

  return response;
}
