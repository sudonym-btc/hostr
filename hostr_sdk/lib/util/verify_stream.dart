import 'dart:async';

import 'package:ndk/ndk.dart' show Nip01Event;
import 'package:rxdart/rxdart.dart';

import 'stream_status.dart';
import 'validation_stream.dart';

/// Verifies items from a [StreamWithStatus] individually as they arrive.
///
/// Unlike [validateStream] which validates the entire snapshot at once,
/// [verifyStream] runs [resolve] and [verify] per-item. This lets
/// verification start as soon as the first item loads. The underlying
/// data sources (e.g. [CrudUseCase.findByTag], [CrudUseCase.getOne]) are
/// expected to batch concurrent requests via their own debounce queues,
/// so the per-item [resolve] calls naturally coalesce into bulk queries
/// without the caller needing to be aware of batching.
///
/// [resolve] fetches whatever dependencies are needed to verify one item.
/// Multiple [resolve] calls run concurrently, so their internal fetches
/// hit the same debounce window.
///
/// [verify] is a synchronous, pure function that decides if an item is
/// [Valid] or [Invalid] given its resolved dependencies.
///
/// Status propagation: [StreamStatusQuerying] is forwarded immediately.
/// [StreamStatusQueryComplete] and [StreamStatusLive] are deferred until
/// all pending verify operations drain, so downstream never sees "live"
/// while verifications are still in-flight.
ValidatedStreamWithStatus<T> verifyStream<T extends Nip01Event, TDeps>({
  required StreamWithStatus<T> source,
  required Future<TDeps> Function(T item) resolve,
  required Validation<T> Function(T item, TDeps deps) verify,
  Duration debounce = const Duration(milliseconds: 50),
  bool closeSourceOnClose = false,
}) {
  late final StreamSubscription<StreamStatus> statusSub;
  late final StreamSubscription<List<T>> listSub;

  // Track which items have been processed (by event id).
  final verified = <String, Validation<T>>{};
  var pendingCount = 0;
  StreamStatus? deferredStatus;

  // Whether the source has emitted items we haven't processed yet
  // (debounce window hasn't fired).
  var hasUnprocessedItems = false;

  final response = ValidatedStreamWithStatus<T>(
    onClose: () async {
      await statusSub.cancel();
      await listSub.cancel();
      if (closeSourceOnClose) {
        await source.close();
      }
    },
  );

  void emitSnapshot() {
    response.setSnapshot(List.unmodifiable(verified.values.toList()));
  }

  void maybeForwardDeferredStatus() {
    if (pendingCount == 0 && !hasUnprocessedItems && deferredStatus != null) {
      response.addStatus(deferredStatus!);
      deferredStatus = null;
    }
  }

  // Listen to raw source stream (pre-debounce) to detect unprocessed items.
  source.stream.listen((_) {
    hasUnprocessedItems = true;
  });

  statusSub = source.status.listen((status) {
    if (status is StreamStatusError) {
      response.addStatus(status);
      return;
    }

    if (status is StreamStatusQuerying) {
      response.addStatus(status);
      return;
    }

    // Defer QueryComplete and Live until pending verifications drain.
    if (status is StreamStatusQueryComplete || status is StreamStatusLive) {
      deferredStatus = status;
      maybeForwardDeferredStatus();
      return;
    }

    response.addStatus(status);
  }, onError: response.addError);

  listSub = source.list.debounceTime(debounce).listen((snapshot) {
    hasUnprocessedItems = false;

    // Find items not yet processed or with updated content.
    final newItems = <T>[];
    for (final item in snapshot) {
      final id = item.id;
      if (id == null) continue;
      if (!verified.containsKey(id)) {
        newItems.add(item);
      }
    }

    if (newItems.isEmpty) {
      maybeForwardDeferredStatus();
      return;
    }

    for (final item in newItems) {
      final id = item.id!;
      pendingCount++;

      resolve(item)
          .then((deps) {
            verified[id] = verify(item, deps);
          })
          .catchError((Object error) {
            verified[id] = Invalid(item, error.toString());
          })
          .whenComplete(() {
            pendingCount--;
            emitSnapshot();
            maybeForwardDeferredStatus();
          });
    }
  }, onError: response.addError);

  return response;
}
