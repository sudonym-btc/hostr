import 'dart:async';
import 'dart:collection';

import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart'
    show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Ndk, Nip01Event;

import '../../config.dart' show CoinlibEventSigner, HostrConfig;
import '../../injection.dart';
import '../../util/coinlib_gift_wrap.dart';
import '../../util/main.dart';
import '../crud.usecase.dart';

bool _isCompletionStatus(StreamStatus status) =>
    status is StreamStatusQueryComplete || status is StreamStatusLive;

@visibleForTesting
StreamWithStatus<Nip01Event> parseGiftWrapsConcurrently({
  required StreamWithStatus<Nip01Event> raw,
  required Future<Nip01Event?> Function(Nip01Event event) parse,
  int maxConcurrent = 8,
}) {
  final parsed = StreamWithStatus<Nip01Event>(onClose: raw.close);
  final rawSeen = <String>{};
  final parsedSeen = <String>{};
  final queue = Queue<({Nip01Event event, bool historical})>();

  var active = 0;
  var historicalPending = 0;
  var historicalPhase = true;
  StreamStatus? pendingCompletionStatus;

  void maybeEmitCompletionStatus() {
    final status = pendingCompletionStatus;
    if (status == null || historicalPending > 0) return;
    pendingCompletionStatus = null;
    parsed.addStatus(status);
  }

  void drain() {
    while (active < maxConcurrent && queue.isNotEmpty) {
      final item = queue.removeFirst();
      active++;
      unawaited(
        parse(item.event)
            .then((event) {
              if (event == null) return;
              if (!parsedSeen.add(event.id)) return;
              parsed.add(event);
            }, onError: parsed.addError)
            .whenComplete(() {
              active--;
              if (item.historical) {
                historicalPending--;
                maybeEmitCompletionStatus();
              }
              drain();
            }),
      );
    }
  }

  void enqueue(Nip01Event event, {required bool historical}) {
    if (!rawSeen.add(event.id)) return;
    if (historical) historicalPending++;
    queue.add((event: event, historical: historical));
    drain();
  }

  parsed.addSubscription(
    raw.replayStream.listen((event) {
      enqueue(event, historical: historicalPhase);
    }, onError: parsed.addError),
  );
  parsed.addSubscription(
    raw.status.listen((status) {
      if (!_isCompletionStatus(status)) {
        parsed.addStatus(status);
        return;
      }
      for (final event in raw.items) {
        enqueue(event, historical: true);
      }
      historicalPhase = false;
      pendingCompletionStatus = status;
      maybeEmitCompletionStatus();
    }, onError: parsed.addError),
  );

  return parsed;
}

/// CRUD-style use case for NIP-59 gift wraps.
///
/// Read operations expose parsed inner events from wrapped `1059` events.
/// Callers can then use `.whereType<T>()` on the returned stream.
@Singleton()
class GiftWraps extends CrudUseCase<Nip01Event> {
  final Ndk _ndk;
  final HostrConfig? _config;

  GiftWraps({
    required Ndk ndk,
    required super.requests,
    required super.logger,
    @ignoreParam HostrConfig? config,
  }) : _ndk = ndk,
       _config = config,
       super(kind: kNostrKindGiftWrap);

  /// Wraps a rumor/event for [recipientPubkey] without broadcasting it.
  ///
  /// Uses [coinlibToGiftWrap] (provider-backed NIP-44 fast paths on web)
  /// when a [CoinlibEventSigner] is the active account. Falls back to NDK's
  /// pure-Dart path otherwise.
  Future<Nip01Event> wrap({
    required Nip01Event rumor,
    required String recipientPubkey,
  }) => logger.span('wrap', () async {
    final rawSigner = _ndk.accounts.getLoggedAccount()?.signer;
    final signer = rawSigner is CoinlibEventSigner ? rawSigner : null;
    if (signer?.privateKey != null) {
      return coinlibToGiftWrap(
        rumor: rumor,
        recipientPubkey: recipientPubkey,
        senderPrivKey: signer!.privateKey!,
        senderPubKey: signer.getPublicKey(),
      );
    }
    // Fallback for non-coinlib signers (e.g. hardware wallet / NIP-46).
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
    final hostrRelay = _hostrRelay();
    final responses = await requests.broadcast(
      event: wrapped,
      relays: hostrRelay.isEmpty ? null : [hostrRelay],
    );
    return responses;
  });

  /// Subscribes to kind `1059` events and returns parsed inner events.
  StreamWithStatus<Nip01Event> subscribeParsed(Filter filter, {String? name}) =>
      logger.spanSync('subscribeParsed', () {
        final hostrRelay = _hostrRelay();
        final raw = requests.subscribe<Nip01Event>(
          filter: kindFilter(filter),
          relays: hostrRelay.isEmpty ? null : [hostrRelay],
          name: name != null ? 'GiftWraps-$name' : 'GiftWraps-parsed',
          // NIP-59 gift wraps have a randomised created_at (up to 48 h in the
          // past) for privacy. Setting a `since` filter on the live phase would
          // cause the relay to silently drop newly sent gift wraps whose
          // timestamp happens to fall before `since`, so we disable it.
          setSinceOnLiveFilter: false,
        );

        return parseGiftWrapsConcurrently(raw: raw, parse: _parseWrappedEvent);
      });

  Future<Nip01Event?> _parseWrappedEvent(Nip01Event event) async {
    try {
      return await parserWithGiftWrap<Nip01Event>(event, _ndk);
    } catch (error, stackTrace) {
      logger.w(
        'Failed to parse gift wrap event kind=${event.kind} id=${event.id}',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String _hostrRelay() {
    final config = _config;
    if (config != null) return config.hostrRelay;
    if (!getIt.isRegistered<HostrConfig>()) return '';
    return getIt<HostrConfig>().hostrRelay;
  }
}
