import 'package:dart_nostr/dart_nostr.dart';
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
  late T Function(NostrEvent event) creator;
  CustomLogger logger = CustomLogger();

  Stream<DataResult<T>> list({NostrFilter? filter}) {
    logger.i("list $filter");
    return nostr
        .startRequest(
            request: NostrRequest(
          filters: [
            eventTypeFilter ?? NostrFilter(),
            filter ?? NostrFilter(),
          ],
        ))
        .stream
        .map(_parser)
        .doOnData((e) => logger.i("list result $e"));
  }

  void create(NostrEvent event) {
    logger.i("create $event");
    return nostr.sendEventToRelays(event);
  }

  DataResult<T> _parser(NostrEvent event) {
    return Data(creator(event));
  }
}
