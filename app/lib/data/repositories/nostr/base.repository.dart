import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/ease.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/models/main.dart';
import 'package:hostr/data/sources/main.dart';
import 'package:hostr/injection.dart';
import 'package:rxdart/rxdart.dart';

abstract class DataResult<T> {}

class Data<T> extends DataResult<T> {
  final T value;
  Data(this.value);
}

class OK<T> extends DataResult<T> {}

class Err<T> extends DataResult<T> {
  final String message;
  Err(this.message);
}

NostrFilter getCombinedFilter(NostrFilter? filter1, NostrFilter? filter2) {
  return NostrFilter(
    ids: (filter1?.ids != null || filter2?.ids != null)
        ? [...?filter1?.ids, ...?filter2?.ids]
        : null,
    authors: (filter1?.authors != null || filter2?.authors != null)
        ? [...?filter1?.authors, ...?filter2?.authors]
        : null,
    kinds: (filter1?.kinds != null || filter2?.kinds != null)
        ? [...?filter1?.kinds, ...?filter2?.kinds]
        : null,
    e: (filter1?.e != null || filter2?.e != null)
        ? [...?filter1?.e, ...?filter2?.e]
        : null,
    p: (filter1?.p != null || filter2?.p != null)
        ? [...?filter1?.p, ...?filter2?.p]
        : null,
    t: (filter1?.t != null || filter2?.t != null)
        ? [...?filter1?.t, ...?filter2?.t]
        : null,
    a: (filter1?.a != null || filter2?.a != null)
        ? [...?filter1?.a, ...?filter2?.a]
        : null,
    since: filter1?.since ?? filter2?.since,
    until: filter1?.until ?? filter2?.until,
    limit: filter1?.limit ?? filter2?.limit,
    search: filter1?.search ?? filter2?.search,
    additionalFilters: filter1?.additionalFilters ?? filter2?.additionalFilters,
  );
}

class BaseRepository<T extends Event> {
  List<int> kinds = [];
  NostrProvider nostr = getIt<NostrProvider>();
  late T Function(NostrEvent event) creator = (event) => event as T;
  CustomLogger logger = CustomLogger();

  Future<int> count(NostrFilter filter) {
    final countEvent = NostrCountEvent.fromPartialData(
        eventsFilter: getCombinedFilter(filter, NostrFilter(kinds: kinds)));

    return Nostr.instance.relaysService
        .sendCountEventToRelaysAsync(countEvent,
            timeout: const Duration(seconds: 3))
        .then((v) {
      return v.count;
    });
  }

  Stream<DataResult<T>> list(
      {NostrFilter? filter,
      required void Function(String relay, NostrRequestEoseCommand ease)
          onEose}) {
    logger.i("list $filter");

    return nostr
        .startRequest(
            request: NostrRequest(
              filters: [getCombinedFilter(filter, NostrFilter(kinds: kinds))],
            ),
            onEose: onEose)
        .stream
        .map(_parser)
        .doOnData((e) => logger.i("list result $e"));
  }

  Future<DataResult<T>> get({
    NostrFilter? filter,
  }) async {
    logger.i("get $filter");
    var results = await nostr.startRequestAsync(
      request: NostrRequest(
        filters: [
          NostrFilter(limit: 1),
          getCombinedFilter(filter, NostrFilter(kinds: kinds)),
        ],
      ),
    );
    return results.map(_parser).first;
  }

  create(T event) {
    logger.i("create $event");
    return nostr.sendEventToRelaysAsync(event: event);
  }

  DataResult<T> _parser(NostrEvent event) {
    logger.i("parser $event");
    return Data(creator(event));
  }
}
