import 'package:hostr_sdk/util/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01Event;

import 'crud.usecase.dart';

/// Contract for verifying a [Nip01Event] after resolving any dependent data.
abstract class Verifier<T extends Nip01Event, TDeps> {
  Future<TDeps> resolve(T item);
  Validation<T> verify(T item, TDeps deps);
}

/// Mixin that adds verified subscribe/query helpers to a [CrudUseCase].
///
/// Classes using this mixin must implement [resolve] and [verify] so the
/// verification pipeline knows how to fetch dependencies and how to decide if
/// an item is valid once resolved.
mixin CanVerify<T extends Nip01Event, TDeps> on CrudUseCase<T>
    implements Verifier<T, TDeps> {
  /// Override to customize the default name suffix used for verification
  /// subscriptions/queries (useful for logging and deduped request IDs).
  String get verificationStreamName => 'verified';

  ValidatedStreamWithStatus<T> subscribeVerified({
    Filter? filter,
    Duration debounce = const Duration(milliseconds: 50),
    bool closeSourceOnClose = true,
    String? name,
  }) {
    final effectiveFilter = filter ?? Filter();
    final streamName = name ?? verificationStreamName;
    logger.d(
      'Subscribing to $streamName $T with filter: $effectiveFilter',
    );

    final source = subscribe(effectiveFilter, name: streamName);
    return _verifySource(
      source: source,
      debounce: debounce,
      closeSourceOnClose: closeSourceOnClose,
    );
  }

  ValidatedStreamWithStatus<T> queryVerified({
    Filter? filter,
    Duration debounce = const Duration(milliseconds: 50),
    bool closeSourceOnClose = true,
    String? name,
  }) {
    final effectiveFilter = filter ?? Filter();
    final streamName = name ?? '${verificationStreamName}-query';
    logger.d('Querying $streamName $T with filter: $effectiveFilter');

    final source = _queryWithStatus(effectiveFilter, name: streamName);
    return _verifySource(
      source: source,
      debounce: debounce,
      closeSourceOnClose: closeSourceOnClose,
    );
  }

  ValidatedStreamWithStatus<T> _verifySource({
    required StreamWithStatus<T> source,
    required Duration debounce,
    required bool closeSourceOnClose,
  }) {
    return verifyStream<T, TDeps>(
      source: source,
      debounce: debounce,
      closeSourceOnClose: closeSourceOnClose,
      resolve: resolve,
      verify: verify,
    );
  }

  StreamWithStatus<T> _queryWithStatus(Filter filter, {required String name}) {
    final combinedFilter = getCombinedFilter(filter, Filter(kinds: [kind]));
    return StreamWithStatus<T>(
      queryFn: () => requests.query<T>(
        filter: combinedFilter,
        name: '$T-$name',
      ),
    );
  }
}
