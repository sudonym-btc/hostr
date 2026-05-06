class HostrCancellationException implements Exception {
  const HostrCancellationException([this.message = 'Request was cancelled.']);

  final String message;

  @override
  String toString() => message;
}

class HostrCancellationToken {
  final _callbacks = <void Function()>[];
  var _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final callback in List<void Function()>.from(_callbacks)) {
      callback();
    }
    _callbacks.clear();
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw const HostrCancellationException();
    }
  }

  void onCancel(void Function() callback) {
    if (_cancelled) {
      callback();
      return;
    }
    _callbacks.add(callback);
  }
}
