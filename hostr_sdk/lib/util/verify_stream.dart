import 'dart:async';

import 'package:ndk/ndk.dart' show Nip01Event;

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
StreamWithStatus<Validation<T>> verifyStream<T extends Nip01Event, TDeps>({
  required StreamWithStatus<T> source,
  required Future<TDeps> Function(T item) resolve,
  required Validation<T> Function(T item, TDeps deps) verify,
  Duration debounce = const Duration(milliseconds: 1000),
  bool closeSourceOnClose = false,
}) {
  late final StreamSubscription<T> replaySub;
  late final StreamSubscription<StreamStatus> statusSub;

  // Track which items have been processed (by event id).
  final verified = <String, Validation<T>>{};
  var pendingCount = 0;
  StreamStatus? deferredStatus;

  // Buffer of items received but not yet dispatched for verification
  // (waiting for debounce window to close).
  final pendingItems = <String, T>{};
  Timer? debounceTimer;

  final response = StreamWithStatus<Validation<T>>(
    onClose: () async {
      debounceTimer?.cancel();
      await statusSub.cancel();
      await replaySub.cancel();
      if (closeSourceOnClose) {
        await source.close();
      }
    },
  );

  void maybeForwardDeferredStatus() {
    if (pendingCount == 0 && pendingItems.isEmpty && deferredStatus != null) {
      response.addStatus(deferredStatus!);
      deferredStatus = null;
    }
  }

  void flushPendingItems() {
    final items = Map<String, T>.of(pendingItems);
    pendingItems.clear();

    if (items.isEmpty) {
      maybeForwardDeferredStatus();
      return;
    }

    for (final entry in items.entries) {
      final id = entry.key;
      final item = entry.value;
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
            response.add(verified[id]!);
            maybeForwardDeferredStatus();
          });
    }
  }

  // Listen to the raw broadcast stream for immediate synchronous delivery.
  // We also listen to replayStream so that items already buffered
  // before verifyStream was created are picked up.
  void onItem(T item) {
    final id = item.id;
    if (verified.containsKey(id) || pendingItems.containsKey(id)) {
      return; // already processed or already buffered
    }

    pendingItems[id] = item;
    debounceTimer?.cancel();
    debounceTimer = Timer(debounce, flushPendingItems);
  }

  // source.replayStream replays current items then continues with new
  // per-item events. This replaces the old separate stream + replay
  // listeners.
  replaySub = source.replayStream.listen(onItem, onError: response.addError);

  // Listen to snapshot status changes (distinct by type to avoid
  // redundant updates from item-only snapshot changes).
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

  return response;
}
