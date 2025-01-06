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

class BaseRepository<T extends Event> {
  NostrFilter? eventTypeFilter;
  NostrProvider nostr = getIt<NostrProvider>();
  late T Function(NostrEvent event) creator = (event) => event as T;
  CustomLogger logger = CustomLogger();

  Stream<DataResult<T>> list(
      {NostrFilter? filter,
      required void Function(String relay, NostrRequestEoseCommand ease)
          onEose}) {
    logger.i("list $filter");
    filter ??= NostrFilter();
    NostrFilter? finalFilter = NostrFilter(
      ids: filter.ids,
      authors: filter.authors,
      kinds: [...(filter.kinds ?? []), ...(eventTypeFilter?.kinds ?? [])],
      e: filter.e,
      p: filter.p,
      t: filter.t,
      since: filter.since,
      until: filter.until,
      limit: filter.limit,
      search: filter.search,
      a: filter.a,
      additionalFilters: filter.additionalFilters,
    );
    logger.i("finalFilter $finalFilter");
    return nostr
        .startRequest(
            request: NostrRequest(
              filters: [finalFilter],
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
          eventTypeFilter ?? NostrFilter(),
          filter ?? NostrFilter(),
        ],
      ),
    );
    return results.map(_parser).first;
  }

  create(NostrEvent event) {
    logger.i("create $event");
    return nostr.sendEventToRelaysAsync(event);
  }

  DataResult<T> _parser(NostrEvent event) {
    logger.i("parser $event");
    return Data(creator(event));
  }
}
