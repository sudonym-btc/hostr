import 'dart:async';

import 'package:bloc/bloc.dart';

extension BlocDetachX<S> on BlocBase<S> {
  /// Safely tears down the cubit when it is no longer needed by a widget.
  ///
  /// If the cubit is already in a terminal state (per [isTerminal]) or is
  /// already closed, it is closed immediately (no-op if already closed).
  ///
  /// If an operation is still in-flight, a one-shot stream listener is
  /// registered that will call [close] once the cubit reaches a terminal
  /// state — allowing the async work to complete even after its host widget
  /// has been disposed.
  void detachOrClose(bool Function(S state) isTerminal) {
    if (isClosed) return;
    if (isTerminal(state)) {
      close();
      return;
    }
    // In-flight: orphan the cubit and let it self-close when done.
    late StreamSubscription<S> sub;
    sub = stream.listen(
      (s) {
        if (isTerminal(s)) {
          sub.cancel();
          if (!isClosed) close();
        }
      },
      onError: (_, __) {
        sub.cancel();
        if (!isClosed) close();
      },
      onDone: () => sub.cancel(),
    );
  }
}
