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

class ValidatedStreamWithStatus<T> {
  Function? onClose;

  final BehaviorSubject<List<Validation<T>>> _listSubject =
      BehaviorSubject<List<Validation<T>>>.seeded(const []);
  final BehaviorSubject<StreamStatus> status =
      BehaviorSubject<StreamStatus>.seeded(StreamStatusIdle());

  ValidatedStreamWithStatus({this.onClose});

  Stream<List<Validation<T>>> get stream => _listSubject.stream;

  ValueStream<List<Validation<T>>> get list => _listSubject;

  void addStatus(StreamStatus next) {
    status.add(next);
  }

  void addError(Object error, StackTrace? stackTrace) {
    status.add(StreamStatusError(error, stackTrace));
  }

  void setSnapshot(List<Validation<T>> snapshot) {
    _listSubject.add(List.unmodifiable(snapshot));
  }

  Future<void> close() async {
    await onClose?.call();
    await status.close();
    await _listSubject.close();
  }
}

ValidatedStreamWithStatus<T> validateStream<T>({
  required StreamWithStatus<T> source,
  required Future<List<Validation<T>>> Function(List<T> snapshot) validator,
  Duration debounce = const Duration(milliseconds: 300),
  bool closeSourceOnClose = false,
}) {
  late final StreamSubscription<StreamStatus> statusSub;
  late final StreamSubscription<List<Validation<T>>> listSub;
  var hasValidatedAtLeastOnce = false;
  StreamStatus? latestSourceStatus;

  final response = ValidatedStreamWithStatus<T>(
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
