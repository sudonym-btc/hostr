import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart'
    show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Ndk, Nip01Event;

import '../../util/main.dart';
import '../crud.usecase.dart';

/// CRUD-style use case for NIP-59 gift wraps.
///
/// Read operations expose parsed inner events from wrapped `1059` events.
/// Callers can then use `.whereType<T>()` on the returned stream.
@Singleton()
class GiftWraps extends CrudUseCase<Nip01Event> {
  final Ndk _ndk;

  GiftWraps({required Ndk ndk, required super.requests, required super.logger})
    : _ndk = ndk,
      super(kind: kNostrKindGiftWrap);

  /// Wraps a rumor/event for [recipientPubkey] without broadcasting it.
  Future<Nip01Event> wrap({
    required Nip01Event rumor,
    required String recipientPubkey,
  }) => logger.span('wrap', () async {
    return _ndk.giftWrap.toGiftWrap(
      rumor: rumor,
      recipientPubkey: recipientPubkey,
    );
  });

  /// Wraps [rumor] for [recipientPubkey] and broadcasts the resulting giftwrap.
  Future<List<RelayBroadcastResponse>> upsertWrapped({
    required Nip01Event rumor,
    required String recipientPubkey,
  }) => logger.span('upsertWrapped', () async {
    final wrapped = await wrap(rumor: rumor, recipientPubkey: recipientPubkey);
    return upsert(wrapped);
  });

  /// Subscribes to kind `1059` events and returns parsed inner events.
  StreamWithStatus<Nip01Event> subscribeParsed(Filter filter, {String? name}) =>
      logger.spanSync('subscribeParsed', () {
        final raw = requests.subscribe<Nip01Event>(
          filter: kindFilter(filter),
          name: name != null ? 'GiftWraps-$name' : 'GiftWraps-parsed',
        );

        final parsed = StreamWithStatus<Nip01Event>(onClose: raw.close);
        parsed.addSubscription(
          raw.replayStream
              .asyncMap(
                (event) => safeParserWithGiftWrap<Nip01Event>(event, _ndk),
              )
              .where((event) => event != null)
              .cast<Nip01Event>()
              .listen(parsed.add, onError: parsed.addError),
        );
        parsed.addSubscription(
          raw.status.listen(parsed.addStatus, onError: parsed.addError),
        );
        return parsed;
      });
}
